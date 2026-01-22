<script setup>
import AppLayout from '@/layouts/AppLayout.vue'

defineProps({
  candidatesPerStagePerWeek: Array,
  averageTimeInStage: Array,
  currentUser: Object
})

function formatDays(days) {
  if (days < 1) return 'Less than a day'
  if (days === 1) return '1 day'
  return `${days} days`
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Reports</h1>
        <p class="text-gray-600">Pipeline analytics and metrics</p>
      </div>

      <!-- Average Time in Stage -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Average Time in Stage</h2>
        <div class="overflow-x-auto">
          <table class="min-w-full">
            <thead>
              <tr class="border-b">
                <th class="text-left py-2 text-sm font-medium text-gray-500">Stage</th>
                <th class="text-right py-2 text-sm font-medium text-gray-500">Avg. Time</th>
                <th class="text-right py-2 text-sm font-medium text-gray-500">Sample Size</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="stage in averageTimeInStage" :key="stage.stageId" class="border-b last:border-0">
                <td class="py-3">
                  <span 
                    class="font-medium"
                    :class="{
                      'text-green-600': stage.kind === 'hired',
                      'text-red-600': stage.kind === 'rejected',
                      'text-gray-900': stage.kind === 'active'
                    }"
                  >
                    {{ stage.stageName }}
                  </span>
                </td>
                <td class="py-3 text-right text-gray-600">
                  {{ formatDays(stage.averageDays) }}
                </td>
                <td class="py-3 text-right text-gray-500">
                  {{ stage.sampleSize }} applications
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Candidates Per Stage Per Week -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Candidates Per Stage (Last 12 Weeks)</h2>
        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b">
                <th class="text-left py-2 font-medium text-gray-500">Week</th>
                <th 
                  v-for="stage in (candidatesPerStagePerWeek[0]?.stages || [])" 
                  :key="stage.stageId"
                  class="text-right py-2 font-medium text-gray-500 px-2"
                >
                  {{ stage.stageName }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="week in candidatesPerStagePerWeek" :key="week.week" class="border-b last:border-0">
                <td class="py-2 font-medium text-gray-900">{{ week.weekLabel }}</td>
                <td 
                  v-for="stage in week.stages" 
                  :key="stage.stageId"
                  class="py-2 text-right text-gray-600 px-2"
                >
                  {{ stage.count || '—' }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- JSON Export -->
      <div class="bg-gray-50 rounded-lg p-4">
        <h3 class="text-sm font-medium text-gray-700 mb-2">API Endpoints</h3>
        <div class="space-y-1 text-sm text-gray-600">
          <div><code>GET /app/reports/candidates_per_stage</code> - JSON export</div>
          <div><code>GET /app/reports/time_in_stage</code> - JSON export</div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
