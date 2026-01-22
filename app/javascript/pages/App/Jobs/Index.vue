<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

defineProps({
  jobs: Array,
  currentUser: Object
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Job Postings</h1>
          <p class="text-gray-600">Manage your job postings</p>
        </div>
        <Link 
          href="/app/jobs/new"
          class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
        >
          Create Job
        </Link>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Job</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Department</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Applications</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="job in jobs" :key="job.id" class="hover:bg-gray-50">
              <td class="px-6 py-4">
                <Link :href="`/app/jobs/${job.id}`" class="font-medium text-gray-900 hover:text-indigo-600">
                  {{ job.title }}
                </Link>
                <div class="text-sm text-gray-500">/embed/jobs/{{ job.slug }}</div>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ job.department || '—' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ job.location || '—' }}</td>
              <td class="px-6 py-4">
                <span 
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="job.published ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                >
                  {{ job.published ? 'Published' : 'Draft' }}
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ job.applicationsCount }}</td>
              <td class="px-6 py-4 text-right">
                <Link :href="`/app/jobs/${job.id}/edit`" class="text-indigo-600 hover:text-indigo-800 text-sm">
                  Edit
                </Link>
              </td>
            </tr>
            <tr v-if="jobs.length === 0">
              <td colspan="6" class="px-6 py-8 text-center text-gray-500">
                No job postings yet. Create your first one!
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AppLayout>
</template>
