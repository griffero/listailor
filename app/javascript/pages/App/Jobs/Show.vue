<script setup>
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  job: Object,
  questions: Array,
  applications: Array,
  currentUser: Object
})

function togglePublish() {
  const url = props.job.published 
    ? `/app/jobs/${props.job.id}/unpublish`
    : `/app/jobs/${props.job.id}/publish`
  router.post(url)
}

function archiveJob() {
  if (confirm('Are you sure you want to archive this job? It will be unpublished and hidden from the list.')) {
    router.post(`/app/jobs/${props.job.id}/archive`)
  }
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-start">
        <div>
          <Link href="/app/jobs" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
            ← Back to Jobs
          </Link>
          <h1 class="text-2xl font-bold text-gray-900">{{ job.title }}</h1>
          <div class="flex items-center gap-4 mt-2 text-sm text-gray-600">
            <span v-if="job.department">{{ job.department }}</span>
            <span v-if="job.location">{{ job.location }}</span>
          </div>
        </div>
        <div class="flex gap-2">
          <button 
            @click="togglePublish"
            class="px-4 py-2 rounded-lg transition"
            :class="job.published 
              ? 'bg-gray-100 text-gray-700 hover:bg-gray-200' 
              : 'bg-green-600 text-white hover:bg-green-700'"
          >
            {{ job.published ? 'Unpublish' : 'Publish' }}
          </button>
          <Link 
            :href="`/app/jobs/${job.id}/edit`"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Edit
          </Link>
          <button 
            @click="archiveJob"
            class="px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition"
          >
            Archive
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Description -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Description</h2>
            <div
              class="prose prose-sm max-w-none text-gray-700 prose-p:my-4 prose-ul:my-5 prose-ol:my-5 prose-li:my-1.5 prose-headings:mt-8 prose-headings:mb-3"
              v-html="job.description"
            ></div>
          </div>

          <!-- Questions -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Application Questions</h2>
            <div v-if="questions.length > 0" class="space-y-3">
              <div v-for="q in questions" :key="q.id" class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <span class="font-medium">{{ q.label }}</span>
                  <span v-if="q.required" class="text-red-500 ml-1">*</span>
                  <span class="text-sm text-gray-500 ml-2">({{ q.kind }})</span>
                </div>
              </div>
            </div>
            <div v-else class="text-gray-500">No custom questions</div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Status -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Status</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span class="text-gray-600">Status</span>
                <span :class="job.published ? 'text-green-600' : 'text-gray-600'">
                  {{ job.published ? 'Published' : 'Draft' }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Applications</span>
                <span class="font-medium">{{ job.applicationsCount }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Slug</span>
                <span class="font-mono text-sm">{{ job.slug }}</span>
              </div>
            </div>
          </div>

          <!-- Embed URL -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Embed URL</h3>
            <code class="text-xs bg-gray-100 p-2 rounded block break-all">/embed/jobs/{{ job.slug }}</code>
          </div>
        </div>
      </div>

      <!-- Recent Applications -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Recent Applications</h2>
        </div>
        <div class="divide-y divide-gray-200">
          <div v-for="app in applications" :key="app.id" class="px-6 py-4 hover:bg-gray-50">
            <Link :href="`/app/applications/${app.id}`" class="flex justify-between items-center">
              <div>
                <div class="font-medium text-gray-900">{{ app.candidate.name }}</div>
                <div class="text-sm text-gray-500">{{ app.candidate.email }}</div>
              </div>
              <div class="flex items-center gap-3">
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
              </div>
            </Link>
          </div>
          <div v-if="applications.length === 0" class="px-6 py-8 text-center text-gray-500">
            No applications yet
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
