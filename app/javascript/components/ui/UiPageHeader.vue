<script setup>
defineProps({
  title: String,
  description: String
})
</script>

<template>
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-semibold text-zinc-900 tracking-tight">{{ title }}</h1>
      <p v-if="description" class="text-zinc-500 mt-1">{{ description }}</p>
    </div>
    <div v-if="$slots.actions" class="flex items-center gap-3">
      <slot name="actions" />
    </div>
  </div>
</template>
