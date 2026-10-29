export type DictionarySkill = {
  id: string
  name: string
  aliases: string[]
  signals: {
    languages: string[]
    dependencies: Record<string, string[]>
    topics: string[]
    files: string[]
    keywords: string[]
    keywords_case_sensitive: string[]
    extensions?: string[]
  }
  suggestion: { vi: string; en: string }
}

export type SourceSnapshot = {
  evidenceId: string
  failed?: boolean
  languageBytes?: Record<string, number>
  topics?: string[]
  rootFiles?: string[]
  dependencies?: Record<string, string[]>
  text?: string
}

export type Suggestion = {
  name: string
  evidenceIds: string[]
  signals: string[]
  signalTypes: string[]
}

export function signalTypeFor(signal: string): string {
  const kind = signal.split(':')[0]
  if (kind === 'language') return 'language_stat'
  if (kind === 'topic') return 'topic'
  if (kind === 'keyword') return 'readme_keyword'
  if (kind === 'dependency' || kind === 'file') return 'manifest_dependency'
  return 'readme_keyword'
}

export function normalizeSkillName(name: string): string {
  return name.trim().replace(/\s+/g, ' ').toLowerCase()
}

export function parsePubspec(yaml: string): string[] {
  const names: string[] = []
  let inDependencies = false
  for (const line of yaml.split('\n')) {
    if (!inDependencies) {
      if (/^dependencies:\s*$/.test(line)) inDependencies = true
      continue
    }
    if (/^\S/.test(line)) break
    const match = line.match(/^  ([A-Za-z0-9_]+)\s*:/)
    if (match) names.push(match[1])
  }
  return names
}

function wholeWord(text: string, word: string, sensitive: boolean): boolean {
  const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const pattern = new RegExp(
    `(^|[^A-Za-z0-9_])${escaped}([^A-Za-z0-9_]|$)`,
    sensitive ? '' : 'i',
  )
  return pattern.test(text)
}

function languagesOf(source: SourceSnapshot): string[] {
  const bytes = source.languageBytes ?? {}
  const total = Object.values(bytes).reduce((sum, value) => sum + value, 0)
  if (total <= 0) return []
  return Object.entries(bytes)
    .filter(([, value]) => value / total >= 0.1)
    .map(([name]) => name)
}

const rank: Record<string, number> = {
  dependency: 4,
  language: 3,
  topic: 2,
  file: 2,
  keyword: 1,
}

export function extractSuggestions(input: {
  sources: SourceSnapshot[]
  existingNames: string[]
  blockedNames?: string[]
  dictionary: DictionarySkill[]
}): { suggestions: Suggestion[]; errorCode?: 'SOURCE_UNREADABLE' } {
  const readable = input.sources.filter((source) => !source.failed)
  if (input.sources.length > 0 && readable.length === 0) {
    return { suggestions: [], errorCode: 'SOURCE_UNREADABLE' }
  }
  const owned = new Set(input.existingNames.map(normalizeSkillName))
  const blocked = new Set((input.blockedNames ?? []).map(normalizeSkillName))
  const found = new Map<string, Suggestion>()

  for (const source of readable) {
    for (const skill of input.dictionary) {
      const signals: string[] = []
      for (const language of languagesOf(source)) {
        if (skill.signals.languages.includes(language)) signals.push(`language:${language}`)
      }
      for (const [ecosystem, names] of Object.entries(source.dependencies ?? {})) {
        const known = new Set((skill.signals.dependencies[ecosystem] ?? []).map((name) => name.toLowerCase()))
        for (const name of names) {
          if (known.has(name.toLowerCase())) signals.push(`dependency:${ecosystem}:${name.toLowerCase()}`)
        }
      }
      for (const topic of source.topics ?? []) {
        if (skill.signals.topics.map((item) => item.toLowerCase()).includes(topic.toLowerCase())) {
          signals.push(`topic:${topic.toLowerCase()}`)
        }
      }
      for (const file of source.rootFiles ?? []) {
        if (skill.signals.files.includes(file)) signals.push(`file:${file}`)
      }
      const text = source.text ?? ''
      for (const keyword of skill.signals.keywords) {
        if (wholeWord(text, keyword, false)) signals.push(`keyword:${keyword.toLowerCase()}`)
      }
      for (const keyword of skill.signals.keywords_case_sensitive) {
        if (wholeWord(text, keyword, true)) signals.push(`keyword:${keyword}`)
      }
      const strong = signals.filter((signal) => !(signal.startsWith('keyword:') && signal.slice('keyword:'.length).length < 3))
      if (strong.length === 0) continue
      const current = found.get(skill.id) ?? {
        name: skill.name,
        evidenceIds: [],
        signals: [],
        signalTypes: [],
      }
      if (!current.evidenceIds.includes(source.evidenceId)) current.evidenceIds.push(source.evidenceId)
      for (const signal of strong) {
        if (!current.signals.includes(signal)) current.signals.push(signal)
        const signalType = signalTypeFor(signal)
        if (!current.signalTypes.includes(signalType)) current.signalTypes.push(signalType)
      }
      found.set(skill.id, current)
    }
  }

  const suggestions = [...found.values()].filter((suggestion) => {
    const names = input.dictionary.find((skill) => skill.name === suggestion.name)
    const aliases = [suggestion.name, ...(names?.aliases ?? [])].map(normalizeSkillName)
    return aliases.every((alias) => !owned.has(alias) && !blocked.has(alias))
  })
  suggestions.sort((a, b) => {
    if (a.evidenceIds.length !== b.evidenceIds.length) return b.evidenceIds.length - a.evidenceIds.length
    const best = (signals: string[]) => Math.max(...signals.map((signal) => rank[signal.split(':')[0]] ?? 0))
    if (best(a.signals) !== best(b.signals)) return best(b.signals) - best(a.signals)
    return a.name.localeCompare(b.name)
  })
  return { suggestions: suggestions.slice(0, 20) }
}

export function dictionaryProblems(dictionary: DictionarySkill[]): string[] {
  const problems: string[] = []
  const ids = new Set<string>()
  const names = new Set<string>()
  for (const skill of dictionary) {
    if (ids.has(skill.id)) problems.push(`duplicate id ${skill.id}`)
    ids.add(skill.id)
    const labels = new Set([skill.name, ...skill.aliases].map(normalizeSkillName))
    for (const normalized of labels) {
      if (names.has(normalized)) problems.push(`duplicate name ${normalized}`)
      names.add(normalized)
    }
    if (!skill.suggestion.vi || !skill.suggestion.en) problems.push(`missing suggestion ${skill.id}`)
  }
  return problems
}

export function jobInput(evidenceIds: string[]): { evidence_ids: string[] } {
  return { evidence_ids: evidenceIds }
}

export function gateStatus(code: string | null): number | null {
  if (code === 'CONSENT_REQUIRED') return 403
  if (code === 'QUOTA_EXCEEDED') return 429
  if (code === 'JOB_ALREADY_RUNNING') return 409
  if (code === 'NO_SOURCES' || code === 'NO_SKILLS' || code === 'INPUT_INVALID') {
    return 422
  }
  return null
}
