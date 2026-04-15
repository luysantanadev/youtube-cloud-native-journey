

export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const user = await prisma.user.findUnique({ where: { id } })

  if (!user) {
    throw createError({ statusCode: 404, statusMessage: 'User not found' })
  }

  return user
})
