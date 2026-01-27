<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiButton, UiTable, UiEmptyState } from '@/components/ui'

defineProps({
  templates: Array,
  variables: Array,
  currentUser: Object
})

function formatVariable(v) {
  return `{{${v}}}`
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <UiPageHeader 
        title="Email Templates" 
        description="Manage your email templates"
      >
        <template #actions>
          <UiButton href="/app/email_templates/new">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Template
          </UiButton>
        </template>
      </UiPageHeader>

      <!-- Variables Reference -->
      <UiCard class="bg-zinc-900 border-zinc-800">
        <h3 class="text-sm font-semibold text-white mb-3">Available Variables</h3>
        <div class="flex flex-wrap gap-2">
          <code 
            v-for="v in variables" 
            :key="v" 
            class="px-2 py-1 bg-zinc-800 rounded text-xs text-emerald-400 font-mono"
          >{{ formatVariable(v) }}</code>
        </div>
      </UiCard>

      <UiTable>
        <template #header>
          <tr>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Name</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Subject</th>
            <th class="px-6 py-3 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wider">Actions</th>
          </tr>
        </template>
        
        <tr v-for="template in templates" :key="template.id" class="group">
          <td class="px-6 py-4 font-medium text-zinc-900">{{ template.name }}</td>
          <td class="px-6 py-4 text-sm text-zinc-500">{{ template.subject }}</td>
          <td class="px-6 py-4 text-right">
            <div class="flex items-center justify-end gap-2">
              <UiButton :href="`/app/email_templates/${template.id}/edit`" variant="ghost" size="sm">
                Edit
              </UiButton>
              <Link 
                :href="`/app/email_templates/${template.id}`"
                method="delete"
                as="button"
                class="px-3 py-1.5 text-sm text-red-600 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
                @click="(e) => !confirm('Delete this template?') && e.preventDefault()"
              >
                Delete
              </Link>
            </div>
          </td>
        </tr>
        
        <tr v-if="templates.length === 0">
          <td colspan="3">
            <UiEmptyState 
              title="No templates yet"
              description="Create your first email template"
              icon="document"
            >
              <template #action>
                <UiButton href="/app/email_templates/new" size="sm">
                  Create Template
                </UiButton>
              </template>
            </UiEmptyState>
          </td>
        </tr>
      </UiTable>
    </div>
  </AppLayout>
</template>
