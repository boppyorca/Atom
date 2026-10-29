export const agentPrinciples = [
  'Chỉ đề xuất. Không nói là đã sửa hồ sơ.',
  'Không hỏi và không nhắc lương, email, số điện thoại, liên hệ.',
  'Không bịa số lương.',
  'Không chắc thì nói một câu ngắn.',
  'Mỗi đề xuất để người dùng nhận hoặc bỏ.',
].join('\n')

export type ChatSkill = { name: string; confidence: string }
export type ChatRepo = {
  fullName: string
  files: string[]
  libraries: string[]
  intro: string
}
export type ChatPacket = {
  question: string
  skills: ChatSkill[]
  repos: ChatRepo[]
}
export type ChatProposalDraft = { title: string; detail: string }

const privateKeys = ['salary', 'email', 'contact', 'phone', 'display_name']

export function buildPacket(input: {
  question: string
  skills: ChatSkill[]
  repos: ChatRepo[]
}): ChatPacket {
  return {
    question: input.question.trim(),
    skills: input.skills.map((skill) => ({
      name: skill.name,
      confidence: skill.confidence,
    })),
    repos: input.repos.slice(0, 10).map((repo) => ({
      fullName: repo.fullName,
      files: repo.files,
      libraries: repo.libraries,
      intro: repo.intro.slice(0, 4000),
    })),
  }
}

export function packetHasPrivateFields(packet: ChatPacket): boolean {
  const keys = new Set<string>()
  const walk = (value: unknown) => {
    if (!value || typeof value !== 'object') return
    for (const [key, child] of Object.entries(value)) {
      keys.add(key)
      walk(child)
    }
  }
  walk(packet)
  return privateKeys.some((key) => keys.has(key))
}

export async function firstReply(calls: {
  ollama: () => Promise<string | null>
  groq: () => Promise<string | null>
  zai: () => Promise<string | null>
}): Promise<{ provider: 'ollama' | 'groq' | 'zai'; text: string } | null> {
  const local = await calls.ollama()
  if (local) return { provider: 'ollama', text: local }
  const groq = await calls.groq()
  if (groq) return { provider: 'groq', text: groq }
  const zai = await calls.zai()
  if (zai) return { provider: 'zai', text: zai }
  return null
}

export function parseReply(text: string): { reply: string; proposals: ChatProposalDraft[] } {
  const trimmed = text.trim()
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/)
  const source = fenced?.[1]?.trim() || trimmed
  try {
    const data = JSON.parse(source) as { reply?: unknown; proposals?: unknown }
    const reply = typeof data.reply === 'string' ? data.reply.trim() : ''
    const proposals = Array.isArray(data.proposals)
      ? data.proposals.flatMap((item) => {
        if (!item || typeof item !== 'object') return []
        const title = String((item as { title?: unknown }).title ?? '').trim().slice(0, 50)
        const detail = String((item as { detail?: unknown }).detail ?? '').trim().slice(0, 500)
        return title ? [{ title, detail }] : []
      })
      : []
    if (reply) return { reply, proposals }
  } catch {
    // A plain sentence is still an answer.
  }
  return { reply: trimmed.slice(0, 4000), proposals: [] }
}

export function localModelfile(
  base: string,
  reviews: { title: string; status: string }[],
): string {
  const lines = reviews.slice(-40).map((review) => {
    const decision = review.status === 'accepted' ? 'nhận' : 'bỏ'
    return `- ${decision}: ${review.title.replaceAll('\n', ' ')}`
  })
  const examples = lines.length ? lines.join('\n') : '- chưa có lần nhận hoặc bỏ'
  return `FROM ${base}\nSYSTEM """\n${agentPrinciples}\n\nCác lần người dùng đã chọn:\n${examples}\n"""\n`
}
