<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: (v) => ['default', 'success', 'warning', 'danger', 'info', 'purple', 'outline'].includes(v)
  },
  size: {
    type: String,
    default: 'md',
    validator: (v) => ['sm', 'md'].includes(v)
  },
  dot: Boolean
})

const classes = computed(() => {
  const base = 'inline-flex items-center font-medium rounded-full'
  
  const variants = {
    default: 'bg-zinc-100 text-zinc-700',
    success: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20',
    warning: 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20',
    danger: 'bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20',
    info: 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20',
    purple: 'bg-violet-50 text-violet-700 ring-1 ring-inset ring-violet-600/20',
    outline: 'bg-transparent text-zinc-600 ring-1 ring-inset ring-zinc-300'
  }
  
  const sizes = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-xs'
  }
  
  return `${base} ${variants[props.variant]} ${sizes[props.size]}`
})

const dotColors = {
  default: 'bg-zinc-500',
  success: 'bg-emerald-500',
  warning: 'bg-amber-500',
  danger: 'bg-red-500',
  info: 'bg-blue-500',
  purple: 'bg-violet-500',
  outline: 'bg-zinc-400'
}
</script>

<template>
  <span :class="classes">
    <span v-if="dot" :class="['w-1.5 h-1.5 rounded-full mr-1.5', dotColors[variant]]" />
    <slot />
  </span>
</template>
