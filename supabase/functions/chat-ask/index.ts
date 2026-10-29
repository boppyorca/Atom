import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import {
  agentPrinciples,
  buildPacket,
  firstReply,
  localModelfile,
  parseReply,
  type ChatRepo,
  type ChatSkill,
} from '../_shared/chat.ts'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

function gateStatus(message: string): { code: string; status: number } | null {
  if (message.includes('CONSENT_REQUIRED')) return { code: 'CONSENT_REQUIRED', status: 403 }
  if (message.includes('QUOTA_EXCEEDED')) return { code: 'QUOTA_EXCEEDED', status: 429 }
  if (message.includes('INPUT_INVALID')) return { code: 'INPUT_INVALID', status: 422 }
  return null
}

function ollamaHosts(): string[] {
  const configured = Deno.env.get('OLLAMA_BASE_URL')
  return [configured, 'http://host.docker.internal:11434', 'http://127.0.0.1:11434']
    .filter((host): host is string => Boolean(host))
}

async function localModels(host: string): Promise<string[]> {
  const response = await fetch(`${host}/api/tags`, { signal: AbortSignal.timeout(2000) })
  if (!response.ok) return []
  const body = await response.json() as { models?: { name?: string }[] }
  return (body.models ?? []).map((model) => model.name).filter((name): name is string => Boolean(name))
}

async function askOllama(packetText: string): Promise<string | null> {
  for (const host of ollamaHosts()) {
    try {
      const names = await localModels(host)
      const model = names.find((name) => name.startsWith('atom-local')) ?? names[0]
      if (!model) continue
      const response = await fetch(`${host}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(20000),
        body: JSON.stringify({
          model,
          stream: false,
          messages: [
            {
              role: 'system',
              content: `${agentPrinciples}\nTrả về JSON với reply và proposals.`,
            },
            { role: 'user', content: packetText },
          ],
        }),
      })
      if (!response.ok) continue
      const data = await response.json() as { message?: { content?: string } }
      const text = data.message?.content?.trim()
      if (text) return text
    } catch {
      continue
    }
  }
  return null
}

async function askOpenAICompatible(
  url: string,
  key: string,
  model: string,
  packetText: string,
): Promise<string | null> {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(20000),
      body: JSON.stringify({
        model,
        stream: false,
        messages: [
          { role: 'system', content: `${agentPrinciples}\nTrả về JSON với reply và proposals.` },
          { role: 'user', content: packetText },
        ],
      }),
    })
    if (!response.ok) return null
    const data = await response.json() as { choices?: { message?: { content?: string } }[] }
    const text = data.choices?.[0]?.message?.content?.trim()
    return text || null
  } catch {
    return null
  }
}

async function repoContext(
  admin: SupabaseClient,
  profileId: string,
): Promise<ChatRepo[]> {
  const { data } = await admin
    .from('evidence')
    .select('github_full_name')
    .eq('profile_id', profileId)
    .eq('kind', 'github_repo')
    .limit(10)
  const token = Deno.env.get('GITHUB_PUBLIC_READ_TOKEN')
  const repos: ChatRepo[] = []
  for (const row of data ?? []) {
    const fullName = row.github_full_name as string | null
    if (!fullName) continue
    const repo: ChatRepo = { fullName, files: [], libraries: [], intro: '' }
    if (token) {
      try {
        const encoded = fullName.split('/').map(encodeURIComponent).join('/')
        const headers = {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'User-Agent': 'atom',
        }
        const readme = await fetch(`https://api.github.com/repos/${encoded}/readme`, {
          headers,
          signal: AbortSignal.timeout(8000),
        })
        if (readme.ok) {
          const payload = await readme.json() as { content?: string }
          if (typeof payload.content === 'string') {
            repo.intro = atob(payload.content.replaceAll('\n', '')).slice(0, 4000)
          }
        }
        const root = await fetch(`https://api.github.com/repos/${encoded}/contents/`, {
          headers,
          signal: AbortSignal.timeout(8000),
        })
        if (root.ok) {
          const entries = await root.json() as { type?: string; name?: string }[]
          if (Array.isArray(entries)) {
            repo.files = entries
              .filter((item) => item.type === 'file' && item.name)
              .map((item) => item.name as string)
              .slice(0, 30)
          }
        }
      } catch {
        // The repo name still goes with the question.
      }
    }
    repos.push(repo)
  }
  return repos
}

