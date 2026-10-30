import { assertEquals } from 'jsr:@std/assert@1'
import {
  ignoredGeneratedPath,
  loadRepoCommitScore,
  scoreAuthorCommits,
  type CallBudget,
  type RawCommit,
  type SkillPathRule,
} from '../_shared/commit_signals.ts'
import { githubErrorCode } from '../_shared/github_repos.ts'

const dart: SkillPathRule = { name: 'Dart', extensions: ['.dart'], files: [], dependencies: [] }
const flutter: SkillPathRule = {
  name: 'Flutter',
  extensions: ['.dart'],
  files: [],
  dependencies: ['flutter'],
}

function commit(partial: Partial<RawCommit> & { sha: string; date: string }): RawCommit {
  return {
    authorLogin: 'minh',
    parentCount: 1,
    files: [{ filename: 'lib/main.dart', additions: 40 }],
    ...partial,
  }
}

Deno.test('vendor, lock and generated files are ignored', () => {
  assertEquals(ignoredGeneratedPath('vendor/lib/foo.dart'), true)
  assertEquals(ignoredGeneratedPath('pubspec.lock'), true)
  assertEquals(ignoredGeneratedPath('lib/main.g.dart'), true)
  assertEquals(ignoredGeneratedPath('lib/main.dart'), false)
})

Deno.test('only the saved login counts, and merge or empty commits do not', () => {
  const score = scoreAuthorCommits({
    login: 'Minh',
    repoDependencies: ['flutter'],
    skills: [dart, flutter],
    commits: [
      commit({ sha: '1', date: '2026-01-01T00:00:00Z', authorLogin: 'other' }),
      commit({ sha: '2', date: '2026-01-02T00:00:00Z', authorLogin: null }),
      commit({ sha: '3', date: '2026-01-03T00:00:00Z', parentCount: 2 }),
      commit({ sha: '4', date: '2026-01-04T00:00:00Z', files: [{ filename: 'lib/main.dart', additions: 0 }] }),
      commit({ sha: '5', date: '2026-01-05T00:00:00Z' }),
    ],
  })
  assertEquals(score?.validCommitCount, 1)
  assertEquals(score?.skillNames.sort(), ['Dart', 'Flutter'])
})

Deno.test('the oldest huge commit is dropped only when the scan reached the root', () => {
  const commits = [
    commit({
      sha: 'root',
      date: '2026-01-01T00:00:00Z',
      files: [{ filename: 'lib/main.dart', additions: 1001 }],
    }),
    ...Array.from({ length: 4 }, (_, index) =>
      commit({ sha: `d${index}`, date: `2026-01-02T0${index}:00:00Z`, files: [{ filename: 'lib/main.dart', additions: 10 }] }),
    ),
  ]
  const atRoot = scoreAuthorCommits({
    login: 'minh',
    repoDependencies: [],
    skills: [dart],
    commits,
    reachedRoot: true,
  })
  assertEquals(atRoot?.validCommitCount, 3)
  assertEquals(atRoot?.linesAuthored, 30)
  const cutShort = scoreAuthorCommits({
    login: 'minh',
    repoDependencies: [],
    skills: [dart],
    commits,
    reachedRoot: false,
  })
  assertEquals(cutShort?.validCommitCount, 4)
  assertEquals(cutShort?.linesAuthored, 1031)
})

Deno.test('github errors stay distinct', () => {
  assertEquals(githubErrorCode(404, null), 'NOT_FOUND')
  assertEquals(githubErrorCode(403, '0'), 'RATE_LIMITED')
  assertEquals(githubErrorCode(429, '10'), 'RATE_LIMITED')
  assertEquals(githubErrorCode(500, null), 'GITHUB_UNAVAILABLE')
})

function listedCommit(sha: string, parents = 1) {
  return {
    sha,
    author: { login: 'minh' },
    parents: Array.from({ length: parents }, () => ({ sha: 'parent' })),
    commit: { author: { date: '2026-02-01T00:00:00Z' } },
  }
}

