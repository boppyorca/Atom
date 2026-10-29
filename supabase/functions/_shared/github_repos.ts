export type PublicRepo = {
  full_name: string
  url: string
  description: string | null
  is_fork: boolean
  pushed_at: string | null
}

export type ListedRepo = PublicRepo & { selected: boolean }

export function listWithSelection(
  repos: PublicRepo[],
  savedFullNames: string[],
): ListedRepo[] {
  const saved = new Set(savedFullNames)
  const defaults = new Set(
    repos
      .filter((repo) => !repo.is_fork)
      .sort((a, b) => (b.pushed_at ?? '').localeCompare(a.pushed_at ?? ''))
      .slice(0, 10)
      .map((repo) => repo.full_name),
  )
  const hasSaved = savedFullNames.length > 0
  return repos.map((repo) => ({
    ...repo,
    selected: hasSaved ? saved.has(repo.full_name) : defaults.has(repo.full_name),
  }))
}

export function saveError(fullNames: string[], allowed: Set<string>): string | null {
  if (fullNames.length > 10) return 'TOO_MANY_REPOS'
  for (const name of fullNames) {
    if (!allowed.has(name)) return 'REPO_NOT_PUBLIC'
  }
  return null
}

export function githubErrorCode(status: number, remaining: string | null): string {
  if (status === 404) return 'NOT_FOUND'
  if (status === 429 || (status === 403 && remaining === '0')) return 'RATE_LIMITED'
  return 'GITHUB_UNAVAILABLE'
}

export async function fetchPublicRepoPages(
  fetchImpl: typeof fetch,
  urlForPage: (page: number) => string,
  headers: HeadersInit,
): Promise<{ repos: unknown[]; error: string | null }> {
  const repos: unknown[] = []
  for (let page = 1; page <= 5; page += 1) {
    const response = await fetchImpl(urlForPage(page), { headers })
    if (!response.ok) {
      return {
        repos,
        error: githubErrorCode(response.status, response.headers.get('x-ratelimit-remaining')),
      }
    }
    const body = await response.json()
    if (!Array.isArray(body)) return { repos, error: 'GITHUB_UNAVAILABLE' }
    repos.push(...body)
    if (body.length < 100) break
  }
  return { repos, error: null }
}
