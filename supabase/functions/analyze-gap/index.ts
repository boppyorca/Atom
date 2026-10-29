import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import { gateStatus, type DictionarySkill } from '../_shared/extract.ts'
import { analyzeGap } from '../_shared/gap.ts'

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
  if (message.includes('NO_SKILLS')) return 'NO_SKILLS'
  return 'INTERNAL'
}

export async function finishGap(
  admin: SupabaseClient,
  profileId: string,
  jobId: string,
  description: string,
): Promise<void> {
  const fail = async (code: string) => {
    await admin.from('ai_jobs').update({
      status: 'failed',
      error_code: code,
      finished_at: new Date().toISOString(),
    }).eq('id', jobId)
  }
  try {
    await admin.from('ai_jobs').update({ status: 'running' }).eq('id', jobId)
    const { data: owned, error } = await admin
      .from('skills')
      .select('name, confidence')
      .eq('profile_id', profileId)
    if (error) {
      await fail('INTERNAL')
      return
    }
    const result = analyzeGap({
      description,
      skills: (owned ?? []).map((row) => ({
        name: row.name as string,
        confidence: row.confidence as string,
      })),
      dictionary: skills,
    })
    const { error: updateError } = await admin.from('ai_jobs').update({
      status: 'succeeded',
      finished_at: new Date().toISOString(),
      result,
    }).eq('id', jobId)
    if (updateError) {
      await fail('INTERNAL')
      return
    }
    await admin.from('notices').insert({ profile_id: profileId, kind: 'gap_ready' })
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
  let pasted = ''
  try {
    const body = await request.json()
    const value = body?.['job_description']
    pasted = typeof value === 'string' ? value.trim() : ''
  } catch {
    pasted = ''
  }
  if (pasted.length < 1 || pasted.length > 8000) {
    return json({ code: 'INPUT_INVALID' }, 422)
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) return json({ code: 'CONSENT_REQUIRED' }, 403)

  const admin = createClient(supabaseUrl, serviceKey)
  const { data, error } = await admin.rpc('ai_begin_job', {
    p_profile_id: userData.user.id,
    p_kind: 'gap_analysis',
  })
  if (error) {
    const code = errorCode(error.message)
    return json({ code }, gateStatus(code) ?? 500)
  }
  const jobId = (data as { job_id?: string } | null)?.job_id
  if (!jobId) return json({ code: 'INTERNAL' }, 500)
  const task = finishGap(admin, userData.user.id, jobId, pasted)
  const runtime = (globalThis as {
    EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void }
  }).EdgeRuntime
  if (runtime) runtime.waitUntil(task)
  else await task
  return json({ job_id: jobId, status: 'queued' }, 202)
})