async function saveTurn(
  admin: SupabaseClient,
  profileId: string,
  question: string,
  provider: string,
  reply: string,
  proposals: { title: string; detail: string }[],
): Promise<void> {
  const existing = await admin
    .from('chat_threads')
    .select('id')
    .eq('profile_id', profileId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  let threadId = existing.data?.id as string | undefined
  if (!threadId) {
    const created = await admin
      .from('chat_threads')
      .insert({ profile_id: profileId })
      .select('id')
      .single()
    threadId = created.data?.id as string | undefined
  }
  if (!threadId) throw new Error('INTERNAL')
  await admin.from('chat_messages').insert({
    thread_id: threadId,
    profile_id: profileId,
    role: 'user',
    body: question,
  })
  const assistant = await admin
    .from('chat_messages')
    .insert({
      thread_id: threadId,
      profile_id: profileId,
      role: 'assistant',
      body: reply.slice(0, 4000),
      provider,
    })
    .select('id')
    .single()
  const messageId = assistant.data?.id as string | undefined
  if (messageId && proposals.length > 0) {
    await admin.from('chat_proposals').insert(
      proposals.map((proposal) => ({
        message_id: messageId,
        profile_id: profileId,
        title: proposal.title,
        detail: proposal.detail,
      })),
    )
  }
}

async function trainLocal(admin: SupabaseClient, profileId: string): Promise<boolean> {
  const { data } = await admin
    .from('chat_proposals')
    .select('title, status')
    .eq('profile_id', profileId)
    .in('status', ['accepted', 'rejected'])
  const reviews = (data ?? []).map((row) => ({
    title: row.title as string,
    status: row.status as string,
  }))
  for (const host of ollamaHosts()) {
    try {
      const names = await localModels(host)
      const base = names.find((name) => !name.startsWith('atom-local')) ?? names[0]
      if (!base) continue
      const response = await fetch(`${host}/api/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(60000),
        body: JSON.stringify({
          model: 'atom-local',
          modelfile: localModelfile(base, reviews),
          stream: false,
        }),
      })
      if (response.ok) return true
    } catch {
      continue
    }
  }
  return false
}

Deno.serve(async (request) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const authHeader = request.headers.get('Authorization')
  if (!supabaseUrl || !serviceKey || !anonKey || !authHeader) return json({ code: 'INTERNAL' }, 500)

  let action = 'ask'
  let question = ''
  try {
    const body = await request.json()
    action = body?.action === 'train' ? 'train' : 'ask'
    question = typeof body?.text === 'string' ? body.text.trim() : ''
  } catch {
    question = ''
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) return json({ code: 'CONSENT_REQUIRED' }, 403)
  const profileId = userData.user.id
  const admin = createClient(supabaseUrl, serviceKey)

  if (action === 'train') {
    const trained = await trainLocal(admin, profileId)
    return json({ trained })
  }

  const { error: gateError } = await admin.rpc('chat_gate', {
    p_profile_id: profileId,
    p_text: question,
  })
  if (gateError) {
    const mapped = gateStatus(gateError.message)
    return json({ code: mapped?.code ?? 'INTERNAL' }, mapped?.status ?? 500)
  }

  const { data: skillRows } = await admin
    .from('skills')
    .select('name, confidence')
    .eq('profile_id', profileId)
  const skills: ChatSkill[] = (skillRows ?? []).map((row) => ({
    name: row.name as string,
    confidence: row.confidence as string,
  }))
  const packet = buildPacket({
    question,
    skills,
    repos: await repoContext(admin, profileId),
  })
  const packetText = JSON.stringify(packet)
  const groqKey = Deno.env.get('GROQ_API_KEY')
  const zaiKey = Deno.env.get('ZAI_API_KEY')
  const answer = await firstReply({
    ollama: () => askOllama(packetText),
    groq: () => groqKey
      ? askOpenAICompatible(
        'https://api.groq.com/openai/v1/chat/completions',
        groqKey,
        Deno.env.get('GROQ_MODEL') || 'openai/gpt-oss-20b',
        packetText,
      )
      : Promise.resolve(null),
    zai: () => zaiKey
      ? askOpenAICompatible(
        'https://api.z.ai/api/paas/v4/chat/completions',
        zaiKey,
        'glm-4.7-flash',
        packetText,
      )
      : Promise.resolve(null),
  })
  if (!answer) return json({ code: 'CHAT_UNAVAILABLE' }, 502)
  const parsed = parseReply(answer.text)
  if (!parsed.reply) return json({ code: 'CHAT_UNAVAILABLE' }, 502)
  try {
    await saveTurn(admin, profileId, question, answer.provider, parsed.reply, parsed.proposals)
  } catch {
    return json({ code: 'INTERNAL' }, 500)
  }
  return json({ provider: answer.provider, reply: parsed.reply })
})
