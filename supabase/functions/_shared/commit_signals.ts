import { githubErrorCode } from './github_repos.ts'
import { parsePackageJson, parsePubspec } from './extract.ts'

export type CommitFile = { filename: string; additions: number }

export type RawCommit = {
  sha: string
  authorLogin: string | null
  date: string
  parentCount: number
  files: CommitFile[]
}

export type SkillPathRule = {
  name: string
  extensions: string[]
  files: string[]
  dependencies: string[]
}

export type RepoCommitScore = {
  validCommitCount: number
  linesAuthored: number
  firstCommitAt: string
  lastCommitAt: string
  skillNames: string[]
}

const manifestNames = new Set([
  'pubspec.yaml',
  'package.json',
  'requirements.txt',
  'pyproject.toml',
  'go.mod',
  'cargo.toml',
  'gemfile',
  'composer.json',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
])

export function ignoredGeneratedPath(path: string): boolean {
  const lower = path.toLowerCase().replaceAll('\\', '/')
  const base = lower.split('/').pop() ?? lower
  if (
    lower.startsWith('vendor/') ||
    lower.includes('/vendor/') ||
    lower.startsWith('node_modules/') ||
    lower.includes('/node_modules/') ||
    lower.startsWith('third_party/') ||
    lower.includes('/third_party/') ||
    lower.startsWith('dist/') ||
    lower.includes('/dist/') ||
    lower.startsWith('build/') ||
    lower.includes('/build/') ||
    lower.startsWith('generated/') ||
    lower.includes('/generated/')
  ) {
    return true
  }
  return (
    base.endsWith('.lock') ||
    base.endsWith('-lock.json') ||
    base === 'pubspec.lock' ||
    base === 'package-lock.json' ||
    base === 'yarn.lock' ||
    base === 'cargo.lock' ||
    base === 'gemfile.lock' ||
    base === 'composer.lock' ||
    base === 'poetry.lock' ||
    base.endsWith('.g.dart') ||
    base.endsWith('.freezed.dart') ||
    base.endsWith('.pb.dart') ||
    base.endsWith('.min.js')
  )
}

function dayKey(iso: string): string {
  const shifted = new Date(new Date(iso).getTime() + 7 * 60 * 60 * 1000)
  return shifted.toISOString().slice(0, 10)
}

function matchesSkill(filename: string, rule: SkillPathRule, repoDependencies: Set<string>): boolean {
  const lower = filename.toLowerCase().replaceAll('\\', '/')
  const base = lower.split('/').pop() ?? lower
  const extensionHit = rule.extensions.some((extension) => lower.endsWith(extension.toLowerCase()))
  const fileHit = rule.files.some((file) => base === file.toLowerCase() || lower.endsWith(`/${file.toLowerCase()}`))
  const dependencyPresent = rule.dependencies.some((name) => repoDependencies.has(name.toLowerCase()))
  if ((extensionHit || fileHit) && (rule.dependencies.length === 0 || dependencyPresent)) return true
  return manifestNames.has(base) && dependencyPresent
}

