import { assertEquals } from 'jsr:@std/assert@1'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import {
  extractSuggestions,
  signalTypeFor,
  type DictionarySkill,
  type SourceSnapshot,
} from '../_shared/extract.ts'
import { scoreAuthorCommits, type RawCommit, type SkillPathRule } from '../_shared/commit_signals.ts'

const skills = dictionary as unknown as DictionarySkill[]
const rules: SkillPathRule[] = skills.map((skill) => ({
  name: skill.name,
  extensions: skill.signals.extensions ?? [],
  files: skill.signals.files,
  dependencies: Object.values(skill.signals.dependencies ?? {}).flat(),
}))

function namesOf(source: SourceSnapshot): string[] {
  return extractSuggestions({ sources: [source], existingNames: [], dictionary: skills })
    .suggestions.map((item) => item.name).sort()
}

function onlyKeyword(source: SourceSnapshot): boolean {
  const result = extractSuggestions({ sources: [source], existingNames: [], dictionary: skills })
  return result.suggestions.every((item) =>
    item.signals.every((signal) => signalTypeFor(signal) === 'readme_keyword')
  )
}

const pubspec = `name: app
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
`

const codeRepo: SourceSnapshot = {
  evidenceId: 'repo',
  languageBytes: { Dart: 90, Other: 10 },
  dependencies: { pub: ['flutter', 'provider'] },
  rootFiles: ['pubspec.yaml'],
  text: '',
}

const stuffedReadme: SourceSnapshot = {
  evidenceId: 'readme',
  text: 'Yêu cầu Flutter, Kubernetes, Rust, Docker, Python, React, PostgreSQL, Swift, Kotlin, Go, TypeScript',
}

const cases: { name: string; check: () => void }[] = [
  { name: 'flutter app suggests Flutter, Provider and Dart', check: () => {
    assertEquals(namesOf(codeRepo), ['Dart', 'Flutter', 'Provider'])
  } },
  { name: 'readme stuffing does not invent skills outside the dictionary', check: () => {
    const found = namesOf(stuffedReadme)
    assertEquals(found.includes('Kubernetes'), false)
    assertEquals(found.includes('Rust'), false)
    assertEquals(found.includes('Flutter'), true)
  } },
  { name: 'readme stuffing is only a weak keyword signal', check: () => {
    assertEquals(onlyKeyword(stuffedReadme), true)
  } },
]

for (const word of ['Flutter', 'Docker', 'Python', 'React', 'PostgreSQL', 'Swift', 'Kotlin', 'Go']) {
  cases.push({
    name: `readme mention of ${word} is a keyword, not a commit`,
    check: () => {
      const source = { evidenceId: word, text: `We use ${word} every day.` }
      assertEquals(onlyKeyword(source), true)
    },
  })
}

cases.push({
  name: 'a commit that only edits the README does not count as authored code',
  check: () => {
    const score = scoreAuthorCommits({
      login: 'minh',
      repoDependencies: ['flutter'],
      skills: rules,
      commits: [{
        sha: '1',
        authorLogin: 'minh',
        date: '2026-03-01T00:00:00Z',
        parentCount: 1,
        files: [{ filename: 'README.md', additions: 80 }],
      }],
    })
    assertEquals(score, null)
  },
})

for (let index = 1; index <= 10; index += 1) {
  cases.push({
    name: `dart commit ${index} by the saved login counts`,
    check: () => {
      const score = scoreAuthorCommits({
        login: 'minh',
        repoDependencies: [],
        skills: rules,
        commits: [{
          sha: String(index),
          authorLogin: 'minh',
          date: `2026-04-${String(index).padStart(2, '0')}T00:00:00Z`,
          parentCount: 1,
          files: [{ filename: `lib/file_${index}.dart`, additions: 30 }],
        }],
      })
      assertEquals(score?.skillNames.includes('Dart'), true)
    },
  })
}

for (let index = 1; index <= 8; index += 1) {
  cases.push({
    name: `someone else commit ${index} is ignored`,
    check: () => {
      const score = scoreAuthorCommits({
        login: 'minh',
        repoDependencies: [],
        skills: rules,
        commits: [{
          sha: `other-${index}`,
          authorLogin: 'other',
          date: '2026-05-01T00:00:00Z',
          parentCount: 1,
          files: [{ filename: 'lib/main.dart', additions: 50 }],
        }],
      })
      assertEquals(score, null)
    },
  })
}

Deno.test(`labeled repo set has 30 cases and every case matches the current rules`, () => {
  assertEquals(cases.length, 30)
  for (const item of cases) item.check()
})
