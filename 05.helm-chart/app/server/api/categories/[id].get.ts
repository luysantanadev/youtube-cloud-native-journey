export default defineEventHandler(async (event) => {
  const id = parseInt(getRouterParam(event, 'id') ?? '')

  if (isNaN(id)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid id' })
  }

  const category = await prisma.category.findUnique({ where: { id } })

  if (!category) {
    throw createError({ statusCode: 404, statusMessage: 'Category not found' })
  }

  return category
})
