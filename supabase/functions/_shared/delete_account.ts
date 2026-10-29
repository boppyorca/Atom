export function accountToDelete(
  userId: string,
  body: { confirm?: boolean; id?: string },
): string | null {
  if (body.confirm !== true) return null
  return userId
}
