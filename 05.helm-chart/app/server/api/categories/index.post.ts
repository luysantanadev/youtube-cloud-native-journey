export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body?.name || typeof body.name !== 'string' || body.name.trim() === '') {
    throw createError({ statusCode: 400, statusMessage: 'name is required' })
  }

  const name = body.name.trim()

  try {
    return await prisma.category.create({ data: { name } })
  } catch {
    throw createError({ statusCode: 409, statusMessage: 'A category with that name already exists' })
  }
})