export function scoreAuthorCommits(input: {
  login: string
  commits: RawCommit[]
  skills: SkillPathRule[]
  repoDependencies: string[]
  // True only when the oldest commit in this list is the start of the saved login's history.
  reachedRoot?: boolean
}): RepoCommitScore | null {
  const login = input.login.toLowerCase()
  const repoDependencies = new Set(input.repoDependencies.map((name) => name.toLowerCase()))
  const kept = input.commits
    .filter((commit) => commit.authorLogin?.toLowerCase() === login)
    .filter((commit) => commit.parentCount <= 1)
    .map((commit) => ({
      ...commit,
      files: commit.files.filter((file) => !ignoredGeneratedPath(file.filename) && file.additions > 0),
    }))
    .filter((commit) => commit.files.length > 0)
    .sort((a, b) => a.date.localeCompare(b.date))

  // A huge oldest commit is treated as a template dump only when we reached the root.
  // A cut-short scan's oldest commit is not the first commit, so it stays.
  if (
    input.reachedRoot === true &&
    kept.length > 0 &&
    kept[0].files.reduce((sum, file) => sum + file.additions, 0) > 1000
  ) {
    kept.shift()
  }

  const perDay = new Map<string, number>()
  const counted = kept.filter((commit) => {
    const day = dayKey(commit.date)
    const used = perDay.get(day) ?? 0
    if (used >= 3) return false
    perDay.set(day, used + 1)
    return true
  })

  const bySkill = new Map<string, { lines: number; dates: string[] }>()
  for (const commit of counted) {
    for (const rule of input.skills) {
      const lines = commit.files
        .filter((file) => matchesSkill(file.filename, rule, repoDependencies))
        .reduce((sum, file) => sum + file.additions, 0)
      if (lines <= 0) continue
      const current = bySkill.get(rule.name) ?? { lines: 0, dates: [] }
      current.lines += lines
      current.dates.push(commit.date)
      bySkill.set(rule.name, current)
    }
  }
  if (bySkill.size === 0) return null
  const dates = counted.map((commit) => commit.date).sort()
  return {
    validCommitCount: counted.length,
    linesAuthored: [...bySkill.values()].reduce((sum, item) => sum + item.lines, 0),
    firstCommitAt: dates[0],
    lastCommitAt: dates[dates.length - 1],
    skillNames: [...bySkill.keys()],
  }
}

export const commitScanBudget = {
  maxRepos: 10,
  maxCalls: 240,
  maxDetailsPerRepo: 20,
  listPageSize: 100,
  manifestBytes: 200_000,
  callTimeoutMs: 8_000,
}

export type CallBudget = { used: number; maxCalls: number }

export function scanMeetsEvidenceBar(score: RepoCommitScore): boolean {
  const spanMs = new Date(score.lastCommitAt).getTime() - new Date(score.firstCommitAt).getTime()
  return score.validCommitCount >= 5 && score.linesAuthored >= 200 && spanMs >= 14 * 24 * 60 * 60 * 1000
}

type GithubCommit = {
  sha?: string
  author?: { login?: string | null } | null
  parents?: unknown[]
  commit?: { author?: { date?: string } }
  files?: { filename?: string; additions?: number }[]
}

type ManifestPayload = { size?: number; content?: string }

function reserve(budget: CallBudget): boolean {
  if (budget.used >= budget.maxCalls) return false
  budget.used += 1
  return true
}

async function githubFetch(
  budget: CallBudget,
  fetchImpl: typeof fetch,
  url: string,
  headers: HeadersInit,
): Promise<Response | 'RATE_LIMITED' | 'GITHUB_UNAVAILABLE'> {
  if (!reserve(budget)) return 'RATE_LIMITED'
  try {
    return await fetchImpl(url, { headers, signal: AbortSignal.timeout(commitScanBudget.callTimeoutMs) })
  } catch {
    return 'GITHUB_UNAVAILABLE'
  }
}

function namesFromManifest(payload: ManifestPayload, parse: (text: string) => string[]): string[] {
  if (typeof payload.size === 'number' && payload.size > commitScanBudget.manifestBytes) return []
  if (typeof payload.content !== 'string') return []
  const text = atob(payload.content.replaceAll('\n', ''))
  if (text.length > commitScanBudget.manifestBytes) return []
  return parse(text)
}

