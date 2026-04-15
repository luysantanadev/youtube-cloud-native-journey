<script setup lang="ts">
definePageMeta({ title: 'Edit User' })

const route = useRoute()
const id = Number(route.params.id)
const router = useRouter()
const toast = useToast()
const errorMsg = ref('')

const { data: user } = await useFetch(`/api/users/${id}`)

const name = ref(user.value?.name ?? '')

async function submit() {
  errorMsg.value = ''
  try {
    await $fetch(`/api/users/${id}`, {
      method: 'PUT',
      body: { name: name.value },
    })
    toast.add({ title: 'User updated', icon: 'i-lucide-circle-check', color: 'success' })
    await router.push('/users')
  } catch (err: any) {
    errorMsg.value = err?.data?.statusMessage ?? 'An error occurred'
  }
}
</script>

<template>
  <UDashboardPanel :id="`users-edit-${id}`">
    <template #header>
      <UDashboardNavbar :title="`Edit User #${id}`">
        <template #leading>
          <UDashboardSidebarCollapse />
          <UButton icon="i-lucide-arrow-left" color="neutral" variant="ghost" to="/users" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="p-6 max-w-md">
        <form class="space-y-5" @submit.prevent="submit">
          <UFormField label="Name" required>
            <UInput v-model="name" placeholder="Enter a username" class="w-full" required />
          </UFormField>

          <UAlert
            v-if="errorMsg"
            color="error"
            variant="soft"
            :title="errorMsg"
            icon="i-lucide-circle-x"
          />

          <div class="flex gap-3">
            <UButton color="neutral" variant="outline" to="/users">Cancel</UButton>
            <UButton type="submit" icon="i-lucide-save">Save</UButton>
          </div>
        </form>
      </div>
    </template>
  </UDashboardPanel>
</template>
