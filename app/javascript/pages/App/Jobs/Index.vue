<script setup>
import { ref, computed } from 'vue'
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiPageHeader, UiBadge, UiButton, UiTable, UiEmptyState } from '@/components/ui'

const props = defineProps({
  jobs: Array,
  currentUser: Object
})

const selectedCountry = ref('all')

function inferCountry(title) {
  if (!title) return 'cl'
  const lower = title.toLowerCase()
  if (lower.includes('méxico') || lower.includes('mexico')) return 'mx'
  if (lower.includes('colombia')) return 'co'
  if (lower.includes('perú') || lower.includes('peru')) return 'pe'
  if (lower.includes('argentina')) return 'ar'
  return 'cl'
}

const filteredJobs = computed(() => {
  if (selectedCountry.value === 'all') return props.jobs
  return props.jobs.filter(job => inferCountry(job.title) === selectedCountry.value)
})

const countByCountry = computed(() => {
  const counts = { cl: 0, mx: 0, co: 0, pe: 0, ar: 0 }
  for (const job of props.jobs) {
    const country = inferCountry(job.title)
    counts[country] = (counts[country] || 0) + 1
  }
  return counts
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <UiPageHeader 
        title="Job Postings" 
        description="Manage your job postings"
      >
        <template #actions v-if="currentUser?.canWrite">
          <UiButton href="/app/jobs/new">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Job
          </UiButton>
        </template>
      </UiPageHeader>

      <!-- Country Tabs -->
      <div class="flex items-center gap-2">
        <button
          @click="selectedCountry = 'all'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'all' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🌎 All <span class="ml-1 font-mono text-xs opacity-75">({{ jobs.length }})</span>
        </button>
        <button
          @click="selectedCountry = 'cl'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'cl' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🇨🇱 Chile <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.cl }})</span>
        </button>
        <button
          @click="selectedCountry = 'mx'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'mx' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🇲🇽 México <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.mx }})</span>
        </button>
        <button
          v-if="countByCountry.co > 0"
          @click="selectedCountry = 'co'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'co' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🇨🇴 Colombia <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.co }})</span>
        </button>
        <button
          v-if="countByCountry.pe > 0"
          @click="selectedCountry = 'pe'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'pe' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🇵🇪 Perú <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.pe }})</span>
        </button>
        <button
          v-if="countByCountry.ar > 0"
          @click="selectedCountry = 'ar'"
          class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
          :class="selectedCountry === 'ar' 
            ? 'bg-zinc-900 text-white' 
            : 'text-zinc-600 hover:bg-zinc-100'"
        >
          🇦🇷 Argentina <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.ar }})</span>
        </button>
      </div>

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
        
        <tr v-for="job in filteredJobs" :key="job.id" class="group">
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
            <UiButton v-if="currentUser?.canWrite" :href="`/app/jobs/${job.id}/edit`" variant="ghost" size="sm">
              Edit
            </UiButton>
          </td>
        </tr>
        
        <tr v-if="filteredJobs.length === 0">
          <td colspan="6">
            <UiEmptyState 
              :title="selectedCountry === 'all' ? 'No job postings yet' : 'No jobs in this country'"
              :description="selectedCountry === 'all' ? 'Create your first job posting' : 'Try selecting a different country'"
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
