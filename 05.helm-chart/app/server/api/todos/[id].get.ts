

export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const todo = await prisma.todo.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
    },
  })

  if (!todo) {
    throw createError({ statusCode: 404, statusMessage: 'Todo not found' })
  }

  return todo
})
