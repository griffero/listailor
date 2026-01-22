<script setup>
import { ref, watch } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  application: Object,
  templates: Array,
  currentUser: Object
})

const selectedTemplateId = ref('')
const subject = ref('')
const body = ref('')

watch(selectedTemplateId, (newId) => {
  if (newId) {
    const template = props.templates.find(t => t.id === parseInt(newId))
    if (template) {
      subject.value = template.subject
      body.value = template.body
    }
  }
})

function send() {
  router.post(`/app/applications/${props.application.id}/emails`, {
    template_id: selectedTemplateId.value || undefined,
    subject: subject.value,
    body: body.value
  })
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-3xl mx-auto space-y-6">
      <div>
        <Link :href="`/app/applications/${application.id}`" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
          ← Back to Application
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">Send Email</h1>
        <p class="text-gray-600">To: {{ application.candidate.name }} ({{ application.candidate.email }})</p>
      </div>

      <form @submit.prevent="send" class="bg-white rounded-lg shadow p-6 space-y-6">
        <!-- Template Selection -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Use Template</label>
          <select 
            v-model="selectedTemplateId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">No template (write from scratch)</option>
            <option v-for="template in templates" :key="template.id" :value="template.id">
              {{ template.name }}
            </option>
          </select>
          <p class="text-xs text-gray-500 mt-1">Variables will be replaced automatically</p>
        </div>

        <!-- Subject -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Subject *</label>
          <input 
            v-model="subject"
            type="text"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
        </div>

        <!-- Body -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Message *</label>
          <textarea 
            v-model="body"
            required
            rows="12"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 font-mono text-sm"
          ></textarea>
        </div>

        <!-- Context Info -->
        <div class="bg-gray-50 rounded-lg p-4 text-sm">
          <h4 class="font-medium text-gray-700 mb-2">Available Variables</h4>
          <div class="grid grid-cols-2 gap-2 text-gray-600">
            <code>{{ "{{candidate.first_name}}" }}</code>
            <code>{{ "{{candidate.last_name}}" }}</code>
            <code>{{ "{{job.title}}" }}</code>
            <code>{{ "{{stage.name}}" }}</code>
            <code>{{ "{{application.url}}" }}</code>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Link :href="`/app/applications/${application.id}`" class="px-4 py-2 text-gray-700 hover:text-gray-900">
            Cancel
          </Link>
          <button 
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Send Email
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>
