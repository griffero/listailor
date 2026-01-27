<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => []
  },
  options: {
    type: Array,
    required: true
  },
  label: String,
  placeholder: {
    type: String,
    default: 'Select...'
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

const isOpen = ref(false)
const dropdownRef = ref(null)

const selectedLabels = computed(() => {
  return props.options
    .filter(opt => props.modelValue.includes(opt.value))
    .map(opt => opt.label)
})

const displayText = computed(() => {
  if (props.modelValue.length === 0) return props.placeholder
  if (props.modelValue.length === 1) return selectedLabels.value[0]
  return `${props.modelValue.length} selected`
})

function toggle(value) {
  const newValue = props.modelValue.includes(value)
    ? props.modelValue.filter(v => v !== value)
    : [...props.modelValue, value]
  
  emit('update:modelValue', newValue)
  emit('change', newValue)
}

function isSelected(value) {
  return props.modelValue.includes(value)
}

function clearAll() {
  emit('update:modelValue', [])
  emit('change', [])
}

function handleClickOutside(event) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="space-y-1.5">
    <label v-if="label" class="block text-sm font-medium text-zinc-700">{{ label }}</label>
    <div ref="dropdownRef" class="relative">
      <!-- Trigger Button -->
      <button
        type="button"
        @click="isOpen = !isOpen"
        class="w-full flex items-center justify-between gap-2 px-3 py-2 text-sm bg-white border border-zinc-200 rounded-lg hover:border-zinc-300 focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-400 transition-colors"
        :class="{ 'ring-2 ring-zinc-900/10 border-zinc-400': isOpen }"
      >
        <span class="truncate" :class="modelValue.length === 0 ? 'text-zinc-400' : 'text-zinc-900'">
          {{ displayText }}
        </span>
        <div class="flex items-center gap-1">
          <span 
            v-if="modelValue.length > 0" 
            @click.stop="clearAll"
            class="p-0.5 hover:bg-zinc-100 rounded transition-colors"
          >
            <svg class="w-3.5 h-3.5 text-zinc-400 hover:text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </span>
          <svg 
            class="w-4 h-4 text-zinc-400 transition-transform" 
            :class="{ 'rotate-180': isOpen }"
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </button>

      <!-- Dropdown Panel -->
      <Transition
        enter-active-class="transition ease-out duration-100"
        enter-from-class="transform opacity-0 scale-95"
        enter-to-class="transform opacity-100 scale-100"
        leave-active-class="transition ease-in duration-75"
        leave-from-class="transform opacity-100 scale-100"
        leave-to-class="transform opacity-0 scale-95"
      >
        <div 
          v-if="isOpen"
          class="absolute z-50 mt-1 w-full bg-white border border-zinc-200 rounded-lg shadow-lg py-1 max-h-64 overflow-auto"
        >
          <div 
            v-for="option in options" 
            :key="option.value"
            @click="toggle(option.value)"
            class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-zinc-50 transition-colors"
          >
            <!-- Checkbox -->
            <div 
              class="w-4 h-4 rounded border-2 flex items-center justify-center transition-colors"
              :class="isSelected(option.value) 
                ? 'bg-zinc-900 border-zinc-900' 
                : 'border-zinc-300 hover:border-zinc-400'"
            >
              <svg 
                v-if="isSelected(option.value)" 
                class="w-3 h-3 text-white" 
                fill="none" viewBox="0 0 24 24" stroke="currentColor"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            
            <!-- Label -->
            <span class="flex-1 text-sm text-zinc-700">{{ option.label }}</span>
            
            <!-- Count Badge -->
            <span 
              v-if="option.count !== undefined" 
              class="text-xs font-medium px-1.5 py-0.5 rounded-full"
              :class="isSelected(option.value) ? 'bg-zinc-900 text-white' : 'bg-zinc-100 text-zinc-500'"
            >
              {{ option.count }}
            </span>
          </div>
          
          <div v-if="options.length === 0" class="px-3 py-2 text-sm text-zinc-400">
            No options available
          </div>
        </div>
      </Transition>
    </div>
  </div>
</template>
