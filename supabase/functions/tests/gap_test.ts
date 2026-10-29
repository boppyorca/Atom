import { assertEquals } from 'jsr:@std/assert@1'
import dictionary from '../_shared/skill_dictionary.json' with { type: 'json' }
import { analyzeGap } from '../_shared/gap.ts'
import type { DictionarySkill } from '../_shared/extract.ts'

const skills = dictionary as unknown as DictionarySkill[]

Deno.test('a job asking for Flutter, REST API and CI/CD splits have and missing', () => {
  const result = analyzeGap({
    description: 'Yêu cầu Flutter, REST API, CI/CD',
    skills: [{ name: 'Flutter', confidence: 'evidenced' }],
    dictionary: skills,
  })
  assertEquals(result, {
    status: 'ok',
    have: [{ skill: 'Flutter', confidence: 'evidenced' }],
    missing: [
      {
        skill: 'REST API',
        suggestion: { vi: 'Viết một REST API nhỏ.', en: 'Build a small REST API.' },
      },
      {
        skill: 'CI/CD',
        suggestion: { vi: 'Thêm một bước CI/CD.', en: 'Add a CI/CD step.' },
      },
    ],
  })
})

Deno.test('a job with no known technology reports that nothing was recognized', () => {
  const result = analyzeGap({
    description: 'Cần người hòa đồng và chịu khó',
    skills: [{ name: 'Flutter', confidence: 'self_claimed' }],
    dictionary: skills,
  })
  assertEquals(result, { status: 'no_known_skills' })
})

Deno.test('a repeated skill is listed once', () => {
  const result = analyzeGap({
    description: 'Flutter, then Flutter again, and Flutter',
    skills: [],
    dictionary: skills,
  })
  assertEquals(result.status, 'ok')
  if (result.status !== 'ok') return
  assertEquals(result.missing.filter((item) => item.skill === 'Flutter').length, 1)
})

Deno.test('extra spaces and lowercase still count as a skill the person has', () => {
  const result = analyzeGap({
    description: 'We need Flutter',
    skills: [{ name: 'flutter ', confidence: 'self_claimed' }],
    dictionary: skills,
  })
  assertEquals(result, {
    status: 'ok',
    have: [{ skill: 'Flutter', confidence: 'self_claimed' }],
    missing: [],
  })
})

Deno.test('Go matches the capital word and ignores go to market', () => {
  const result = analyzeGap({
    description: 'Experience with Go and a go to market plan',
    skills: [],
    dictionary: skills,
  })
  assertEquals(result.status, 'ok')
  if (result.status !== 'ok') return
  assertEquals(result.missing.map((item) => item.skill), ['Go'])
})

Deno.test('the gap function does not log the job text', async () => {
  const source = await Deno.readTextFile(
    new URL('../analyze-gap/index.ts', import.meta.url),
  )
  assertEquals(source.includes('console.'), false)
  assertEquals(source.includes('job_description:'), false)
})
