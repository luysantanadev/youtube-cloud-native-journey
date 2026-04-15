<script setup lang="ts">
definePageMeta({ title: 'New Todo' })

const router = useRouter()
const toast = useToast()
const errorMsg = ref('')

const form = reactive({
  name: '',
  description: '',
  finishedAt: '',
  userId: '' as string | number,
  categoryId: '' as string | number,
})

const [{ data: users }, { data: categories }] = await Promise.all([
  useFetch('/api/users'),
  useFetch('/api/categories'),
])

const userOptions = computed(() => (users.value ?? []).map(u => ({ label: u.name, value: u.id })))
const categoryOptions = computed(() => (categories.value ?? []).map(c => ({ label: c.name, value: c.id })))

async function submit() {
  errorMsg.value = ''
  try {
    await $fetch('/api/todos', {
      method: 'POST',
      body: {
        name: form.name,
        description: form.description || null,
        finishedAt: form.finishedAt || null,
        userId: Number(form.userId),
        categoryId: Number(form.categoryId),
      },
    })
    toast.add({ title: 'Todo created', icon: 'i-lucide-circle-check', color: 'success' })
    await router.push('/todos')
  } catch (err: any) {
    errorMsg.value = err?.data?.statusMessage ?? 'An error occurred'
  }
}
</script>

<template>
  <UDashboardPanel id="todos-new">
    <template #header>
      <UDashboardNavbar title="New Todo">
        <template #leading>
          <UDashboardSidebarCollapse />
          <UButton icon="i-lucide-arrow-left" color="neutral" variant="ghost" to="/todos" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="p-6 max-w-xl">
        <form class="space-y-5" @submit.prevent="submit">
          <UFormField label="Name" required>
            <UInput v-model="form.name" placeholder="Enter a todo name" class="w-full" required />
          </UFormField>

          <UFormField label="Description">
            <UTextarea v-model="form.description" placeholder="Optional description" :rows="3" class="w-full" />
          </UFormField>

          <UFormField label="Assigned to" required>
            <USelect
              v-model="form.userId"
              :items="userOptions"
              value-key="value"
              label-key="label"
              placeholder="Select a user"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Category" required>
            <USelect
              v-model="form.categoryId"
              :items="categoryOptions"
              value-key="value"
              label-key="label"
              placeholder="Select a category"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Finish date">
            <UInput v-model="form.finishedAt" type="datetime-local" class="w-full" />
          </UFormField>

          <UAlert
            v-if="errorMsg"
            color="error"
            variant="soft"
            :title="errorMsg"
            icon="i-lucide-circle-x"
          />

          <div class="flex gap-3">
            <UButton color="neutral" variant="outline" to="/todos">Cancel</UButton>
            <UButton type="submit" icon="i-lucide-plus">Create</UButton>
          </div>
        </form>
      </div>
    </template>
  </UDashboardPanel>
</template>
