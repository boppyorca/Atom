import { normalizeSkillName, type DictionarySkill } from './extract.ts'

export type GapItem = {
  skill: string
  confidence?: string
  suggestion?: { vi: string; en: string }
}

export type GapResult =
  | { status: 'no_known_skills' }
  | { status: 'ok'; have: GapItem[]; missing: GapItem[] }

function firstIndex(text: string, word: string, sensitive: boolean): number {
  if (word.length === 0) return -1
  const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const pattern = new RegExp(
    `(^|[^A-Za-z0-9_])(${escaped})(?=[^A-Za-z0-9_]|$)`,
    sensitive ? 'g' : 'gi',
  )
  const match = pattern.exec(text)
  if (!match) return -1
  return match.index + match[1].length
}

function earliest(text: string, skill: DictionarySkill): number {
  const indexes = [
    ...skill.aliases.map((word) => firstIndex(text, word, false)),
    ...skill.signals.keywords.map((word) => firstIndex(text, word, false)),
    ...skill.signals.keywords_case_sensitive.map((word) => firstIndex(text, word, true)),
  ].filter((index) => index >= 0)
  if (indexes.length === 0) return -1
  return Math.min(...indexes)
}

export function analyzeGap(input: {
  description: string
  skills: { name: string; confidence: string }[]
  dictionary: DictionarySkill[]
}): GapResult {
  const found = input.dictionary
    .map((skill) => ({ skill, index: earliest(input.description, skill) }))
    .filter((item) => item.index >= 0)
    .sort((a, b) => a.index - b.index || a.skill.name.localeCompare(b.skill.name))

  if (found.length === 0) return { status: 'no_known_skills' }

  const have: GapItem[] = []
  const missing: GapItem[] = []
  for (const item of found) {
    const labels = new Set(
      [item.skill.name, ...item.skill.aliases].map(normalizeSkillName),
    )
    const owned = input.skills.find((skill) => labels.has(normalizeSkillName(skill.name)))
    if (owned) {
      have.push({ skill: item.skill.name, confidence: owned.confidence })
    } else {
      missing.push({ skill: item.skill.name, suggestion: item.skill.suggestion })
    }
  }
  return { status: 'ok', have, missing }
}
