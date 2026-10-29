import { createClient } from 'jsr:@supabase/supabase-js@2'
import { accountToDelete } from '../_shared/delete_account.ts'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

Deno.serve(async (request) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const authHeader = request.headers.get('Authorization')
  if (!supabaseUrl || !serviceKey || !anonKey || !authHeader) {
    return json({ code: 'INTERNAL' }, 500)
  }
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) return json({ code: 'UNAUTHORIZED' }, 401)
  let body: { confirm?: boolean; id?: string } = {}
  try {
    body = await request.json()
  } catch {
    body = {}
  }
  const userId = accountToDelete(userData.user.id, body)
  if (!userId) return json({ code: 'CONFIRM_REQUIRED' }, 400)
  const admin = createClient(supabaseUrl, serviceKey)
  const { error } = await admin.auth.admin.deleteUser(userId)
  if (error) return json({ code: 'INTERNAL' }, 500)
  return json({ deleted: true })
})