function fakeGithub(filesFor: (sha: string) => { filename: string; additions: number }[]) {
  const urls: string[] = []
  const fetchImpl: typeof fetch = (input) => {
    const url = String(input)
    urls.push(url)
    if (url.endsWith('/minh-dev/app')) {
      return Promise.resolve(Response.json({ archived: false, owner: { type: 'User' } }))
    }
    if (url.endsWith('/contents/pubspec.yaml')) {
      return Promise.resolve(new Response('missing', { status: 404 }))
    }
    if (url.endsWith('/contents/package.json')) {
      return Promise.resolve(Response.json({
        content: btoa(JSON.stringify({
          scripts: { build: 'do not follow this' },
          dependencies: { react: '18.0.0' },
        })),
        size: 40,
      }))
    }
    if (url.includes('/commits?')) {
      const count = url.includes('page-full') ? 100 : 2
      const commits = Array.from({ length: count }, (_, index) => listedCommit(String(index), index === 0 && count === 2 ? 2 : 1))
      return Promise.resolve(Response.json(commits))
    }
    const sha = url.split('/').pop() ?? ''
    return Promise.resolve(Response.json({
      sha,
      files: filesFor(sha),
    }))
  }
  return { urls, fetchImpl }
}

Deno.test('commit details are opened only for commits that can count', async () => {
  const budget: CallBudget = { used: 0, maxCalls: 20 }
  const github = fakeGithub(() => [{ filename: 'lib/main.dart', additions: 40 }])
  const score = await loadRepoCommitScore({
    fetch: github.fetchImpl,
    token: 'token',
    fullName: 'minh-dev/app',
    login: 'minh',
    skills: [dart],
    repoDependencies: [],
    budget,
  })
  assertEquals(typeof score === 'string', false)
  if (typeof score === 'string' || score == null) return
  assertEquals(score.scanTruncated, false)
  assertEquals(score.listedCommitCount, 1)
  assertEquals(github.urls.filter((url) => /\/commits\/\d+$/.test(url)).length, 1)
  assertEquals(github.urls.some((url) => url.endsWith('/commits/0')), false)
  assertEquals(github.urls.some((url) => url.endsWith('/commits/1')), true)
})

Deno.test('a full commit page is marked unfinished and is not a total', async () => {
  const budget: CallBudget = { used: 0, maxCalls: 240 }
  const github = fakeGithub(() => [{ filename: 'lib/main.dart', additions: 10 }])
  const original = github.fetchImpl
  github.fetchImpl = (input, init) => {
    const url = String(input)
    if (url.includes('/commits?')) {
      github.urls.push(url.replace('app', 'page-full'))
      const commits = Array.from({ length: 100 }, (_, index) => listedCommit(`c${index}`))
      return Promise.resolve(Response.json(commits))
    }
    return original(input, init)
  }
  const score = await loadRepoCommitScore({
    fetch: github.fetchImpl,
    token: 'token',
    fullName: 'minh-dev/app',
    login: 'minh',
    skills: [dart],
    repoDependencies: [],
    budget,
  })
  if (typeof score === 'string' || score == null) throw new Error('expected a partial score')
  assertEquals(score.scanTruncated, true)
  assertEquals(score.listedCommitCount, 100)
  assertEquals(github.urls.filter((url) => /\/commits\/c\d+$/.test(url)).length, 20)
})

Deno.test('running out of call budget is rate limited, not an outage', async () => {
  const budget: CallBudget = { used: 0, maxCalls: 2 }
  const github = fakeGithub(() => [])
  const score = await loadRepoCommitScore({
    fetch: github.fetchImpl,
    token: 'token',
    fullName: 'minh-dev/app',
    login: 'minh',
    skills: [dart],
    repoDependencies: [],
    budget,
  })
  assertEquals(score, 'RATE_LIMITED')
  assertEquals(github.urls.length, 2)
})
