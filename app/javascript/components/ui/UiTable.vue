<script setup>
defineProps({
  hoverable: {
    type: Boolean,
    default: true
  }
})
</script>

<template>
  <div class="bg-white rounded-xl border border-zinc-200/60 shadow-sm overflow-hidden">
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-zinc-200">
        <thead class="bg-zinc-50/50">
          <slot name="header" />
        </thead>
        <tbody :class="['divide-y divide-zinc-100', hoverable ? '[&>tr]:hover:bg-zinc-50/50' : '']">
          <slot />
        </tbody>
      </table>
    </div>
  </div>
</template>
