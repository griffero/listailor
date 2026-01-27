<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

defineProps({
  recentApplications: Array,
  canonicalStages: Array,
  stats: Object,
  syncStats: Object,
  currentUser: Object
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <!-- Header -->
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p class="text-gray-600">Welcome to Listailor ATS</p>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm font-medium text-gray-500">Total Applications</div>
          <div class="text-3xl font-bold text-gray-900 mt-1">{{ stats.totalApplications }}</div>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm font-medium text-gray-500">Active Jobs</div>
          <div class="text-3xl font-bold text-gray-900 mt-1">{{ stats.totalJobs }}</div>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm font-medium text-gray-500">This Week</div>
          <div class="text-3xl font-bold text-gray-900 mt-1">{{ stats.thisWeekApplications }}</div>
        </div>
      </div>

      <!-- Sync Overview -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Sync Overview</h2>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
            <!-- From TeamTailor -->
            <div class="text-center p-4 rounded-lg bg-blue-50">
              <div class="text-2xl font-bold text-blue-600">{{ syncStats.fromTeamtailorPct }}%</div>
              <div class="text-sm text-gray-600 mt-1">TeamTailor</div>
              <div class="text-xs text-gray-400">{{ syncStats.fromTeamtailor?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- With CV -->
            <div class="text-center p-4 rounded-lg bg-purple-50">
              <div class="text-2xl font-bold text-purple-600">{{ syncStats.withCvPct }}%</div>
              <div class="text-sm text-gray-600 mt-1">Con CV</div>
              <div class="text-xs text-gray-400">{{ syncStats.withCv?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- With Education -->
            <div class="text-center p-4 rounded-lg" :class="syncStats.withEducationPct >= 80 ? 'bg-green-50' : 'bg-yellow-50'">
              <div class="text-2xl font-bold" :class="syncStats.withEducationPct >= 80 ? 'text-green-600' : 'text-yellow-600'">{{ syncStats.withEducationPct }}%</div>
              <div class="text-sm text-gray-600 mt-1">Educación</div>
              <div class="text-xs text-gray-400">{{ syncStats.withEducation?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- With Work Experience -->
            <div class="text-center p-4 rounded-lg" :class="syncStats.withWorkExperiencePct >= 80 ? 'bg-green-50' : 'bg-yellow-50'">
              <div class="text-2xl font-bold" :class="syncStats.withWorkExperiencePct >= 80 ? 'text-green-600' : 'text-yellow-600'">{{ syncStats.withWorkExperiencePct || 0 }}%</div>
              <div class="text-sm text-gray-600 mt-1">Experiencia</div>
              <div class="text-xs text-gray-400">{{ (syncStats.withWorkExperience || 0)?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- With Custom Questions -->
            <div class="text-center p-4 rounded-lg" :class="syncStats.withCustomQuestionsPct >= 80 ? 'bg-green-50' : 'bg-yellow-50'">
              <div class="text-2xl font-bold" :class="syncStats.withCustomQuestionsPct >= 80 ? 'text-green-600' : 'text-yellow-600'">{{ syncStats.withCustomQuestionsPct }}%</div>
              <div class="text-sm text-gray-600 mt-1">Preguntas</div>
              <div class="text-xs text-gray-400">{{ syncStats.withCustomQuestions?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- Processing Completed -->
            <div class="text-center p-4 rounded-lg" :class="syncStats.processingCompletedPct >= 80 ? 'bg-green-50' : 'bg-yellow-50'">
              <div class="text-2xl font-bold" :class="syncStats.processingCompletedPct >= 80 ? 'text-green-600' : 'text-yellow-600'">{{ syncStats.processingCompletedPct }}%</div>
              <div class="text-sm text-gray-600 mt-1">Procesado</div>
              <div class="text-xs text-gray-400">{{ syncStats.processingCompleted?.toLocaleString() }} / {{ syncStats.total?.toLocaleString() }}</div>
            </div>
            
            <!-- Pending Extraction -->
            <div class="text-center p-4 rounded-lg bg-orange-50">
              <div class="text-2xl font-bold text-orange-600">{{ syncStats.pendingExtraction || 0 }}</div>
              <div class="text-sm text-gray-600 mt-1">Pendiente</div>
              <div class="text-xs text-gray-400">CVs sin extraer</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pipeline Overview -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Pipeline Overview</h2>
        </div>
        <div class="p-6">
          <div class="flex gap-4 overflow-x-auto">
            <div 
              v-for="stage in canonicalStages" 
              :key="stage.canonical"
              class="flex-shrink-0 w-28 text-center p-4 rounded-lg"
              :class="{
                'bg-green-50': stage.kind === 'hired',
                'bg-red-50': stage.kind === 'rejected',
                'bg-gray-50': stage.kind === 'active'
              }"
            >
              <div class="text-2xl font-bold" :class="{
                'text-green-600': stage.kind === 'hired',
                'text-red-600': stage.kind === 'rejected',
                'text-gray-900': stage.kind === 'active'
              }">
                {{ stage.count }}
              </div>
              <div class="text-sm text-gray-600 mt-1">{{ stage.name }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Applications -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
          <h2 class="text-lg font-semibold text-gray-900">Recent Applications</h2>
          <Link href="/app/applications" class="text-sm text-indigo-600 hover:text-indigo-800">View all</Link>
        </div>
        <div class="divide-y divide-gray-200">
          <div 
            v-for="app in recentApplications" 
            :key="app.id"
            class="px-6 py-4 hover:bg-gray-50"
          >
            <Link :href="`/app/applications/${app.id}`" class="flex justify-between items-center">
              <div>
                <div class="font-medium text-gray-900">{{ app.candidate.name }}</div>
                <div class="text-sm text-gray-500">{{ app.job.title }}</div>
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
                <span class="text-sm text-gray-500">{{ formatDate(app.createdAt) }}</span>
              </div>
            </Link>
          </div>
          <div v-if="recentApplications.length === 0" class="px-6 py-8 text-center text-gray-500">
            No applications yet
          </div>
        </div>
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
        day: 'numeric'
      })
    }
  }
}
</script>
