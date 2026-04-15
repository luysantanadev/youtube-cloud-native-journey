export default defineEventHandler(async () => {
  return prisma.category.findMany({
    orderBy: { name: 'asc' },
  })
})
