<script setup>
import { ref, computed } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  template: Object,
  variables: Array,
  currentUser: Object
})

const isEditing = computed(() => !!props.template)

const form = ref({
  name: props.template?.name || '',
  subject: props.template?.subject || '',
  body: props.template?.body || ''
})

function submit() {
  const url = isEditing.value ? `/app/email_templates/${props.template.id}` : '/app/email_templates'
  const method = isEditing.value ? 'put' : 'post'
  
  router[method](url, {
    email_template: form.value
  })
}

function insertVariable(variable) {
  form.value.body += `{{${variable}}}`
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-3xl mx-auto space-y-6">
      <div>
        <Link href="/app/email_templates" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
          ← Back to Templates
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ isEditing ? 'Edit Template' : 'Create Template' }}
        </h1>
      </div>

      <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Template Name *</label>
          <input 
            v-model="form.name"
            type="text"
            required
            placeholder="e.g., Interview Invitation"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Subject *</label>
          <input 
            v-model="form.subject"
            type="text"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Body *</label>
          <textarea 
            v-model="form.body"
            required
            rows="15"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          ></textarea>
        </div>

        <!-- Variables -->
        <div class="bg-gray-50 rounded-lg p-4">
          <h4 class="text-sm font-medium text-gray-700 mb-2">Insert Variable</h4>
          <div class="flex flex-wrap gap-2">
            <button 
              v-for="v in variables" 
              :key="v"
              type="button"
              @click="insertVariable(v)"
              class="px-2 py-1 bg-white border border-gray-300 rounded text-xs hover:bg-gray-100 transition"
            >
              {{ v }}
            </button>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Link href="/app/email_templates" class="px-4 py-2 text-gray-700 hover:text-gray-900">Cancel</Link>
          <button 
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            {{ isEditing ? 'Update' : 'Create' }}
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>
