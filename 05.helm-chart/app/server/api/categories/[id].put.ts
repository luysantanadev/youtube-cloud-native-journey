export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const body = await readBody(event)

  if (!body?.name || typeof body.name !== 'string' || body.name.trim() === '') {
    throw createError({ statusCode: 400, statusMessage: 'name is required' })
  }

  const name = body.name.trim()

  try {
    return await prisma.category.update({ where: { id }, data: { name } })
  } catch {
    throw createError({ statusCode: 404, statusMessage: 'Category not found' })
  }
})
