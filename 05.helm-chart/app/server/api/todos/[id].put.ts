

export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

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

  try {
    return await prisma.todo.update({
      where: { id },
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
  } catch {
    throw createError({ statusCode: 404, statusMessage: 'Todo not found' })
  }
})
