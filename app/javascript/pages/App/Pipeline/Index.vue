<script setup>
import { ref, watch, computed } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiBadge, UiButton, UiSelect, UiEmptyState } from '@/components/ui'
import draggable from 'vuedraggable'

const props = defineProps({
  stages: Array,
  jobs: Array,
  selectedJobId: String,
  currentUser: Object
})

const selectedJob = ref(props.selectedJobId || '')
const selectedCountry = ref('cl')

// Reset job selection when country changes
watch(selectedCountry, () => {
  selectedJob.value = ''
  filterByJob()
})

// Infer country from job title
function inferCountry(title) {
  const t = title.toLowerCase()
  if (t.includes('méxico') || t.includes('mexico') || t.includes('méx') || t.includes('mex ') || t.includes(' mx') || t.includes('cdmx')) {
    return 'mx'
  }
  if (t.includes('chile') || t.includes(' cl')) {
    return 'cl'
  }
  return 'cl'
}

// Infer department from job title
function inferDepartment(title) {
  const t = title.toLowerCase()
  if (t.includes('engineer') || t.includes('developer') || t.includes('devops') || t.includes('frontend') || t.includes('backend') || t.includes('software') || t.includes('security') || t.includes('infrastructure') || t.includes('sre')) return 'Engineering'
  if (t.includes('product manager') || t.includes('product ops') || t.includes('product operations') || t.includes('product designer')) return 'Product'
  if (t.includes('sales') || t.includes('account exec') || t.includes('account manager') || t.includes('key account') || t.includes('bdr') || t.includes('business development')) return 'Sales'
  if (t.includes('people') || t.includes('recruiter') || t.includes('talent') || t.includes('hr ') || t.includes('human resources')) return 'People'
  if (t.includes('marketing') || t.includes('growth') || t.includes('community') || t.includes('events') || t.includes('brand') || t.includes('content')) return 'Marketing'
  if (t.includes('operations') || t.includes('ops ') || t.includes('customer support') || t.includes('customer success') || t.includes('support specialist')) return 'Operations'
  if (t.includes('finance') || t.includes('contador') || t.includes('accountant') || t.includes('financial') || t.includes('payment')) return 'Finance'
  if (t.includes('design') || t.includes('ux') || t.includes('ui')) return 'Design'
  if (t.includes('strategy') || t.includes('chief') || t.includes('head of') || t.includes('director')) return 'Strategy'
  return 'Other'
}

const filteredJobsByCountry = computed(() => {
  if (selectedCountry.value === 'all') return props.jobs
  return props.jobs.filter(job => inferCountry(job.title) === selectedCountry.value)
})

const countByCountry = computed(() => {
  const counts = { cl: 0, mx: 0 }
  for (const job of props.jobs) {
    const country = inferCountry(job.title)
    counts[country] = (counts[country] || 0) + 1
  }
  return counts
})

const totalApplicationCount = computed(() => {
  return filteredJobsByCountry.value.reduce((sum, job) => sum + (job.applicationCount || 0), 0)
})

const groupedJobs = computed(() => {
  const groups = {}
  const departmentOrder = ['Engineering', 'Product', 'Design', 'Sales', 'Marketing', 'Operations', 'People', 'Finance', 'Strategy', 'Other']
  
  for (const job of filteredJobsByCountry.value) {
    const dept = job.department || inferDepartment(job.title)
    if (!groups[dept]) groups[dept] = []
    groups[dept].push(job)
  }
  
  const sortedGroups = {}
  for (const dept of departmentOrder) {
    if (groups[dept] && groups[dept].length > 0) {
      sortedGroups[dept] = groups[dept]
    }
  }
  for (const dept of Object.keys(groups)) {
    if (!sortedGroups[dept]) sortedGroups[dept] = groups[dept]
  }
  
  return sortedGroups
})

function onDragEnd(targetStageId, event) {
  const appId = event.item.dataset.appId
  if (!appId || !targetStageId) return
  
  router.post(`/app/applications/${appId}/move_stage`, {
    stage_id: targetStageId
  }, {
    preserveScroll: true
  })
}

function getStageStyles(kind) {
  if (kind === 'hired') return 'border-emerald-200 bg-emerald-50/50'
  if (kind === 'rejected') return 'border-red-200 bg-red-50/50'
  return 'border-zinc-200 bg-zinc-50/50'
}

function getStageHeaderStyles(kind) {
  if (kind === 'hired') return 'text-emerald-700'
  if (kind === 'rejected') return 'text-red-700'
  return 'text-zinc-900'
}

function formatCount(count) {
  if (count > 99) return '99+'
  return String(count)
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric'
  })
}

