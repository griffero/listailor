<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiStatCard, UiPageHeader, UiBadge, UiButton, UiTable } from '@/components/ui'

defineProps({
  recentApplications: Array,
  canonicalStages: Array,
  stats: Object,
  syncStats: Object,
  currentUser: Object
})

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

function formatNumber(num) {
  return num?.toLocaleString() || '0'
}

function getSyncVariant(pct) {
  if (pct >= 80) return 'success'
  if (pct >= 50) return 'warning'
  return 'danger'
}

function getInitials(name) {
  return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-8">
      <!-- Header -->
      <UiPageHeader 
        title="Dashboard" 
        description="Overview of your hiring pipeline"
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

      <!-- Top Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <UiCard class="relative overflow-hidden">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm font-medium text-zinc-500">Total Applications</p>
              <p class="text-3xl font-bold text-zinc-900 mt-1 font-mono tracking-tight">
                {{ formatNumber(stats.totalApplications) }}
              </p>
            </div>
            <div class="w-10 h-10 bg-zinc-100 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
          </div>
          <div class="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-zinc-200 to-zinc-300"></div>
        </UiCard>

        <UiCard class="relative overflow-hidden">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm font-medium text-zinc-500">Active Jobs</p>
              <p class="text-3xl font-bold text-zinc-900 mt-1 font-mono tracking-tight">
                {{ formatNumber(stats.totalJobs) }}
              </p>
            </div>
            <div class="w-10 h-10 bg-emerald-50 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
          </div>
          <div class="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-emerald-200 to-emerald-300"></div>
        </UiCard>

        <UiCard class="relative overflow-hidden">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm font-medium text-zinc-500">This Week</p>
              <p class="text-3xl font-bold text-zinc-900 mt-1 font-mono tracking-tight">
                {{ formatNumber(stats.thisWeekApplications) }}
              </p>
            </div>
            <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
            </div>
          </div>
          <div class="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-200 to-blue-300"></div>
        </UiCard>
      </div>

      <!-- TeamTailor Sync Overview -->
      <UiCard padding="none">
        <div class="px-6 py-4 border-b border-zinc-100">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-semibold text-zinc-900">TeamTailor Sync Overview</h2>
              <p class="text-sm text-zinc-500 mt-0.5">Data extraction and sync status</p>
            </div>
            <UiBadge v-if="syncStats.pendingExtraction > 0" variant="warning" dot>
              {{ syncStats.pendingExtraction }} pending
            </UiBadge>
          </div>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
            <UiStatCard 
              label="TeamTailor" 
              :value="`${syncStats.fromTeamtailorPct}%`"
              :subtext="`${formatNumber(syncStats.fromTeamtailor)} / ${formatNumber(syncStats.total)}`"
              variant="info"
            />
            <UiStatCard 
              label="Con CV" 
              :value="`${syncStats.withCvPct}%`"
              :subtext="`${formatNumber(syncStats.withCv)} / ${formatNumber(syncStats.total)}`"
              variant="purple"
            />
            <UiStatCard 
              label="Educación" 
              :value="`${syncStats.withEducationPct}%`"
              :subtext="`${formatNumber(syncStats.withEducation)} / ${formatNumber(syncStats.total)}`"
              :variant="getSyncVariant(syncStats.withEducationPct)"
            />
            <UiStatCard 
              label="Experiencia" 
              :value="`${syncStats.withWorkExperiencePct || 0}%`"
              :subtext="`${formatNumber(syncStats.withWorkExperience || 0)} / ${formatNumber(syncStats.total)}`"
              :variant="getSyncVariant(syncStats.withWorkExperiencePct || 0)"
            />
            <UiStatCard 
              label="Preguntas" 
              :value="`${syncStats.withCustomQuestionsPct}%`"
              :subtext="`${formatNumber(syncStats.withCustomQuestions)} / ${formatNumber(syncStats.total)}`"
              :variant="getSyncVariant(syncStats.withCustomQuestionsPct)"
            />
            <UiStatCard 
              label="Procesado" 
              :value="`${syncStats.processingCompletedPct}%`"
              :subtext="`${formatNumber(syncStats.processingCompleted)} / ${formatNumber(syncStats.total)}`"
              :variant="getSyncVariant(syncStats.processingCompletedPct)"
            />
            <UiStatCard 
              label="Cover Letter" 
              :value="`${syncStats.withCoverLetterEvalPct || 0}%`"
              :subtext="`✓${syncStats.coverLetterAdvance || 0} / ✗${syncStats.coverLetterReject || 0}`"
              :variant="getSyncVariant(syncStats.withCoverLetterEvalPct || 0)"
            />
            <UiStatCard 
              label="Pendiente" 
              :value="formatNumber(syncStats.pendingExtraction || 0)"
              subtext="CVs sin extraer"
              variant="warning"
            />
          </div>
        </div>
      </UiCard>

      <!-- Pipeline Overview -->
      <UiCard padding="none">
        <div class="px-6 py-4 border-b border-zinc-100">
          <div class="flex items-center justify-between">
            <h2 class="text-base font-semibold text-zinc-900">Pipeline Overview</h2>
            <UiButton href="/app/pipeline" variant="ghost" size="sm">
              View Pipeline
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </UiButton>
          </div>
        </div>
        <div class="p-6 overflow-x-auto">
          <div class="grid grid-cols-5 lg:grid-cols-10 gap-2 min-w-[600px]">
            <div 
              v-for="stage in canonicalStages" 
              :key="stage.canonical"
              :class="[
                'p-3 rounded-lg text-center transition-all',
                stage.kind === 'hired' ? 'bg-emerald-50 ring-1 ring-emerald-200' :
                stage.kind === 'rejected' ? 'bg-red-50 ring-1 ring-red-200' :
                'bg-zinc-50 ring-1 ring-zinc-200'
              ]"
            >
              <div :class="[
                'text-xl font-bold font-mono',
                stage.kind === 'hired' ? 'text-emerald-600' :
                stage.kind === 'rejected' ? 'text-red-600' :
                'text-zinc-900'
              ]">
                {{ stage.count }}
              </div>
              <div class="text-xs text-zinc-600 mt-1 truncate" :title="stage.name">{{ stage.name }}</div>
            </div>
          </div>
        </div>
      </UiCard>

      <!-- Recent Applications -->
      <div>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-zinc-900">Recent Applications</h2>
          <UiButton href="/app/applications" variant="ghost" size="sm">
            View All
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </UiButton>
        </div>
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
          
          <tr v-for="app in recentApplications" :key="app.id" class="group">
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
                  class="inline-flex items-center justify-center w-6 h-6 rounded bg-violet-100 text-violet-600"
                  title="Experiencia en startups"
                >
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </span>
                <span 
                  v-if="app.hasYearTenure" 
                  class="inline-flex items-center justify-center w-6 h-6 rounded bg-emerald-100 text-emerald-600"
                  title="+1 año en algún rol"
                >
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </span>
                <span 
                  v-if="app.hasPersonalProjects" 
                  class="inline-flex items-center justify-center w-6 h-6 rounded bg-amber-100 text-amber-600"
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
          
          <tr v-if="recentApplications.length === 0">
            <td colspan="7" class="px-6 py-12 text-center">
              <div class="w-12 h-12 bg-zinc-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-6 h-6 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
              </div>
              <p class="text-sm text-zinc-500">No applications yet</p>
            </td>
          </tr>
        </UiTable>
      </div>
    </div>
  </AppLayout>
</template>
