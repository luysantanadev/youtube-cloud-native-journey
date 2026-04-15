

export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  try {
    await prisma.user.delete({ where: { id } })
    return { success: true }
  } catch {
    throw createError({ statusCode: 404, statusMessage: 'User not found' })
  }
})
