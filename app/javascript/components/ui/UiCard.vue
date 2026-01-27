<script setup>
defineProps({
  padding: {
    type: String,
    default: 'md',
    validator: (v) => ['none', 'sm', 'md', 'lg'].includes(v)
  },
  hover: Boolean
})

const paddingClasses = {
  none: '',
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8'
}
</script>

<template>
  <div 
    :class="[
      'bg-white rounded-xl border border-zinc-200/60 shadow-sm',
      paddingClasses[padding],
      hover ? 'hover:border-zinc-300 hover:shadow-md transition-all duration-200' : ''
    ]"
  >
    <slot />
  </div>
</template>
