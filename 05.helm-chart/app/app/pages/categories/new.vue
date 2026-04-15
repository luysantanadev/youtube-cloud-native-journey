<script setup lang="ts">
definePageMeta({ title: 'New Category' })

const name = ref('')
const errorMsg = ref('')
const router = useRouter()
const toast = useToast()

async function submit() {
  errorMsg.value = ''
  try {
    await $fetch('/api/categories', {
      method: 'POST',
      body: { name: name.value },
    })
    toast.add({ title: 'Category created', icon: 'i-lucide-circle-check', color: 'success' })
    await router.push('/categories')
  } catch (err: any) {
    errorMsg.value = err?.data?.statusMessage ?? 'An error occurred'
  }
}
</script>

<template>
  <UDashboardPanel id="categories-new">
    <template #header>
      <UDashboardNavbar title="New Category">
        <template #leading>
          <UDashboardSidebarCollapse />
          <UButton icon="i-lucide-arrow-left" color="neutral" variant="ghost" to="/categories" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="p-6 max-w-md">
        <form class="space-y-5" @submit.prevent="submit">
          <UFormField label="Name" required>
            <UInput v-model="name" placeholder="Enter a category name" class="w-full" required />
          </UFormField>

          <UAlert
            v-if="errorMsg"
            color="error"
            variant="soft"
            :title="errorMsg"
            icon="i-lucide-circle-x"
          />

          <div class="flex gap-3">
            <UButton color="neutral" variant="outline" to="/categories">Cancel</UButton>
            <UButton type="submit" icon="i-lucide-plus">Create</UButton>
          </div>
        </form>
      </div>
    </template>
  </UDashboardPanel>
</template>
