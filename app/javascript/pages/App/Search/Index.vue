<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  query: String,
  candidates: Array,
  applications: Array,
  jobs: Array,
  currentUser: Object
})

const searchQuery = ref(props.query || '')

function search() {
  router.get('/app/search', {
    q: searchQuery.value
  }, {
    preserveState: true
  })
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Search</h1>
      </div>

      <!-- Search Box -->
      <div class="bg-white rounded-lg shadow p-4">
        <form @submit.prevent="search" class="flex gap-4">
          <input 
            v-model="searchQuery"
            type="text"
            placeholder="Search candidates, applications, jobs..."
            class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            autofocus
          >
          <button 
            type="submit"
            class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Search
          </button>
        </form>
      </div>

      <div v-if="query" class="space-y-6">
        <!-- Candidates -->
        <div v-if="candidates.length > 0" class="bg-white rounded-lg shadow">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-semibold text-gray-900">Candidates ({{ candidates.length }})</h2>
          </div>
          <div class="divide-y divide-gray-200">
            <div v-for="candidate in candidates" :key="candidate.id" class="px-6 py-4 hover:bg-gray-50">
              <div class="flex justify-between items-center">
                <div>
                  <div class="font-medium text-gray-900">{{ candidate.name }}</div>
                  <div class="text-sm text-gray-500">{{ candidate.email }}</div>
                </div>
                <div class="text-sm text-gray-500">
                  {{ candidate.applicationsCount }} application(s)
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Applications -->
        <div v-if="applications.length > 0" class="bg-white rounded-lg shadow">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-semibold text-gray-900">Applications ({{ applications.length }})</h2>
          </div>
          <div class="divide-y divide-gray-200">
            <div v-for="app in applications" :key="app.id" class="px-6 py-4 hover:bg-gray-50">
              <Link :href="`/app/applications/${app.id}`" class="flex justify-between items-center">
                <div>
                  <div class="font-medium text-gray-900">{{ app.candidate.name }}</div>
                  <div class="text-sm text-gray-500">{{ app.job.title }}</div>
                </div>
                <div class="flex items-center gap-3">
                  <span 
                    v-if="app.stage"
                    class="px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800"
                  >
                    {{ app.stage.name }}
                  </span>
                </div>
              </Link>
            </div>
          </div>
        </div>

        <!-- Jobs -->
        <div v-if="jobs.length > 0" class="bg-white rounded-lg shadow">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-semibold text-gray-900">Jobs ({{ jobs.length }})</h2>
          </div>
          <div class="divide-y divide-gray-200">
            <div v-for="job in jobs" :key="job.id" class="px-6 py-4 hover:bg-gray-50">
              <Link :href="`/app/jobs/${job.id}`" class="flex justify-between items-center">
                <div>
                  <div class="font-medium text-gray-900">{{ job.title }}</div>
                  <div class="text-sm text-gray-500">{{ job.department }}</div>
                </div>
                <span 
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="job.published ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                >
                  {{ job.published ? 'Published' : 'Draft' }}
                </span>
              </Link>
            </div>
          </div>
        </div>

        <!-- No Results -->
        <div v-if="candidates.length === 0 && applications.length === 0 && jobs.length === 0" class="bg-white rounded-lg shadow p-8 text-center">
          <p class="text-gray-500">No results found for "{{ query }}"</p>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
