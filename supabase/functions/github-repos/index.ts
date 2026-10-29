import { createClient } from 'jsr:@supabase/supabase-js@2'
import { fetchPublicRepoPages, listWithSelection, saveError, type PublicRepo } from '../_shared/github_repos.ts'

type RepoPayload = {
  full_name: string
  url: string
  title: string | null
  is_fork: boolean
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

Deno.serve(async (request) => {
  const token = Deno.env.get('GITHUB_PUBLIC_READ_TOKEN')
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authHeader = request.headers.get('Authorization')
  if (!token || !supabaseUrl || !serviceKey || !authHeader) {
    return json({ code: 'GITHUB_UNAVAILABLE' }, 502)
  }

  const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') ?? serviceKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) return json({ code: 'GITHUB_NOT_CONNECTED' }, 409)

  const admin = createClient(supabaseUrl, serviceKey)
  const { data: connection } = await admin
    .from('github_connections')
    .select('github_username')
    .eq('profile_id', userData.user.id)
    .maybeSingle()
  if (!connection?.github_username) return json({ code: 'GITHUB_NOT_CONNECTED' }, 409)

  const username = connection.github_username as string
  let payload: { action?: string; full_names?: string[] }
  try {
    payload = await request.json()
  } catch {
    return json({ code: 'GITHUB_UNAVAILABLE' }, 502)
  }

  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
    'User-Agent': 'atom',
  }
  const listed = await fetchPublicRepoPages(
    fetch,
    (page) =>
      `https://api.github.com/users/${encodeURIComponent(username)}/repos?per_page=100&type=owner&page=${page}`,
    headers,
  )
  if (listed.error) return json({ code: listed.error }, listed.error === 'NOT_FOUND' ? 404 : 502)
  const body = listed.repos
  if (!Array.isArray(body)) return json({ code: 'GITHUB_UNAVAILABLE' }, 502)
  const publicRepos: PublicRepo[] = body
    .filter((repo) => repo && repo.private !== true && typeof repo.full_name === 'string')
    .filter((repo) => String(repo.full_name).startsWith(`${username}/`))
    .map((repo) => ({
      full_name: repo.full_name as string,
      url: `https://github.com/${repo.full_name}`,
      description: typeof repo.description === 'string' ? repo.description : null,
      is_fork: repo.fork === true,
      pushed_at: typeof repo.pushed_at === 'string' ? repo.pushed_at : null,
    }))

  if (payload.action === 'list') {
    const { data: saved } = await admin
      .from('evidence')
      .select('github_full_name')
      .eq('profile_id', userData.user.id)
      .eq('kind', 'github_repo')
    const names = (saved ?? [])
      .map((row) => row.github_full_name as string | null)
      .filter((name): name is string => Boolean(name))
    return json({ repos: listWithSelection(publicRepos, names) })
  }

  if (payload.action === 'save') {
    const names = payload.full_names ?? []
    const allowed = new Set(publicRepos.map((repo) => repo.full_name))
    const problem = saveError(names, allowed)
    if (problem) return json({ code: problem }, 422)
    const repos: RepoPayload[] = names.map((name) => {
      const found = publicRepos.find((repo) => repo.full_name === name)!
      return {
        full_name: name,
        url: found.url,
        title: found.description,
        is_fork: found.is_fork,
      }
    })
    const { error } = await admin.rpc('save_github_repos', {
      p_profile_id: userData.user.id,
      p_repos: repos,
    })
    if (error) return json({ code: 'GITHUB_UNAVAILABLE' }, 502)
    return json({ saved: names.length })
  }

  return json({ code: 'GITHUB_UNAVAILABLE' }, 502)
})
