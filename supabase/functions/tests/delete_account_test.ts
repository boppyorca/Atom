import { assertEquals } from 'jsr:@std/assert@1'
import { accountToDelete } from '../_shared/delete_account.ts'

Deno.test('delete uses the signed-in person, not an id sent by the app', () => {
  assertEquals(
    accountToDelete('user-a', { confirm: true, id: 'user-b' }),
    'user-a',
  )
  assertEquals(accountToDelete('user-a', { confirm: false, id: 'user-a' }), null)
})
