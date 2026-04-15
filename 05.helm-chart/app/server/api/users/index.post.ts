

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body?.name || typeof body.name !== 'string' || body.name.trim() === '') {
    throw createError({ statusCode: 400, statusMessage: 'name is required' })
  }

  try {
    return await prisma.user.create({ data: { name: body.name.trim() } })
  } catch {
    throw createError({ statusCode: 409, statusMessage: 'A user with that name already exists' })
  }
})
