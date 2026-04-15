<script setup lang="ts">
import { h, resolveComponent } from 'vue'
import type { TableColumn, DropdownMenuItem } from '@nuxt/ui'

definePageMeta({ title: 'Todos' })

const UBadge = resolveComponent('UBadge')
const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const router = useRouter()
const toast = useToast()

const { data: todos, refresh, status } = await useFetch('/api/todos')

type Todo = NonNullable<typeof todos.value>[number]

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  return new Date(value).toLocaleString()
}

async function remove(id: number) {
  await $fetch(`/api/todos/${id}`, { method: 'DELETE' })
  await refresh()
  toast.add({ title: 'Todo deleted', icon: 'i-lucide-circle-check', color: 'success' })
}

function getActions(row: Todo): DropdownMenuItem[][] {
  return [
    [{ label: 'Edit', icon: 'i-lucide-pencil', onSelect: () => router.push(`/todos/${row.id}/edit`) }],
    [{ label: 'Delete', icon: 'i-lucide-trash', color: 'error' as const, onSelect: () => remove(row.id) }],
  ]
}

const columns: TableColumn<Todo>[] = [
  { accessorKey: 'id', header: 'ID', meta: { class: { th: 'w-12' } } },
  { accessorKey: 'name', header: 'Name' },
  {
    accessorKey: 'description',
    header: 'Description',
    cell: ({ row }) => row.getValue('description') ?? '—',
  },
  {
    id: 'user',
    header: 'User',
    cell: ({ row }) => row.original.user.name,
  },
  {
    id: 'category',
    header: 'Category',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: 'primary' }, () => row.original.category.name),
  },
  {
    accessorKey: 'createdAt',
    header: 'Created',
    cell: ({ row }) => formatDate(row.getValue('createdAt')),
  },
  {
    accessorKey: 'finishedAt',
    header: 'Finished',
    cell: ({ row }) => {
      const v = row.getValue<string | null>('finishedAt')
      return v
        ? h(UBadge, { variant: 'subtle', color: 'success' }, () => formatDate(v))
        : h('span', { class: 'text-muted' }, '—')
    },
  },
  {
    id: 'actions',
    meta: { class: { td: 'text-right' } },
    cell: ({ row }) =>
      h(UDropdownMenu, {
        items: getActions(row.original),
        content: { align: 'end' },
        'aria-label': 'Actions',
      }, () => h(UButton, {
        icon: 'i-lucide-ellipsis-vertical',
        color: 'neutral',
        variant: 'ghost',
        'aria-label': 'Actions',
      })),
  },
]
</script>

<template>
  <UDashboardPanel id="todos">
    <template #header>
      <UDashboardNavbar title="Todos">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UButton icon="i-lucide-plus" to="/todos/new">New Todo</UButton>
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <UTable
        :data="todos ?? []"
        :columns="columns"
        :loading="status === 'pending'"
        class="flex-1"
      />
    </template>
  </UDashboardPanel>
</template>
