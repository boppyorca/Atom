import { assertEquals } from 'jsr:@std/assert@1'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import {
  dictionaryProblems,
  extractSuggestions,
  gateStatus,
  jobInput,
  parsePubspec,
  type DictionarySkill,
  type SourceSnapshot,
} from '../_shared/extract.ts'

const skills = dictionary as unknown as DictionarySkill[]

function repo(id: string, yaml: string, dartBytes = 95): SourceSnapshot {
  return {
    evidenceId: id,
    languageBytes: { Dart: dartBytes, Other: 100 - dartBytes },
    dependencies: { pub: parsePubspec(yaml) },
    text: '',
  }
}

const pubspec = `name: todo
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
`

Deno.test('the starter dictionary is valid and the approved names are present', () => {
  assertEquals(dictionaryProblems(skills), [])
  for (const name of ['Flutter', 'Dart', 'React', 'TypeScript', 'Python', 'Docker', 'PostgreSQL', 'Swift', 'Kotlin']) {
    assertEquals(skills.some((skill) => skill.name === name), true)
  }
})

Deno.test('a Flutter repo suggests Flutter, Provider and Dart', () => {
  const result = extractSuggestions({
    sources: [repo('repo-1', pubspec)],
    existingNames: [],
    dictionary: skills,
  })
  assertEquals(result.suggestions.map((item) => item.name).sort(), ['Dart', 'Flutter', 'Provider'])
  const provider = result.suggestions.find((item) => item.name === 'Provider')
  assertEquals(provider?.signals, ['dependency:pub:provider'])
})

Deno.test('an existing Flutter skill is not suggested again', () => {
  const result = extractSuggestions({
    sources: [repo('repo-1', pubspec)],
    existingNames: ['flutter'],
    dictionary: skills,
  })
  assertEquals(result.suggestions.map((item) => item.name).sort(), ['Dart', 'Provider'])
})

Deno.test('the word react in a sentence is not the React skill', () => {
  const result = extractSuggestions({
    sources: [{ evidenceId: 'repo-1', text: 'we react quickly to issues' }],
    existingNames: [],
    dictionary: skills,
  })
  assertEquals(result.suggestions.some((item) => item.name === 'React'), false)
})

Deno.test('the same library in two repos is one suggestion', () => {
  const result = extractSuggestions({
    sources: [repo('repo-1', pubspec), repo('repo-2', pubspec)],
    existingNames: [],
    dictionary: skills,
  })
  const provider = result.suggestions.find((item) => item.name === 'Provider')
  assertEquals(provider?.evidenceIds, ['repo-1', 'repo-2'])
})

Deno.test('every unreadable source fails the job', () => {
  const result = extractSuggestions({
    sources: [
      { evidenceId: 'repo-1', failed: true },
      { evidenceId: 'link-1', failed: true },
    ],
    existingNames: [],
    dictionary: skills,
  })
  assertEquals(result.errorCode, 'SOURCE_UNREADABLE')
})

Deno.test('starting a job never sends personal fields', () => {
  const input = jobInput(['evidence-1'])
  assertEquals(Object.keys(input), ['evidence_ids'])
  assertEquals(gateStatus('CONSENT_REQUIRED'), 403)
  assertEquals(gateStatus('QUOTA_EXCEEDED'), 429)
})
