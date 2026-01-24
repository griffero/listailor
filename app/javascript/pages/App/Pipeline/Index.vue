<script setup>
import { ref, watch } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import draggable from 'vuedraggable'

const props = defineProps({
  stages: Array,
  jobs: Array,
  currentUser: Object
})

// Slide-over state
const showManagePanel = ref(false)
const managedStages = ref([])
const editingStageId = ref(null)
const editForm = ref({ name: '', kind: 'active' })
const newStageForm = ref({ name: '', kind: 'active' })
const isSubmitting = ref(false)

// Sync managed stages when panel opens
watch(showManagePanel, (open) => {
  if (open) {
    managedStages.value = props.stages.map(s => ({ ...s }))
  }
})

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

function getKindBadgeClass(kind) {
  switch (kind) {
    case 'hired': return 'bg-green-100 text-green-800'
    case 'rejected': return 'bg-red-100 text-red-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function formatCount(count, threshold = 100) {
  if (count > threshold) return `+${threshold}`
  return String(count)
}

// Stage management functions
function startEdit(stage) {
  editingStageId.value = stage.id
  editForm.value = { name: stage.name, kind: stage.kind }
}

function cancelEdit() {
  editingStageId.value = null
  editForm.value = { name: '', kind: 'active' }
}

function saveEdit(stage) {
  if (!editForm.value.name.trim()) return
  isSubmitting.value = true
  
  router.patch(`/app/pipeline_stages/${stage.id}`, {
    pipeline_stage: editForm.value
  }, {
    preserveScroll: true,
    onSuccess: () => {
      editingStageId.value = null
      editForm.value = { name: '', kind: 'active' }
    },
    onFinish: () => {
      isSubmitting.value = false
    }
  })
}

function createStage() {
  if (!newStageForm.value.name.trim()) return
  isSubmitting.value = true
  
  router.post('/app/pipeline_stages', {
    pipeline_stage: newStageForm.value
  }, {
    preserveScroll: true,
    onSuccess: () => {
      newStageForm.value = { name: '', kind: 'active' }
    },
    onFinish: () => {
      isSubmitting.value = false
    }
  })
}

function deleteStage(stage) {
  if (stage.applicationCount > 0) {
    alert('Cannot delete stage with applications. Move them first.')
    return
  }
  
  if (!confirm(`Delete stage "${stage.name}"?`)) return
  
  isSubmitting.value = true
  router.delete(`/app/pipeline_stages/${stage.id}`, {
    preserveScroll: true,
    onFinish: () => {
      isSubmitting.value = false
    }
  })
}

function onStageReorder() {
  const stageIds = managedStages.value.map(s => s.id)
  
  router.post('/app/pipeline_stages/reorder', {
    stage_ids: stageIds
  }, {
    preserveScroll: true
  })
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric'
  })
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
        <div class="flex gap-3">
          <button
            type="button"
            @click="showManagePanel = true"
            class="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition cursor-pointer"
          >
            Manage Stages
          </button>
          <Link 
            href="/app/applications/new"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Add Application
          </Link>
        </div>
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
                <span class="text-sm text-gray-500">
                  {{ formatCount(stage.applicationCount || 0) }}
                </span>
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

    <!-- Slide-over Panel -->
    <div v-if="showManagePanel" class="fixed inset-0 z-50 overflow-hidden">
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          @click="showManagePanel = false"
        ></div>

        <!-- Panel -->
        <div class="absolute inset-y-0 right-0 flex max-w-full pl-10">
          <div class="w-screen max-w-md">
            <div class="h-full flex flex-col bg-white shadow-xl">
              <!-- Header -->
              <div class="px-4 py-6 bg-indigo-600 sm:px-6">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-medium text-white">Manage Pipeline Stages</h2>
                  <button
                    @click="showManagePanel = false"
                    class="text-indigo-200 hover:text-white"
                  >
                    <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
                <p class="mt-1 text-sm text-indigo-200">
                  Drag to reorder, click to edit
                </p>
              </div>

              <!-- Content -->
              <div class="flex-1 overflow-y-auto px-4 py-6 sm:px-6">
                <!-- Add New Stage -->
                <div class="mb-6 p-4 bg-gray-50 rounded-lg">
                  <h3 class="text-sm font-medium text-gray-900 mb-3">Add New Stage</h3>
                  <div class="space-y-3">
                    <input
                      v-model="newStageForm.name"
                      type="text"
                      placeholder="Stage name"
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      @keyup.enter="createStage"
                    >
                    <div class="flex gap-2">
                      <select
                        v-model="newStageForm.kind"
                        class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      >
                        <option value="active">Active</option>
                        <option value="hired">Hired (terminal)</option>
                        <option value="rejected">Rejected (terminal)</option>
                      </select>
                      <button
                        @click="createStage"
                        :disabled="!newStageForm.name.trim() || isSubmitting"
                        class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                      >
                        Add
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Stages List -->
                <h3 class="text-sm font-medium text-gray-900 mb-3">Current Stages</h3>
                <draggable
                  v-model="managedStages"
                  item-key="id"
                  handle=".drag-handle"
                  class="space-y-2"
                  @end="onStageReorder"
                >
                  <template #item="{ element: stage }">
                    <div 
                      class="bg-white border border-gray-200 rounded-lg p-3 shadow-sm"
                      :class="{ 'ring-2 ring-indigo-500': editingStageId === stage.id }"
                    >
                      <!-- View Mode -->
                      <div v-if="editingStageId !== stage.id" class="flex items-center gap-3">
                        <div class="drag-handle cursor-grab text-gray-400 hover:text-gray-600">
                          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8h16M4 16h16" />
                          </svg>
                        </div>
                        
                        <div class="flex-1 min-w-0">
                          <div class="flex items-center gap-2">
                            <span class="font-medium text-gray-900 truncate">{{ stage.name }}</span>
                            <span 
                              class="px-2 py-0.5 text-xs font-medium rounded-full"
                              :class="getKindBadgeClass(stage.kind)"
                            >
                              {{ stage.kind }}
                            </span>
                          </div>
                          <div class="text-xs text-gray-500 mt-0.5">
                            {{ stage.applicationCount || 0 }} application{{ (stage.applicationCount || 0) === 1 ? '' : 's' }}
                          </div>
                        </div>

                        <div class="flex items-center gap-1">
                          <button
                            @click="startEdit(stage)"
                            class="p-1.5 text-gray-400 hover:text-indigo-600 rounded"
                            title="Edit"
                          >
                            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                            </svg>
                          </button>
                          <button
                            @click="deleteStage(stage)"
                            class="p-1.5 text-gray-400 hover:text-red-600 rounded disabled:opacity-50 disabled:cursor-not-allowed"
                            :disabled="stage.applicationCount > 0"
                            :title="stage.applicationCount > 0 ? 'Cannot delete: has applications' : 'Delete'"
                          >
                            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </div>
                      </div>

                      <!-- Edit Mode -->
                      <div v-else class="space-y-3">
                        <input
                          v-model="editForm.name"
                          type="text"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                          @keyup.enter="saveEdit(stage)"
                          @keyup.escape="cancelEdit"
                        >
                        <select
                          v-model="editForm.kind"
                          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                        >
                          <option value="active">Active</option>
                          <option value="hired">Hired (terminal)</option>
                          <option value="rejected">Rejected (terminal)</option>
                        </select>
                        <div class="flex gap-2">
                          <button
                            @click="cancelEdit"
                            class="flex-1 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 text-sm"
                          >
                            Cancel
                          </button>
                          <button
                            @click="saveEdit(stage)"
                            :disabled="!editForm.name.trim() || isSubmitting"
                            class="flex-1 px-3 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 text-sm"
                          >
                            Save
                          </button>
                        </div>
                      </div>
                    </div>
                  </template>
                </draggable>

                <p v-if="managedStages.length === 0" class="text-center text-gray-500 py-8">
                  No stages yet. Add one above.
                </p>
              </div>

              <!-- Footer -->
              <div class="border-t border-gray-200 px-4 py-4 sm:px-6">
                <button
                  @click="showManagePanel = false"
                  class="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
  </AppLayout>
</template>

<style scoped>
.sortable-ghost {
  opacity: 0.5;
  background: #c8ebfb;
}
</style>
