<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import draggable from 'vuedraggable'

const props = defineProps({
  stages: Array,
  jobs: Array,
  currentUser: Object
})

const localStages = ref([...props.stages])

function onDragEnd(stageId, event) {
  const appId = event.item.dataset.appId
  if (!appId) return
  
  router.post(`/app/applications/${appId}/move_stage`, {
    stage_id: stageId
  }, {
    preserveScroll: true
  })
}

function getStageClass(kind) {
  switch (kind) {
    case 'hired': return 'border-green-300 bg-green-50'
    case 'rejected': return 'border-red-300 bg-red-50'
    default: return 'border-gray-300 bg-gray-50'
  }
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Pipeline</h1>
          <p class="text-gray-600">Drag applications between stages</p>
        </div>
        <Link 
          href="/app/applications/new"
          class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
        >
          Add Application
        </Link>
      </div>

      <div class="flex gap-4 overflow-x-auto pb-4">
        <div 
          v-for="stage in stages" 
          :key="stage.id"
          class="flex-shrink-0 w-72"
        >
          <div 
            class="rounded-lg border-2 h-full"
            :class="getStageClass(stage.kind)"
          >
            <div class="p-3 border-b border-gray-200">
              <div class="flex justify-between items-center">
                <h3 class="font-semibold text-gray-900">{{ stage.name }}</h3>
                <span class="text-sm text-gray-500">{{ stage.applications.length }}</span>
              </div>
            </div>
            
            <draggable
              :list="stage.applications"
              group="applications"
              item-key="id"
              class="p-2 min-h-[200px] space-y-2"
              @end="(e) => onDragEnd(stage.id, e)"
            >
              <template #item="{ element: app }">
                <div 
                  :data-app-id="app.id"
                  class="bg-white rounded-lg shadow-sm p-3 cursor-grab active:cursor-grabbing border border-gray-200 hover:border-indigo-300 transition"
                >
                  <Link :href="`/app/applications/${app.id}`" class="block">
                    <div class="font-medium text-gray-900 text-sm">{{ app.candidate.name }}</div>
                    <div class="text-xs text-gray-500 mt-1">{{ app.job.title }}</div>
                    <div class="text-xs text-gray-400 mt-1">{{ formatDate(app.createdAt) }}</div>
                  </Link>
                </div>
              </template>
            </draggable>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script>
export default {
  methods: {
    formatDate(dateStr) {
      return new Date(dateStr).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
      })
    }
  }
}
</script>

<style scoped>
.sortable-ghost {
  opacity: 0.5;
  background: #c8ebfb;
}
</style>
