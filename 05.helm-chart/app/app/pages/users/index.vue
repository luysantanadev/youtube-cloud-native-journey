<script setup lang="ts">
import { h, resolveComponent } from 'vue'
import type { TableColumn, DropdownMenuItem } from '@nuxt/ui'

definePageMeta({ title: 'Users' })

const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const router = useRouter()
const toast = useToast()

const { data: users, refresh, status } = await useFetch('/api/users')

type User = NonNullable<typeof users.value>[number]

async function remove(id: number) {
  await $fetch(`/api/users/${id}`, { method: 'DELETE' })
  await refresh()
  toast.add({ title: 'User deleted', icon: 'i-lucide-circle-check', color: 'success' })
}

function getActions(row: User): DropdownMenuItem[][] {
  return [
    [{ label: 'Edit', icon: 'i-lucide-pencil', onSelect: () => router.push(`/users/${row.id}/edit`) }],
    [{ label: 'Delete', icon: 'i-lucide-trash', color: 'error' as const, onSelect: () => remove(row.id) }],
  ]
}

const columns: TableColumn<User>[] = [
  { accessorKey: 'id', header: 'ID', meta: { class: { th: 'w-12' } } },
  { accessorKey: 'name', header: 'Name' },
  {
    accessorKey: 'createdAt',
    header: 'Created',
    cell: ({ row }) => new Date(row.getValue('createdAt')).toLocaleString(),
  },
  {
    accessorKey: 'updatedAt',
    header: 'Updated',
    cell: ({ row }) => new Date(row.getValue('updatedAt')).toLocaleString(),
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
  <UDashboardPanel id="users">
    <template #header>
      <UDashboardNavbar title="Users">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UButton icon="i-lucide-plus" to="/users/new">New User</UButton>
        </template>
      </UDashboardNavbar>
    </template>
    <template #body>
      <UTable
        :data="users ?? []"
      :columns="columns"
      :loading="status === 'pending'"
      class="flex-1"
    />
    </template>
  </UDashboardPanel>
</template>
