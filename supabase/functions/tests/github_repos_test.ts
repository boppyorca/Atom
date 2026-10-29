import { assertEquals } from 'jsr:@std/assert@1'
import { fetchPublicRepoPages, listWithSelection, saveError, type PublicRepo } from '../_shared/github_repos.ts'

function repo(name: string, pushedAt: string, isFork = false): PublicRepo {
  return {
    full_name: name,
    url: `https://github.com/${name}`,
    description: null,
    is_fork: isFork,
    pushed_at: pushedAt,
  }
}

Deno.test('a first visit preselects the 10 newest repos that are not forks', () => {
  const repos = [
    repo('minh-dev/forked', '2026-10-20T00:00:00Z', true),
    ...Array.from({ length: 11 }, (_, index) =>
      repo(`minh-dev/app-${index}`, `2026-10-${String(index + 1).padStart(2, '0')}T00:00:00Z`),
    ),
  ]
  const listed = listWithSelection(repos, [])
  const selected = listed.filter((item) => item.selected).map((item) => item.full_name)
  assertEquals(selected.length, 10)
  assertEquals(selected.includes('minh-dev/forked'), false)
  assertEquals(selected.includes('minh-dev/app-0'), false)
  assertEquals(listed.find((item) => item.full_name === 'minh-dev/forked')?.is_fork, true)
})

Deno.test('saving an 11th repo is rejected and a repo outside the public list is rejected', () => {
  const allowed = new Set(['minh-dev/todo'])
  assertEquals(saveError(Array.from({ length: 11 }, (_, index) => `minh-dev/app-${index}`), allowed), 'TOO_MANY_REPOS')
  assertEquals(saveError(['other/secret'], allowed), 'REPO_NOT_PUBLIC')
  assertEquals(saveError(['minh-dev/todo'], allowed), null)
})

Deno.test('github list pages stop after a short page and keep rate-limit errors', async () => {
  const calls: number[] = []
  const result = await fetchPublicRepoPages(
    (_url) => {
      const page = calls.length + 1
      calls.push(page)
      const body = page === 1 ? Array.from({ length: 100 }, (_, index) => index) : [1]
      return Promise.resolve(new Response(JSON.stringify(body), { status: 200 }))
    },
    (page) => `https://example.test?page=${page}`,
    {},
  )
  assertEquals(result.error, null)
  assertEquals(result.repos.length, 101)
  assertEquals(calls, [1, 2])
})
