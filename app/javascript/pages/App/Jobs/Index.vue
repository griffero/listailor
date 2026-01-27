<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiPageHeader, UiBadge, UiButton, UiTable, UiEmptyState } from '@/components/ui'

defineProps({
  jobs: Array,
  currentUser: Object
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <UiPageHeader 
        title="Job Postings" 
        description="Manage your job postings"
      >
        <template #actions>
          <UiButton href="/app/jobs/new">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Job
          </UiButton>
        </template>
      </UiPageHeader>

      <UiTable>
        <template #header>
          <tr>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Job</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Department</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Location</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Status</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Applications</th>
            <th class="px-6 py-3 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wider">Actions</th>
          </tr>
        </template>
        
        <tr v-for="job in jobs" :key="job.id" class="group">
          <td class="px-6 py-4">
            <Link :href="`/app/jobs/${job.id}`" class="block">
              <div class="font-medium text-zinc-900 group-hover:text-zinc-600 transition-colors">{{ job.title }}</div>
              <div class="text-xs text-zinc-400 font-mono mt-0.5">/embed/jobs/{{ job.slug }}</div>
            </Link>
          </td>
          <td class="px-6 py-4">
            <span v-if="job.department" class="text-sm text-zinc-600">{{ job.department }}</span>
            <span v-else class="text-sm text-zinc-300">—</span>
          </td>
          <td class="px-6 py-4">
            <span v-if="job.location" class="text-sm text-zinc-600">{{ job.location }}</span>
            <span v-else class="text-sm text-zinc-300">—</span>
          </td>
          <td class="px-6 py-4">
            <UiBadge 
              :variant="job.published ? 'success' : 'default'"
              size="sm"
              dot
            >
              {{ job.published ? 'Published' : 'Draft' }}
            </UiBadge>
          </td>
          <td class="px-6 py-4">
            <span class="text-sm text-zinc-600 font-mono">{{ job.applicationsCount }}</span>
          </td>
          <td class="px-6 py-4 text-right">
            <UiButton :href="`/app/jobs/${job.id}/edit`" variant="ghost" size="sm">
              Edit
            </UiButton>
          </td>
        </tr>
        
        <tr v-if="jobs.length === 0">
          <td colspan="6">
            <UiEmptyState 
              title="No job postings yet"
              description="Create your first job posting"
              icon="document"
            >
              <template #action>
                <UiButton href="/app/jobs/new" size="sm">
                  Create Job
                </UiButton>
              </template>
            </UiEmptyState>
          </td>
        </tr>
      </UiTable>
    </div>
  </AppLayout>
</template>
