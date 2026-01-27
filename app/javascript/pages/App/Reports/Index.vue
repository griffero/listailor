<script setup>
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiTable, UiBadge } from '@/components/ui'

defineProps({
  candidatesPerStagePerWeek: Array,
  averageTimeInStage: Array,
  currentUser: Object
})

function formatDays(days) {
  if (days < 1) return '< 1 day'
  if (days === 1) return '1 day'
  return `${days} days`
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-8">
      <UiPageHeader 
        title="Reports" 
        description="Pipeline analytics and metrics"
      />

      <!-- Average Time in Stage -->
      <UiCard padding="none">
        <div class="px-6 py-4 border-b border-zinc-100">
          <h2 class="text-base font-semibold text-zinc-900">Average Time in Stage</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full">
            <thead class="bg-zinc-50/50">
              <tr>
                <th class="text-left px-6 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider">Stage</th>
                <th class="text-right px-6 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider">Avg. Time</th>
                <th class="text-right px-6 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider">Sample Size</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100">
              <tr v-for="stage in averageTimeInStage" :key="stage.stageId" class="hover:bg-zinc-50/50">
                <td class="px-6 py-3">
                  <div class="flex items-center gap-2">
                    <span 
                      class="font-medium"
                      :class="{
                        'text-emerald-600': stage.kind === 'hired',
                        'text-red-600': stage.kind === 'rejected',
                        'text-zinc-900': stage.kind === 'active'
                      }"
                    >
                      {{ stage.stageName }}
                    </span>
                    <UiBadge 
                      v-if="stage.kind === 'hired' || stage.kind === 'rejected'"
                      :variant="stage.kind === 'hired' ? 'success' : 'danger'"
                      size="sm"
                    >
                      {{ stage.kind }}
                    </UiBadge>
                  </div>
                </td>
                <td class="px-6 py-3 text-right text-zinc-600 font-mono text-sm">
                  {{ formatDays(stage.averageDays) }}
                </td>
                <td class="px-6 py-3 text-right text-zinc-400 text-sm">
                  {{ stage.sampleSize }} applications
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UiCard>

      <!-- Candidates Per Stage Per Week -->
      <UiCard padding="none">
        <div class="px-6 py-4 border-b border-zinc-100">
          <h2 class="text-base font-semibold text-zinc-900">Candidates Per Stage (Last 12 Weeks)</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="bg-zinc-50/50">
              <tr>
                <th class="text-left px-6 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider">Week</th>
                <th 
                  v-for="stage in (candidatesPerStagePerWeek[0]?.stages || [])" 
                  :key="stage.stageId"
                  class="text-right px-3 py-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider"
                >
                  {{ stage.stageName }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100">
              <tr v-for="week in candidatesPerStagePerWeek" :key="week.week" class="hover:bg-zinc-50/50">
                <td class="px-6 py-3 font-medium text-zinc-900">{{ week.weekLabel }}</td>
                <td 
                  v-for="stage in week.stages" 
                  :key="stage.stageId"
                  class="px-3 py-3 text-right text-zinc-600 font-mono"
                >
                  <span v-if="stage.count" class="px-2 py-0.5 bg-zinc-100 rounded">{{ stage.count }}</span>
                  <span v-else class="text-zinc-300">—</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UiCard>

      <!-- API Endpoints -->
      <UiCard class="bg-zinc-50 border-zinc-200">
        <h3 class="text-sm font-semibold text-zinc-900 mb-3">API Endpoints</h3>
        <div class="space-y-2">
          <div class="flex items-center gap-2">
            <UiBadge variant="info" size="sm">GET</UiBadge>
            <code class="font-mono text-xs text-zinc-600">/app/reports/candidates_per_stage</code>
            <span class="text-xs text-zinc-400">JSON export</span>
          </div>
          <div class="flex items-center gap-2">
            <UiBadge variant="info" size="sm">GET</UiBadge>
            <code class="font-mono text-xs text-zinc-600">/app/reports/time_in_stage</code>
            <span class="text-xs text-zinc-400">JSON export</span>
          </div>
        </div>
      </UiCard>
    </div>
  </AppLayout>
</template>
