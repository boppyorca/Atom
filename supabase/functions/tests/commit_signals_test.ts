import { assertEquals } from 'jsr:@std/assert@1'
import {
  ignoredGeneratedPath,
  scoreAuthorCommits,
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

Deno.test('the first huge commit is dropped and a day keeps only three commits', () => {
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
  const score = scoreAuthorCommits({
    login: 'minh',
    repoDependencies: [],
    skills: [dart],
    commits,
  })
  assertEquals(score?.validCommitCount, 3)
  assertEquals(score?.linesAuthored, 30)
})

Deno.test('github errors stay distinct', () => {
  assertEquals(githubErrorCode(404, null), 'NOT_FOUND')
  assertEquals(githubErrorCode(403, '0'), 'RATE_LIMITED')
  assertEquals(githubErrorCode(429, '10'), 'RATE_LIMITED')
  assertEquals(githubErrorCode(500, null), 'GITHUB_UNAVAILABLE')
})
