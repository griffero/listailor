<script setup>
defineProps({
  modelValue: [String, Number],
  label: String,
  disabled: Boolean,
  error: String,
  hint: String
})

defineEmits(['update:modelValue'])
</script>

<template>
  <div class="space-y-1.5">
    <label v-if="label" class="block text-sm font-medium text-zinc-700">
      {{ label }}
    </label>
    <select
      :value="modelValue"
      :disabled="disabled"
      @change="$emit('update:modelValue', $event.target.value)"
      :class="[
        'block w-full rounded-lg border bg-white px-3 py-2 text-sm text-zinc-900',
        'transition-colors duration-150',
        'focus:outline-none focus:ring-2 focus:ring-offset-0',
        error 
          ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20' 
          : 'border-zinc-300 focus:border-zinc-900 focus:ring-zinc-900/10',
        disabled ? 'bg-zinc-50 cursor-not-allowed' : ''
      ]"
    >
      <slot />
    </select>
    <p v-if="error" class="text-xs text-red-600">{{ error }}</p>
    <p v-else-if="hint" class="text-xs text-zinc-500">{{ hint }}</p>
  </div>
</template>
