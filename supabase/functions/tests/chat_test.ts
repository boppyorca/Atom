import { assertEquals } from 'jsr:@std/assert@1'
import {
  buildPacket,
  firstReply,
  localModelfile,
  packetHasPrivateFields,
  parseReply,
} from '../_shared/chat.ts'

Deno.test('a local answer stops the later providers', async () => {
  const calls = { groq: 0, zai: 0 }
  const result = await firstReply({
    ollama: () => Promise.resolve('máy nhà'),
    groq: () => {
      calls.groq += 1
      return Promise.resolve('groq')
    },
    zai: () => {
      calls.zai += 1
      return Promise.resolve('zai')
    },
  })
  assertEquals(result?.provider, 'ollama')
  assertEquals(calls, { groq: 0, zai: 0 })
})

Deno.test('Groq is used only after the home model is silent', async () => {
  const calls = { zai: 0 }
  const result = await firstReply({
    ollama: () => Promise.resolve(null),
    groq: () => Promise.resolve('groq'),
    zai: () => {
      calls.zai += 1
      return Promise.resolve('zai')
    },
  })
  assertEquals(result?.provider, 'groq')
  assertEquals(calls.zai, 0)
})

Deno.test('Z.ai is the last free model', async () => {
  const result = await firstReply({
    ollama: () => Promise.resolve(null),
    groq: () => Promise.resolve(null),
    zai: () => Promise.resolve('glm'),
  })
  assertEquals(result, { provider: 'zai', text: 'glm' })
})

Deno.test('silence from all three is a failure without an answer', async () => {
  const result = await firstReply({
    ollama: () => Promise.resolve(null),
    groq: () => Promise.resolve(null),
    zai: () => Promise.resolve(null),
  })
  assertEquals(result, null)
})

Deno.test('the packet sent out has skills and repos, not private fields', () => {
  const packet = buildPacket({
    question: 'Mình còn thiếu gì?',
    skills: [{ name: 'Flutter', confidence: 'evidenced' }],
    repos: [{
      fullName: 'minh/todo',
      files: ['README.md'],
      libraries: ['flutter'],
      intro: 'A todo app',
    }],
  })
  assertEquals(packet.skills[0].name, 'Flutter')
  assertEquals(packet.repos[0].fullName, 'minh/todo')
  assertEquals(packetHasPrivateFields(packet), false)
})

Deno.test('a JSON answer becomes proposals and a sentence stays a sentence', () => {
  const parsed = parseReply('{"reply":"Bạn đã có Flutter.","proposals":[{"title":"CI/CD","detail":"Thêm một bước."}]}')
  assertEquals(parsed.proposals[0].title, 'CI/CD')
  assertEquals(parseReply('Chưa chắc.').proposals, [])
})

Deno.test('the local model file learns accepted and rejected titles on this machine', () => {
  const file = localModelfile('llama3.2', [
    { title: 'CI/CD', status: 'accepted' },
    { title: 'Lương ảo', status: 'rejected' },
  ])
  assertEquals(file.startsWith('FROM llama3.2'), true)
  assertEquals(file.includes('nhận: CI/CD'), true)
  assertEquals(file.includes('bỏ: Lương ảo'), true)
  assertEquals(file.includes('api.groq.com'), false)
  assertEquals(file.includes('api.z.ai'), false)
})

Deno.test('the chat function does not log the question', async () => {
  const source = await Deno.readTextFile(new URL('../chat-ask/index.ts', import.meta.url))
  assertEquals(source.includes('console.'), false)
})
