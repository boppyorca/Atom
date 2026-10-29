import { assertEquals } from 'jsr:@std/assert@1'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import {
  blockedNamesForRepos,
  suggestionsFromRepos,
  type RepoRef,
} from '../_shared/read_repo.ts'
import type { DictionarySkill } from '../_shared/extract.ts'

const skills = dictionary as unknown as DictionarySkill[]
const repo: RepoRef = { evidenceId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', fullName: 'minh-dev/todo' }

function fakeFetch(routes: Record<string, { status: number; body: unknown }>): typeof fetch {
  return ((input: string | URL | Request) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url
    const path = url.replace('https://api.github.com', '')
    const route = routes[path]
    if (!route) return Promise.resolve(new Response('missing', { status: 404 }))
    return Promise.resolve(new Response(JSON.stringify(route.body), { status: route.status }))
  }) as typeof fetch
}

const pubspec = btoa(`name: todo
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
`)

Deno.test('a public repo file list becomes Flutter, Provider and Dart suggestions', async () => {
  const fetch = fakeFetch({
    '/repos/minh-dev/todo': { status: 200, body: { default_branch: 'main', topics: [] } },
    '/repos/minh-dev/todo/languages': { status: 200, body: { Dart: 95, Other: 5 } },
    '/repos/minh-dev/todo/contents/?ref=main': {
      status: 200,
      body: [{ name: 'pubspec.yaml', type: 'file' }, { name: 'README.md', type: 'file' }],
    },
    '/repos/minh-dev/todo/contents/pubspec.yaml?ref=main': {
      status: 200,
      body: { content: pubspec },
    },
    '/repos/minh-dev/todo/contents/README.md?ref=main': {
      status: 200,
      body: { content: btoa('A Flutter app') },
    },
  })
  const result = await suggestionsFromRepos({
    fetch,
    token: 'test-token',
    repos: [repo],
    existingNames: [],
    blockedNames: [],
    dictionary: skills,
  })
  assertEquals(result.errorCode, undefined)
  assertEquals(result.suggestions.map((item) => item.name).sort(), ['Dart', 'Flutter', 'Provider'])
})

Deno.test('a missing repo is a failed source and a GitHub error stops the job', async () => {
  const missing = fakeFetch({
    '/repos/minh-dev/todo': { status: 404, body: {} },
  })
  const failed = await suggestionsFromRepos({
    fetch: missing,
    token: 'test-token',
    repos: [repo],
    existingNames: [],
    blockedNames: [],
    dictionary: skills,
  })
  assertEquals(failed.errorCode, 'SOURCE_UNREADABLE')

  const down = fakeFetch({
    '/repos/minh-dev/todo': { status: 503, body: {} },
  })
  const unavailable = await suggestionsFromRepos({
    fetch: down,
    token: 'test-token',
    repos: [repo],
    existingNames: [],
    blockedNames: [],
    dictionary: skills,
  })
  assertEquals(unavailable.errorCode, 'GITHUB_UNAVAILABLE')
})

Deno.test('a skipped skill stays hidden until the chosen repos change', () => {
  const same = blockedNamesForRepos(
    [{ name: 'Flutter', evidenceIds: [repo.evidenceId] }],
    [repo.evidenceId],
  )
  assertEquals(same, ['Flutter'])
  const changed = blockedNamesForRepos(
    [{ name: 'Flutter', evidenceIds: [repo.evidenceId] }],
    ['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'],
  )
  assertEquals(changed, [])
})
