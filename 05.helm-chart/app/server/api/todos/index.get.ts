

export default defineEventHandler(async () => {
  return prisma.todo.findMany({
    orderBy: { createdAt: 'desc' },
    include: {
      user: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
    },
  })
})
