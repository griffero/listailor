<script setup>
defineProps({
  label: String,
  value: [String, Number],
  subtext: String,
  variant: {
    type: String,
    default: 'default',
    validator: (v) => ['default', 'success', 'warning', 'danger', 'info', 'purple'].includes(v)
  },
  trend: {
    type: String,
    validator: (v) => ['up', 'down', 'neutral'].includes(v)
  },
  trendValue: String
})

const variantStyles = {
  default: {
    bg: 'bg-zinc-50',
    text: 'text-zinc-900',
    accent: 'text-zinc-600'
  },
  success: {
    bg: 'bg-emerald-50',
    text: 'text-emerald-700',
    accent: 'text-emerald-600'
  },
  warning: {
    bg: 'bg-amber-50',
    text: 'text-amber-700',
    accent: 'text-amber-600'
  },
  danger: {
    bg: 'bg-red-50',
    text: 'text-red-700',
    accent: 'text-red-600'
  },
  info: {
    bg: 'bg-blue-50',
    text: 'text-blue-700',
    accent: 'text-blue-600'
  },
  purple: {
    bg: 'bg-violet-50',
    text: 'text-violet-700',
    accent: 'text-violet-600'
  }
}
</script>

<template>
  <div :class="['rounded-xl p-4 text-center', variantStyles[variant].bg]">
    <div :class="['text-2xl font-bold font-mono tracking-tight', variantStyles[variant].text]">
      {{ value }}
    </div>
    <div class="text-sm text-zinc-600 mt-1">{{ label }}</div>
    <div v-if="subtext" class="text-xs text-zinc-400 mt-0.5 font-mono">{{ subtext }}</div>
    <div v-if="trend" class="flex items-center justify-center gap-1 mt-2 text-xs">
      <svg v-if="trend === 'up'" class="w-3 h-3 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
      </svg>
      <svg v-else-if="trend === 'down'" class="w-3 h-3 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
      </svg>
      <span :class="trend === 'up' ? 'text-emerald-600' : trend === 'down' ? 'text-red-600' : 'text-zinc-500'">
        {{ trendValue }}
      </span>
    </div>
  </div>
</template>
