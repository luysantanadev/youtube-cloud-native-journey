

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body?.name || typeof body.name !== 'string' || body.name.trim() === '') {
    throw createError({ statusCode: 400, statusMessage: 'name is required' })
  }

  const userId = Number(body.userId)
  const categoryId = Number(body.categoryId)

  if (!userId || isNaN(userId)) {
    throw createError({ statusCode: 400, statusMessage: 'userId is required' })
  }
  if (!categoryId || isNaN(categoryId)) {
    throw createError({ statusCode: 400, statusMessage: 'categoryId is required' })
  }

  return prisma.todo.create({
    data: {
      name: body.name.trim(),
      description: body.description?.trim() || null,
      finishedAt: body.finishedAt ? new Date(body.finishedAt) : null,
      userId,
      categoryId,
    },
    include: {
      user: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
    },
  })
})
