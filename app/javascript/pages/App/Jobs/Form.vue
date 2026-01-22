<script setup>
import { ref, computed } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  job: Object,
  questions: Array,
  currentUser: Object
})

const isEditing = computed(() => !!props.job)

const form = ref({
  title: props.job?.title || '',
  slug: props.job?.slug || '',
  description: props.job?.description || '',
  department: props.job?.department || '',
  location: props.job?.location || ''
})

const newQuestion = ref({
  label: '',
  kind: 'long_text',
  required: false,
  options: ''
})

function submit() {
  const url = isEditing.value ? `/app/jobs/${props.job.id}` : '/app/jobs'
  const method = isEditing.value ? 'put' : 'post'
  
  router[method](url, {
    job_posting: form.value
  })
}

function addQuestion() {
  if (!newQuestion.value.label) return
  
  const options = newQuestion.value.kind === 'select' 
    ? newQuestion.value.options.split(',').map(o => o.trim()).filter(Boolean)
    : null

  router.post(`/app/jobs/${props.job.id}/questions`, {
    job_question: {
      label: newQuestion.value.label,
      kind: newQuestion.value.kind,
      required: newQuestion.value.required,
      options: options
    }
  }, {
    preserveScroll: true,
    onSuccess: () => {
      newQuestion.value = { label: '', kind: 'long_text', required: false, options: '' }
    }
  })
}

function removeQuestion(id) {
  if (confirm('Remove this question?')) {
    router.delete(`/app/jobs/${props.job.id}/questions/${id}`, {
      preserveScroll: true
    })
  }
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-3xl mx-auto space-y-6">
      <div>
        <Link href="/app/jobs" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
          ← Back to Jobs
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ isEditing ? 'Edit Job' : 'Create Job' }}
        </h1>
      </div>

      <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Title *</label>
          <input 
            v-model="form.title"
            type="text" 
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Slug</label>
          <input 
            v-model="form.slug"
            type="text"
            placeholder="auto-generated-from-title"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
          <p class="text-xs text-gray-500 mt-1">Leave empty to auto-generate</p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Department</label>
            <input 
              v-model="form.department"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Location</label>
            <input 
              v-model="form.location"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Description *</label>
          <textarea 
            v-model="form.description"
            required
            rows="10"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          ></textarea>
        </div>

        <div class="flex justify-end gap-3">
          <Link href="/app/jobs" class="px-4 py-2 text-gray-700 hover:text-gray-900">Cancel</Link>
          <button 
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            {{ isEditing ? 'Update' : 'Create' }}
          </button>
        </div>
      </form>

      <!-- Questions (only for editing) -->
      <div v-if="isEditing" class="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 class="text-lg font-semibold text-gray-900">Application Questions</h2>

        <!-- Existing Questions -->
        <div v-if="questions && questions.length > 0" class="space-y-3">
          <div v-for="q in questions" :key="q.id" class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div>
              <span class="font-medium">{{ q.label }}</span>
              <span v-if="q.required" class="text-red-500 ml-1">*</span>
              <span class="text-sm text-gray-500 ml-2">({{ q.kind }})</span>
            </div>
            <button @click="removeQuestion(q.id)" class="text-red-600 hover:text-red-800 text-sm">
              Remove
            </button>
          </div>
        </div>

        <!-- Add Question -->
        <div class="border-t pt-6">
          <h3 class="text-sm font-medium text-gray-700 mb-4">Add Question</h3>
          <div class="space-y-4">
            <div>
              <input 
                v-model="newQuestion.label"
                type="text"
                placeholder="Question text"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <select 
                  v-model="newQuestion.kind"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="long_text">Long Text</option>
                  <option value="short_text">Short Text</option>
                  <option value="number">Number</option>
                  <option value="checkbox">Checkbox</option>
                  <option value="select">Select</option>
                </select>
              </div>
              <div class="flex items-center">
                <label class="flex items-center">
                  <input type="checkbox" v-model="newQuestion.required" class="rounded border-gray-300 text-indigo-600">
                  <span class="ml-2 text-sm text-gray-700">Required</span>
                </label>
              </div>
            </div>
            <div v-if="newQuestion.kind === 'select'">
              <input 
                v-model="newQuestion.options"
                type="text"
                placeholder="Options (comma separated)"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
            </div>
            <button 
              @click="addQuestion"
              type="button"
              class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
            >
              Add Question
            </button>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