export async function loadRepoCommitScore(input: {
  fetch: typeof fetch
  token: string
  fullName: string
  login: string
  skills: SkillPathRule[]
  repoDependencies: string[]
  budget: CallBudget
}): Promise<RepoCommitScore & { orgRepo: boolean; scanTruncated: boolean; listedCommitCount: number } | null | string> {
  const headers = {
    Authorization: `Bearer ${input.token}`,
    Accept: 'application/vnd.github+json',
    'User-Agent': 'atom',
  }
  const encoded = input.fullName.split('/').map(encodeURIComponent).join('/')
  const repo = await githubFetch(input.budget, input.fetch, `https://api.github.com/repos/${encoded}`, headers)
  if (typeof repo === 'string') return repo
  if (!repo.ok) return githubErrorCode(repo.status, repo.headers.get('x-ratelimit-remaining'))
  const details = await repo.json() as { archived?: boolean; owner?: { type?: string } }
  if (details.archived === true) return null

  const foundDependencies = [...input.repoDependencies]
  // Root only. Nested manifests are not read.
  // Only these two files have a package name in the 13 rules: pub flutter/provider, npm react.
  // requirements.txt, pyproject.toml, go.mod, Cargo.toml, pom.xml, build.gradle,
  // Gemfile, composer.json and csproj are not fetched.
  const manifests: { path: string; parse: (text: string) => string[] }[] = [
    { path: 'pubspec.yaml', parse: parsePubspec },
    { path: 'package.json', parse: parsePackageJson },
  ]
  for (const manifest of manifests) {
    const response = await githubFetch(
      input.budget,
      input.fetch,
      `https://api.github.com/repos/${encoded}/contents/${manifest.path}`,
      headers,
    )
    if (typeof response === 'string') return response
    if (response.status === 404) continue
    if (!response.ok) return githubErrorCode(response.status, response.headers.get('x-ratelimit-remaining'))
    foundDependencies.push(...namesFromManifest(await response.json() as ManifestPayload, manifest.parse))
  }

  const listed = await githubFetch(
    input.budget,
    input.fetch,
    `https://api.github.com/repos/${encoded}/commits?author=${encodeURIComponent(input.login)}&per_page=${commitScanBudget.listPageSize}`,
    headers,
  )
  if (typeof listed === 'string') return listed
  if (!listed.ok) return githubErrorCode(listed.status, listed.headers.get('x-ratelimit-remaining'))
  const body = await listed.json() as GithubCommit[]
  if (!Array.isArray(body)) return 'GITHUB_UNAVAILABLE'

  const login = input.login.toLowerCase()
  const candidates = body.filter((item) => {
    const author = item.author?.login?.toLowerCase()
    const parents = Array.isArray(item.parents) ? item.parents.length : 1
    return Boolean(item.sha) && author === login && parents <= 1 && Boolean(item.commit?.author?.date)
  })
  const detailed: RawCommit[] = []
  let stoppedEarly = false
  for (const item of candidates) {
    if (detailed.length >= commitScanBudget.maxDetailsPerRepo) {
      stoppedEarly = true
      break
    }
    const provisional = scoreAuthorCommits({
      login: input.login,
      commits: detailed,
      skills: input.skills,
      repoDependencies: foundDependencies,
      reachedRoot: false,
    })
    if (provisional && scanMeetsEvidenceBar(provisional)) {
      stoppedEarly = true
      break
    }
    const detail = await githubFetch(
      input.budget,
      input.fetch,
      `https://api.github.com/repos/${encoded}/commits/${item.sha}`,
      headers,
    )
    if (typeof detail === 'string') return detail
    if (!detail.ok) return githubErrorCode(detail.status, detail.headers.get('x-ratelimit-remaining'))
    const payload = await detail.json() as GithubCommit
    detailed.push({
      sha: item.sha as string,
      authorLogin: item.author?.login ?? null,
      date: item.commit?.author?.date ?? '',
      parentCount: 1,
      files: (payload.files ?? [])
        .filter((file) => typeof file.filename === 'string')
        .map((file) => ({ filename: file.filename as string, additions: file.additions ?? 0 })),
    })
  }

  const pageFull = body.length >= commitScanBudget.listPageSize
  const openedAll = detailed.length === candidates.length
  const reachedRoot = !pageFull && openedAll && !stoppedEarly
  const score = scoreAuthorCommits({
    login: input.login,
    commits: detailed.filter((commit) => commit.date !== ''),
    skills: input.skills,
    repoDependencies: foundDependencies,
    reachedRoot,
  })
  if (!score) return null
  return {
    ...score,
    orgRepo: details.owner?.type === 'Organization',
    scanTruncated: pageFull || stoppedEarly || !openedAll,
    listedCommitCount: candidates.length,
  }
}

