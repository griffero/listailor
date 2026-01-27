<script setup>
import { ref, computed } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  applications: Array,
  jobs: Array,
  stages: Array,
  filters: Object,
  currentUser: Object
})

const searchQuery = ref(props.filters.query || '')
const selectedJob = ref(props.filters.jobId || '')
const selectedStage = ref(props.filters.stageId || '')

function applyFilters() {
  router.get('/app/applications', {
    q: searchQuery.value || undefined,
    job_id: selectedJob.value || undefined,
    stage_id: selectedStage.value || undefined
  }, {
    preserveState: true,
    preserveScroll: true
  })
}

function clearFilters() {
  searchQuery.value = ''
  selectedJob.value = ''
  selectedStage.value = ''
  router.get('/app/applications')
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Applications</h1>
          <p class="text-gray-600">All applications across jobs</p>
        </div>
        <Link 
          href="/app/applications/new"
          class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
        >
          Add Application
        </Link>
      </div>

      <!-- Filters -->
      <div class="bg-white rounded-lg shadow p-4">
        <div class="flex flex-wrap gap-4 items-end">
          <div class="flex-1 min-w-[200px]">
            <label class="block text-sm font-medium text-gray-700 mb-1">Search</label>
            <input 
              v-model="searchQuery"
              type="text"
              placeholder="Name or email..."
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              @keyup.enter="applyFilters"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Job</label>
            <select 
              v-model="selectedJob"
              class="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              @change="applyFilters"
            >
              <option value="">All Jobs</option>
              <option v-for="job in jobs" :key="job.id" :value="job.id">{{ job.title }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Stage</label>
            <select 
              v-model="selectedStage"
              class="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              @change="applyFilters"
            >
              <option value="">All Stages</option>
              <option v-for="stage in stages" :key="stage.id" :value="stage.id">{{ stage.name }}</option>
            </select>
          </div>
          <button 
            @click="applyFilters"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Search
          </button>
          <button 
            @click="clearFilters"
            class="px-4 py-2 text-gray-600 hover:text-gray-900"
          >
            Clear
          </button>
        </div>
      </div>

      <!-- Applications Table -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Candidate</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Job</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">University</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stage</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="app in applications" :key="app.id" class="hover:bg-gray-50">
              <td class="px-6 py-4">
                <Link :href="`/app/applications/${app.id}`" class="block">
                  <div class="font-medium text-gray-900 hover:text-indigo-600">{{ app.candidate.name }}</div>
                  <div class="text-sm text-gray-500">{{ app.candidate.email }}</div>
                </Link>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">
                <Link :href="`/app/jobs/${app.job.id}`" class="hover:text-indigo-600">
                  {{ app.job.title }}
                </Link>
              </td>
              <td class="px-6 py-4 text-sm text-gray-600">
                <span v-if="app.university">{{ app.university }}</span>
                <span v-else class="text-gray-400">—</span>
              </td>
              <td class="px-6 py-4">
                <span 
                  v-if="app.stage"
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': app.stage.kind === 'hired',
                    'bg-red-100 text-red-800': app.stage.kind === 'rejected',
                    'bg-gray-100 text-gray-800': app.stage.kind === 'active'
                  }"
                >
                  {{ app.stage.name }}
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ formatDate(app.createdAt) }}</td>
            </tr>
            <tr v-if="applications.length === 0">
              <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                No applications found
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AppLayout>
</template>

<script>
export default {
  methods: {
    formatDate(dateStr) {
      return new Date(dateStr).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  }
}
</script>
