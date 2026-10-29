import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import { gateStatus, type DictionarySkill } from '../_shared/extract.ts'
import { blockedNamesForRepos, suggestionsFromRepos } from '../_shared/read_repo.ts'
import { loadRepoCommitScore, type SkillPathRule } from '../_shared/commit_signals.ts'

const skills = dictionary as unknown as DictionarySkill[]

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

function errorCode(message: string): string {
  if (message.includes('CONSENT_REQUIRED')) return 'CONSENT_REQUIRED'
  if (message.includes('QUOTA_EXCEEDED')) return 'QUOTA_EXCEEDED'
  if (message.includes('JOB_ALREADY_RUNNING')) return 'JOB_ALREADY_RUNNING'
  if (message.includes('NO_SOURCES')) return 'NO_SOURCES'
  if (message.includes('RATE_LIMITED')) return 'RATE_LIMITED'
  if (message.includes('NOT_FOUND')) return 'NOT_FOUND'
  return 'INTERNAL'
}

export async function finishExtract(
  admin: SupabaseClient,
  profileId: string,
  jobId: string,
  fetchImpl: typeof fetch = fetch,
): Promise<void> {
  const token = Deno.env.get('GITHUB_PUBLIC_READ_TOKEN')
  const fail = async (code: string) => {
    await admin.from('ai_jobs').update({
      status: 'failed',
      error_code: code,
      finished_at: new Date().toISOString(),
    }).eq('id', jobId)
  }
  try {
    await admin.from('ai_jobs').update({ status: 'running' }).eq('id', jobId)
    if (!token) {
      await fail('GITHUB_UNAVAILABLE')
      return
    }
    const { data: evidence } = await admin
      .from('evidence')
      .select('id, github_full_name')
      .eq('profile_id', profileId)
      .eq('kind', 'github_repo')
    const repos = (evidence ?? [])
      .filter((row) => typeof row.github_full_name === 'string')
      .map((row) => ({
        evidenceId: row.id as string,
        fullName: row.github_full_name as string,
      }))
    const { data: connection } = await admin
      .from('github_connections')
      .select('github_username')
      .eq('profile_id', profileId)
      .maybeSingle()
    const login = connection?.github_username as string | undefined
    const rules: SkillPathRule[] = skills.map((skill) => ({
      name: skill.name,
      extensions: skill.signals.extensions ?? [],
      files: skill.signals.files,
      dependencies: Object.values(skill.signals.dependencies ?? {}).flat(),
    }))
    const commitMetrics: Record<string, {
      valid_commit_count: number
      lines_authored: number
      first_commit_at: string
      last_commit_at: string
      skill_names: string[]
      org_repo: boolean
    }> = {}
    if (login) {
      for (const repo of repos) {
        const deps = new Set<string>()
        const score = await loadRepoCommitScore({
          fetch: fetchImpl,
          token,
          fullName: repo.fullName,
          login,
          skills: rules,
          repoDependencies: [...deps],
        })
        if (typeof score === 'string') {
          await fail(score)
          return
        }
        if (score) {
          commitMetrics[repo.fullName] = {
            valid_commit_count: score.validCommitCount,
            lines_authored: score.linesAuthored,
            first_commit_at: score.firstCommitAt,
            last_commit_at: score.lastCommitAt,
            skill_names: score.skillNames,
            org_repo: score.orgRepo,
          }
        }
      }
    }
    const { data: owned } = await admin.from('skills').select('name').eq('profile_id', profileId)
    const { data: rejected } = await admin
      .from('skill_suggestions')
      .select('name, evidence_ids')
      .eq('profile_id', profileId)
      .eq('status', 'rejected')
    const currentIds = repos.map((repo) => repo.evidenceId)
    const result = await suggestionsFromRepos({
      fetch: fetchImpl,
      token,
      repos,
      existingNames: (owned ?? []).map((row) => row.name as string),
      blockedNames: blockedNamesForRepos(
        (rejected ?? []).map((row) => ({
          name: row.name as string,
          evidenceIds: (row.evidence_ids as string[]) ?? [],
        })),
        currentIds,
      ),
      dictionary: skills,
    })
    if (result.errorCode) {
      await fail(result.errorCode)
      return
    }
    const { data: pendingRows } = await admin
      .from('skill_suggestions')
      .select('name')
      .eq('profile_id', profileId)
      .eq('status', 'pending')
    const pendingNames = new Set(
      (pendingRows ?? []).map((row) => String(row.name).trim().toLowerCase()),
    )
    const fresh = result.suggestions.filter((suggestion) => !pendingNames.has(suggestion.name.trim().toLowerCase()))
    if (fresh.length > 0) {
      const { error } = await admin.from('skill_suggestions').insert(
        fresh.map((suggestion) => ({
          job_id: jobId,
          profile_id: profileId,
          name: suggestion.name,
          evidence_ids: suggestion.evidenceIds,
          signals: suggestion.signals,
          signal_types: suggestion.signalTypes,
          origin: 'catalog',
          commit_metrics: Object.fromEntries(
            repos
              .filter((repo) => suggestion.evidenceIds.includes(repo.evidenceId))
              .map((repo) => [repo.fullName, commitMetrics[repo.fullName]])
              .filter((entry) => entry[1]),
          ),
        })),
      )
      if (error) {
        await fail('INTERNAL')
        return
      }
    }
    await admin.from('ai_jobs').update({
      status: 'succeeded',
      finished_at: new Date().toISOString(),
      result: { count: result.suggestions.length },
    }).eq('id', jobId)
  } catch {
    await fail('INTERNAL')
  }
}

Deno.serve(async (request) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const authHeader = request.headers.get('Authorization')
  if (!supabaseUrl || !serviceKey || !anonKey || !authHeader) {
    return json({ code: 'INTERNAL' }, 500)
  }
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) return json({ code: 'CONSENT_REQUIRED' }, 403)

  const admin = createClient(supabaseUrl, serviceKey)
  const { data, error } = await admin.rpc('ai_begin_job', {
    p_profile_id: userData.user.id,
    p_kind: 'extract_skills',
  })
  if (error) {
    const code = errorCode(error.message)
    return json({ code }, gateStatus(code) ?? 500)
  }
  const jobId = (data as { job_id?: string } | null)?.job_id
  if (!jobId) return json({ code: 'INTERNAL' }, 500)
  const task = finishExtract(admin, userData.user.id, jobId)
  const runtime = (globalThis as {
    EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void }
  }).EdgeRuntime
  if (runtime) runtime.waitUntil(task)
  else await task
  return json(data, 202)
})