function filterByJob() {
  const params = selectedJob.value ? { job_id: selectedJob.value } : {}
  router.get('/app/pipeline', params, {
    preserveState: true,
    preserveScroll: true
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
        title="Pipeline" 
        :description="selectedJob ? jobs.find(j => j.id == selectedJob)?.title : 'Select a job to view its pipeline'"
      >
        <template #actions>
          <UiButton href="/app/applications/new">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Application
          </UiButton>
        </template>
      </UiPageHeader>

      <!-- Job Selector -->
      <UiCard>
        <div class="space-y-4">
          <!-- Country Tabs -->
          <div class="flex gap-2">
            <button
              @click="selectedCountry = 'cl'"
              :class="[
                'px-4 py-2 rounded-lg font-medium text-sm transition-all',
                selectedCountry === 'cl' 
                  ? 'bg-zinc-900 text-white' 
                  : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
              ]"
            >
              🇨🇱 Chile <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.cl }})</span>
            </button>
            <button
              @click="selectedCountry = 'mx'"
              :class="[
                'px-4 py-2 rounded-lg font-medium text-sm transition-all',
                selectedCountry === 'mx' 
                  ? 'bg-zinc-900 text-white' 
                  : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
              ]"
            >
              🇲🇽 México <span class="ml-1 font-mono text-xs opacity-75">({{ countByCountry.mx }})</span>
            </button>
            <button
              @click="selectedCountry = 'all'"
              :class="[
                'px-4 py-2 rounded-lg font-medium text-sm transition-all',
                selectedCountry === 'all' 
                  ? 'bg-zinc-900 text-white' 
                  : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
              ]"
            >
              Todos <span class="ml-1 font-mono text-xs opacity-75">({{ jobs.length }})</span>
            </button>
          </div>

          <!-- Job Dropdown -->
          <div class="flex items-center gap-3">
            <label class="text-sm font-medium text-zinc-700 whitespace-nowrap">Seleccionar rol:</label>
            <select
              v-model="selectedJob"
              @change="filterByJob"
              class="flex-1 px-3 py-2 text-sm border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-900 transition-colors"
            >
              <option value="">Todos los roles ({{ totalApplicationCount }})</option>
              <optgroup v-for="(jobsList, dept) in groupedJobs" :key="dept" :label="dept">
                <option v-for="job in jobsList" :key="job.id" :value="job.id">
                  {{ job.title }} ({{ job.applicationCount }})
                </option>
              </optgroup>
            </select>
          </div>
        </div>
      </UiCard>

      <!-- Empty State -->
      <UiCard v-if="stages.length === 0" class="py-12">
        <UiEmptyState 
          title="No stages found"
          description="Select a different job or sync Teamtailor data"
          icon="inbox"
        />
      </UiCard>

      <!-- Pipeline Board -->
      <div v-else class="flex gap-4 overflow-x-auto pb-4 -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8">
        <div 
          v-for="stage in stages" 
          :key="stage.canonical"
          class="flex-shrink-0 w-72"
        >
          <div 
            :class="[
              'rounded-xl border-2 h-full flex flex-col',
              getStageStyles(stage.kind)
            ]"
          >
            <!-- Stage Header -->
            <div class="p-3 border-b border-zinc-200/50">
              <div class="flex justify-between items-center">
                <h3 :class="['font-semibold text-sm', getStageHeaderStyles(stage.kind)]">
                  {{ stage.name }}
                </h3>
                <span class="px-2 py-0.5 bg-white/80 rounded-full text-xs font-mono text-zinc-500">
                  {{ formatCount(stage.applicationCount || 0) }}
                </span>
              </div>
            </div>
            
            <!-- Draggable Cards -->
            <draggable
              :list="stage.applications"
              group="applications"
              item-key="id"
              class="flex-1 p-2 min-h-[200px] space-y-2"
              @end="(e) => onDragEnd(stage.targetStageId, e)"
            >
              <template #item="{ element: app }">
                <div 
                  :data-app-id="app.id"
                  class="bg-white rounded-lg p-3 cursor-grab active:cursor-grabbing border border-zinc-200 hover:border-zinc-300 hover:shadow-sm transition-all group"
                >
                  <Link :href="`/app/applications/${app.id}`" class="block">
                    <div class="flex items-start gap-3">
                      <div class="w-8 h-8 bg-zinc-100 rounded-full flex items-center justify-center flex-shrink-0 group-hover:bg-zinc-200 transition-colors">
                        <span class="text-xs font-medium text-zinc-600">{{ getInitials(app.candidate.name) }}</span>
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="font-medium text-zinc-900 text-sm truncate">{{ app.candidate.name }}</div>
                        <div v-if="app.stageName" class="text-xs text-zinc-500 mt-0.5">{{ app.stageName }}</div>
                        <div class="text-xs text-zinc-400 font-mono mt-1">{{ formatDate(app.createdAt) }}</div>
                      </div>
                    </div>
                  </Link>
                </div>
              </template>
            </draggable>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.sortable-ghost {
  opacity: 0.4;
}

.sortable-chosen {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}
</style>
