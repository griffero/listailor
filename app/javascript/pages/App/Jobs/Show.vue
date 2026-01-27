<script setup>
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiBadge, UiButton, UiEmptyState } from '@/components/ui'

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

function getInitials(name) {
  return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <Link href="/app/jobs" class="inline-flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 mb-3 transition-colors">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Back to Jobs
          </Link>
          <h1 class="text-2xl font-semibold text-zinc-900">{{ job.title }}</h1>
          <div class="flex items-center gap-3 mt-2">
            <UiBadge v-if="job.department" variant="outline" size="sm">{{ job.department }}</UiBadge>
            <UiBadge v-if="job.location" variant="outline" size="sm">{{ job.location }}</UiBadge>
          </div>
        </div>
        <div class="flex gap-2">
          <UiButton 
            @click="togglePublish"
            :variant="job.published ? 'secondary' : 'success'"
          >
            {{ job.published ? 'Unpublish' : 'Publish' }}
          </UiButton>
          <UiButton :href="`/app/jobs/${job.id}/edit`">
            Edit
          </UiButton>
          <UiButton @click="archiveJob" variant="danger">
            Archive
          </UiButton>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Description -->
          <UiCard>
            <h2 class="text-base font-semibold text-zinc-900 mb-4">Description</h2>
            <div
              class="prose prose-sm max-w-none text-zinc-700 prose-p:my-4 prose-ul:my-5 prose-ol:my-5 prose-li:my-1.5 prose-headings:mt-8 prose-headings:mb-3"
              v-html="job.description"
            ></div>
          </UiCard>

          <!-- Questions -->
          <UiCard>
            <h2 class="text-base font-semibold text-zinc-900 mb-4">Application Questions</h2>
            <div v-if="questions.length > 0" class="space-y-2">
              <div v-for="q in questions" :key="q.id" class="flex items-center justify-between p-3 bg-zinc-50 rounded-lg">
                <div class="flex items-center gap-2">
                  <span class="font-medium text-zinc-900">{{ q.label }}</span>
                  <UiBadge v-if="q.required" variant="danger" size="sm">Required</UiBadge>
                  <UiBadge variant="outline" size="sm">{{ q.kind }}</UiBadge>
                </div>
              </div>
            </div>
            <div v-else class="text-zinc-500 text-sm">No custom questions</div>
          </UiCard>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Status -->
          <UiCard>
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Status</h3>
            <div class="space-y-3 text-sm">
              <div class="flex justify-between items-center">
                <span class="text-zinc-500">Status</span>
                <UiBadge :variant="job.published ? 'success' : 'default'" size="sm" dot>
                  {{ job.published ? 'Published' : 'Draft' }}
                </UiBadge>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-zinc-500">Applications</span>
                <span class="font-mono text-zinc-900">{{ job.applicationsCount }}</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-zinc-500">Slug</span>
                <span class="font-mono text-xs text-zinc-600">{{ job.slug }}</span>
              </div>
            </div>
          </UiCard>

          <!-- Embed URL -->
          <UiCard>
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Embed URL</h3>
            <div class="bg-zinc-900 rounded-lg p-3 font-mono text-xs text-zinc-300 break-all">
              /embed/jobs/{{ job.slug }}
            </div>
          </UiCard>
        </div>
      </div>

      <!-- Recent Applications -->
      <UiCard padding="none">
        <div class="px-6 py-4 border-b border-zinc-100">
          <h2 class="text-base font-semibold text-zinc-900">Recent Applications</h2>
        </div>
        <div class="divide-y divide-zinc-100">
          <Link 
            v-for="app in applications" 
            :key="app.id"
            :href="`/app/applications/${app.id}`"
            class="flex items-center justify-between px-6 py-4 hover:bg-zinc-50 transition-colors"
          >
            <div class="flex items-center gap-3">
              <div class="w-9 h-9 bg-zinc-100 rounded-full flex items-center justify-center">
                <span class="text-xs font-medium text-zinc-600">{{ getInitials(app.candidate.name) }}</span>
              </div>
              <div>
                <div class="font-medium text-zinc-900">{{ app.candidate.name }}</div>
                <div class="text-sm text-zinc-500 font-mono">{{ app.candidate.email }}</div>
              </div>
            </div>
            <UiBadge 
              v-if="app.stage"
              :variant="app.stage.kind === 'hired' ? 'success' : app.stage.kind === 'rejected' ? 'danger' : 'default'"
              size="sm"
            >
              {{ app.stage.name }}
            </UiBadge>
          </Link>
          <div v-if="applications.length === 0" class="px-6 py-12 text-center text-zinc-500 text-sm">
            No applications yet
          </div>
        </div>
      </UiCard>
    </div>
  </AppLayout>
</template>
