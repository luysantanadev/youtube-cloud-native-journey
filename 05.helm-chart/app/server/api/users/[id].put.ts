

export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const body = await readBody(event)

  if (!body?.name || typeof body.name !== 'string' || body.name.trim() === '') {
    throw createError({ statusCode: 400, statusMessage: 'name is required' })
  }

  try {
    return await prisma.user.update({ where: { id }, data: { name: body.name.trim() } })
  } catch {
    throw createError({ statusCode: 404, statusMessage: 'User not found' })
  }
})
