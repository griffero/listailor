<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiBadge, UiButton, UiInput, UiSelect, UiMultiSelect, UiTable, UiEmptyState } from '@/components/ui'

const props = defineProps({
  applications: Array,
  jobs: Array,
  canonicalStages: Array,
  insightOptions: Array,
  filters: Object,
  currentUser: Object
})

const searchQuery = ref(props.filters.query || '')
const selectedJob = ref(props.filters.jobId || '')
const selectedStage = ref(props.filters.canonicalStage || '')
const selectedInsights = ref(props.filters.insights || [])

function applyFilters() {
  router.get('/app/applications', {
    q: searchQuery.value || undefined,
    job_id: selectedJob.value || undefined,
    canonical_stage: selectedStage.value || undefined,
    insights: selectedInsights.value.length > 0 ? selectedInsights.value : undefined
  }, {
    preserveState: true,
    preserveScroll: true
  })
}

function clearFilters() {
  searchQuery.value = ''
  selectedJob.value = ''
  selectedStage.value = ''
  selectedInsights.value = []
  router.get('/app/applications')
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

function getInitials(name) {
  return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <UiPageHeader 
        title="Applications" 
        description="All applications across jobs"
      >
        <template #actions v-if="currentUser?.canWrite">
          <UiButton href="/app/applications/new">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Application
          </UiButton>
        </template>
      </UiPageHeader>

      <!-- Filters -->
      <UiCard>
        <div class="flex flex-wrap gap-4 items-end">
          <div class="flex-1 min-w-[200px]">
            <UiInput 
              v-model="searchQuery"
              label="Search"
              placeholder="Name or email..."
              @keyup.enter="applyFilters"
            >
              <template #icon>
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </template>
            </UiInput>
          </div>
          <div class="w-48">
            <UiSelect v-model="selectedJob" label="Job" @change="applyFilters">
              <option value="">All Jobs</option>
              <option v-for="job in jobs" :key="job.id" :value="job.id">{{ job.title }}</option>
            </UiSelect>
          </div>
          <div class="w-48">
            <UiSelect v-model="selectedStage" label="Stage" @change="applyFilters">
              <option value="">All Stages</option>
              <option v-for="stage in canonicalStages" :key="stage.value" :value="stage.value">
                {{ stage.label }} ({{ stage.count }})
              </option>
            </UiSelect>
          </div>
          <div class="w-56">
            <UiMultiSelect 
              v-model="selectedInsights" 
              :options="insightOptions"
              label="Insights"
              placeholder="All Insights"
              @change="applyFilters"
            />
          </div>
          <div class="flex gap-2">
            <UiButton @click="applyFilters">Search</UiButton>
            <UiButton @click="clearFilters" variant="ghost">Clear</UiButton>
          </div>
        </div>
      </UiCard>

      <!-- Applications Table -->
      <UiTable>
        <template #header>
          <tr>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Candidate</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Job</th>
            <th class="px-3 py-3 text-center text-xs font-semibold text-zinc-500 uppercase tracking-wider w-12">País</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">University</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Insights</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Stage</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Date</th>
          </tr>
        </template>
        
        <tr v-for="app in applications" :key="app.id" class="group">
          <td class="px-6 py-4">
            <Link :href="`/app/applications/${app.id}`" class="flex items-center gap-3">
              <div class="w-9 h-9 bg-zinc-100 rounded-full flex items-center justify-center flex-shrink-0 group-hover:bg-zinc-200 transition-colors">
                <span class="text-xs font-medium text-zinc-600">{{ getInitials(app.candidate.name) }}</span>
              </div>
              <div>
                <div class="font-medium text-zinc-900 group-hover:text-zinc-600 transition-colors">{{ app.candidate.name }}</div>
                <div class="text-sm text-zinc-500 font-mono">{{ app.candidate.email }}</div>
              </div>
            </Link>
          </td>
          <td class="px-6 py-4">
            <Link :href="`/app/jobs/${app.job.id}`" class="text-sm text-zinc-600 hover:text-zinc-900 transition-colors">
              {{ app.job.title }}
            </Link>
          </td>
          <td class="px-3 py-4 text-center text-lg">
            {{ app.countryFlag }}
          </td>
          <td class="px-6 py-4">
            <span v-if="app.university" class="text-sm text-zinc-600">{{ app.university }}</span>
            <span v-else class="text-sm text-zinc-300">—</span>
          </td>
          <td class="px-6 py-4">
            <div class="flex items-center gap-1">
              <span 
                v-if="app.hasStartupExperience" 
                class="group/startup relative inline-flex items-center justify-center w-6 h-6 rounded bg-violet-100 text-violet-600"
                title="Top Startup LATAM/USA/EU"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </span>
              <span 
                v-if="app.hasYearTenure" 
                class="group/tenure relative inline-flex items-center justify-center w-6 h-6 rounded bg-emerald-100 text-emerald-600"
                title="+2 años en algún rol"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </span>
              <span 
                v-if="app.hasPersonalProjects" 
                class="group/projects relative inline-flex items-center justify-center w-6 h-6 rounded bg-amber-100 text-amber-600"
                title="Proyectos propios"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              </span>
              <span 
                v-if="app.coverLetterDecision === 'advance'" 
                class="inline-flex items-center justify-center w-6 h-6 rounded bg-emerald-100 text-emerald-600"
                title="Cover Letter: Advance"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </span>
              <span 
                v-if="app.coverLetterDecision === 'reject'" 
                class="inline-flex items-center justify-center w-6 h-6 rounded bg-red-100 text-red-600"
                title="Cover Letter: Reject"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </span>
              <span v-if="!app.hasStartupExperience && !app.hasYearTenure && !app.hasPersonalProjects && !app.coverLetterDecision" class="text-zinc-300">—</span>
            </div>
          </td>
          <td class="px-6 py-4">
            <UiBadge 
              v-if="app.stage"
              :variant="app.stage.kind === 'hired' ? 'success' : app.stage.kind === 'rejected' ? 'danger' : 'default'"
              size="sm"
            >
              {{ app.stage.name }}
            </UiBadge>
          </td>
          <td class="px-6 py-4 text-sm text-zinc-500 font-mono">{{ formatDate(app.createdAt) }}</td>
        </tr>
        
        <tr v-if="applications.length === 0">
          <td colspan="7">
            <UiEmptyState 
              title="No applications found"
              description="Try adjusting your filters or add a new application"
              icon="users"
            >
              <template #action>
                <UiButton href="/app/applications/new" size="sm">
                  Add Application
                </UiButton>
              </template>
            </UiEmptyState>
          </td>
        </tr>
      </UiTable>
    </div>
  </AppLayout>
</template>
