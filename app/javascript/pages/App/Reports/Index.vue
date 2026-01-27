<script setup>
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiStatCard, UiBadge } from '@/components/ui'

defineProps({
  funnelMetrics: Array,
  hiringVelocity: Array,
  sourceBreakdown: Array,
  timeToHire: Object,
  weeklyActivity: Array,
  currentUser: Object
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-8">
      <UiPageHeader 
        title="Reports" 
        description="Hiring analytics and pipeline metrics"
      />

      <!-- Time to Hire Stats -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <UiStatCard 
          label="Avg. Time to Hire" 
          :value="`${timeToHire.average} days`"
          :subtext="`Based on ${timeToHire.count} hires`"
          variant="info"
        />
        <UiStatCard 
          label="Median Time" 
          :value="`${timeToHire.median} days`"
          subtext="50th percentile"
          variant="default"
        />
        <UiStatCard 
          label="Fastest Hire" 
          :value="`${timeToHire.fastest || 0} days`"
          subtext="Best case"
          variant="success"
        />
        <UiStatCard 
          label="Slowest Hire" 
          :value="`${timeToHire.slowest || 0} days`"
          subtext="Worst case"
          variant="warning"
        />
      </div>

      <!-- Funnel + Weekly Activity Grid -->
      <div class="grid lg:grid-cols-2 gap-6">
        <!-- Pipeline Funnel -->
        <UiCard padding="none">
          <div class="px-6 py-4 border-b border-zinc-100">
            <h2 class="text-base font-semibold text-zinc-900">Pipeline Funnel</h2>
            <p class="text-sm text-zinc-500 mt-0.5">Current distribution across stages</p>
          </div>
          <div class="p-6 space-y-3">
            <div v-for="stage in funnelMetrics" :key="stage.stage" class="relative">
              <div class="flex items-center justify-between mb-1">
                <span 
                  class="text-sm font-medium"
                  :class="{
                    'text-emerald-600': stage.kind === 'hired',
                    'text-red-500': stage.kind === 'rejected',
                    'text-zinc-700': stage.kind === 'active'
                  }"
                >
                  {{ stage.label }}
                </span>
                <span class="text-sm text-zinc-500 font-mono">
                  {{ stage.count.toLocaleString() }} 
                  <span class="text-zinc-400">({{ stage.percentage }}%)</span>
                </span>
              </div>
              <div class="h-2 bg-zinc-100 rounded-full overflow-hidden">
                <div 
                  class="h-full rounded-full transition-all duration-500"
                  :class="{
                    'bg-emerald-500': stage.kind === 'hired',
                    'bg-red-400': stage.kind === 'rejected',
                    'bg-zinc-400': stage.kind === 'active'
                  }"
                  :style="{ width: `${Math.max(stage.percentage, 1)}%` }"
                ></div>
              </div>
            </div>
          </div>
        </UiCard>

        <!-- Weekly Activity -->
        <UiCard padding="none">
          <div class="px-6 py-4 border-b border-zinc-100">
            <h2 class="text-base font-semibold text-zinc-900">Weekly Activity</h2>
            <p class="text-sm text-zinc-500 mt-0.5">Last 8 weeks</p>
          </div>
          <div class="overflow-x-auto">
            <table class="min-w-full">
              <thead class="bg-zinc-50/50">
                <tr>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-zinc-500 uppercase">Week</th>
                  <th class="text-right px-4 py-3 text-xs font-semibold text-zinc-500 uppercase">Applications</th>
                  <th class="text-right px-4 py-3 text-xs font-semibold text-zinc-500 uppercase">Hired</th>
                  <th class="text-right px-6 py-3 text-xs font-semibold text-zinc-500 uppercase">Rejected</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-100">
                <tr v-for="week in weeklyActivity" :key="week.week" class="hover:bg-zinc-50/50">
                  <td class="px-6 py-3 text-sm font-medium text-zinc-900">{{ week.week }}</td>
                  <td class="px-4 py-3 text-sm text-right font-mono text-zinc-600">
                    {{ week.applications || '—' }}
                  </td>
                  <td class="px-4 py-3 text-sm text-right">
                    <span v-if="week.hired" class="inline-flex items-center px-2 py-0.5 rounded bg-emerald-100 text-emerald-700 font-mono text-xs">
                      +{{ week.hired }}
                    </span>
                    <span v-else class="text-zinc-300">—</span>
                  </td>
                  <td class="px-6 py-3 text-sm text-right">
                    <span v-if="week.rejected" class="inline-flex items-center px-2 py-0.5 rounded bg-red-100 text-red-600 font-mono text-xs">
                      {{ week.rejected }}
                    </span>
                    <span v-else class="text-zinc-300">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </UiCard>
      </div>

      <!-- Hiring Velocity + Source Breakdown -->
      <div class="grid lg:grid-cols-2 gap-6">
        <!-- Hiring Velocity -->
        <UiCard padding="none">
          <div class="px-6 py-4 border-b border-zinc-100">
            <h2 class="text-base font-semibold text-zinc-900">Hiring Velocity</h2>
            <p class="text-sm text-zinc-500 mt-0.5">Monthly hiring trends</p>
          </div>
          <div class="p-6">
            <div class="flex items-end gap-2 h-40">
              <div 
                v-for="month in hiringVelocity" 
                :key="month.month"
                class="flex-1 flex flex-col items-center gap-2"
              >
                <div class="w-full flex flex-col items-center">
                  <span class="text-xs font-mono text-zinc-500 mb-1">{{ month.hired }}</span>
                  <div 
                    class="w-full bg-emerald-500 rounded-t transition-all duration-500"
                    :style="{ 
                      height: `${Math.max((month.hired / Math.max(...hiringVelocity.map(m => m.hired), 1)) * 100, 4)}px` 
                    }"
                  ></div>
                </div>
                <span class="text-xs text-zinc-500">{{ month.monthShort }}</span>
              </div>
            </div>
            <div class="mt-4 pt-4 border-t border-zinc-100 grid grid-cols-3 gap-4 text-center">
              <div>
                <div class="text-lg font-bold font-mono text-zinc-900">
                  {{ hiringVelocity.reduce((sum, m) => sum + m.hired, 0) }}
                </div>
                <div class="text-xs text-zinc-500">Total Hired</div>
              </div>
              <div>
                <div class="text-lg font-bold font-mono text-zinc-900">
                  {{ hiringVelocity.reduce((sum, m) => sum + m.applications, 0).toLocaleString() }}
                </div>
                <div class="text-xs text-zinc-500">Applications</div>
              </div>
              <div>
                <div class="text-lg font-bold font-mono text-zinc-900">
                  {{ (hiringVelocity.reduce((sum, m) => sum + m.conversionRate, 0) / hiringVelocity.length).toFixed(1) }}%
                </div>
                <div class="text-xs text-zinc-500">Avg. Conversion</div>
              </div>
            </div>
          </div>
        </UiCard>

        <!-- Source Breakdown -->
        <UiCard padding="none">
          <div class="px-6 py-4 border-b border-zinc-100">
            <h2 class="text-base font-semibold text-zinc-900">Application Sources</h2>
            <p class="text-sm text-zinc-500 mt-0.5">Top 10 sources</p>
          </div>
          <div class="divide-y divide-zinc-100">
            <div 
              v-for="(source, index) in sourceBreakdown" 
              :key="source.source"
              class="px-6 py-3 flex items-center justify-between hover:bg-zinc-50/50"
            >
              <div class="flex items-center gap-3">
                <span class="w-6 h-6 flex items-center justify-center rounded-full bg-zinc-100 text-xs font-medium text-zinc-600">
                  {{ index + 1 }}
                </span>
                <span class="text-sm font-medium text-zinc-900">{{ source.source }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="text-sm font-mono text-zinc-600">{{ source.count.toLocaleString() }}</span>
                <UiBadge variant="default" size="sm">{{ source.percentage }}%</UiBadge>
              </div>
            </div>
            <div v-if="sourceBreakdown.length === 0" class="px-6 py-8 text-center text-sm text-zinc-500">
              No source data available
            </div>
          </div>
        </UiCard>
      </div>
    </div>
  </AppLayout>
</template>
