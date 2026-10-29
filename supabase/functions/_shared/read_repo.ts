import {
  extractSuggestions,
  parsePubspec,
  type DictionarySkill,
  type SourceSnapshot,
  type Suggestion,
} from './extract.ts'

const manifests: Record<string, string> = {
  'pubspec.yaml': 'pub',
  'package.json': 'npm',
}

export type RepoRef = { evidenceId: string; fullName: string }

export function blockedNamesForRepos(
  rejected: { name: string; evidenceIds: string[] }[],
  currentIds: string[],
): string[] {
  const current = [...currentIds].sort().join(',')
  return rejected
    .filter((item) => [...item.evidenceIds].sort().join(',') === current)
    .map((item) => item.name)
}

export function parsePackageJson(text: string): string[] {
  const data = JSON.parse(text) as {
    dependencies?: Record<string, string>
    devDependencies?: Record<string, string>
  }
  return [
    ...Object.keys(data.dependencies ?? {}),
    ...Object.keys(data.devDependencies ?? {}),
  ]
}

function decodeContent(content: string): string {
  return atob(content.replace(/\n/g, ''))
}

async function github(
  fetchImpl: typeof fetch,
  token: string,
  path: string,
): Promise<Response> {
  return await fetchImpl(`https://api.github.com${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'User-Agent': 'atom',
    },
  })
}

export async function readRepo(
  fetchImpl: typeof fetch,
  token: string,
  repo: RepoRef,
): Promise<SourceSnapshot | 'unavailable'> {
  const encoded = repo.fullName.split('/').map(encodeURIComponent).join('/')
  const info = await github(fetchImpl, token, `/repos/${encoded}`)
  if (info.status === 404) return { evidenceId: repo.evidenceId, failed: true }
  if (!info.ok) return 'unavailable'
  const details = await info.json()
  const branch = typeof details.default_branch === 'string' ? details.default_branch : 'HEAD'
  const languagesResponse = await github(fetchImpl, token, `/repos/${encoded}/languages`)
  if (!languagesResponse.ok && languagesResponse.status !== 404) return 'unavailable'
  const languageBytes = languagesResponse.ok
    ? await languagesResponse.json() as Record<string, number>
    : {}
  const rootResponse = await github(
    fetchImpl,
    token,
    `/repos/${encoded}/contents/?ref=${encodeURIComponent(branch)}`,
  )
  if (!rootResponse.ok && rootResponse.status !== 404) return 'unavailable'
  const root = rootResponse.ok ? await rootResponse.json() : []
  const entries = Array.isArray(root) ? root : []
  const rootFiles = entries
    .filter((item) => item && item.type === 'file' && typeof item.name === 'string')
    .map((item) => item.name as string)
  const dependencies: Record<string, string[]> = {}
  let text = ''
  for (const name of rootFiles) {
    const ecosystem = manifests[name]
    const isReadme = name.toLowerCase().startsWith('readme')
    if (!ecosystem && !isReadme) continue
    const file = await github(
      fetchImpl,
      token,
      `/repos/${encoded}/contents/${encodeURIComponent(name)}?ref=${encodeURIComponent(branch)}`,
    )
    if (!file.ok) continue
    const body = await file.json()
    if (typeof body.content !== 'string') continue
    const decoded = decodeContent(body.content)
    if (ecosystem === 'pub') dependencies.pub = parsePubspec(decoded)
    if (ecosystem === 'npm') dependencies.npm = parsePackageJson(decoded)
    if (isReadme) text = decoded.slice(0, 4000)
  }
  return {
    evidenceId: repo.evidenceId,
    languageBytes,
    topics: Array.isArray(details.topics) ? details.topics : [],
    rootFiles,
    dependencies,
    text,
  }
}

export async function suggestionsFromRepos(input: {
  fetch: typeof fetch
  token: string
  repos: RepoRef[]
  existingNames: string[]
  blockedNames: string[]
  dictionary: DictionarySkill[]
}): Promise<{ suggestions: Suggestion[]; errorCode?: 'SOURCE_UNREADABLE' | 'GITHUB_UNAVAILABLE' }> {
  const sources: SourceSnapshot[] = []
  for (const repo of input.repos) {
    const read = await readRepo(input.fetch, input.token, repo)
    if (read === 'unavailable') return { suggestions: [], errorCode: 'GITHUB_UNAVAILABLE' }
    sources.push(read)
  }
  const result = extractSuggestions({
    sources,
    existingNames: input.existingNames,
    blockedNames: input.blockedNames,
    dictionary: input.dictionary,
  })
  return { suggestions: result.suggestions, errorCode: result.errorCode }
}
