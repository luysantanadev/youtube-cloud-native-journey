

export default defineEventHandler(async () => {
  return prisma.user.findMany({ orderBy: { createdAt: 'desc' } })
})
