<script setup>
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  settings: Object,
  envSettings: Object,
  globalQuestions: Array,
  currentUser: Object
})

const form = ref({
  outbound_webhook_url: props.settings.outboundWebhookUrl || '',
  n8n_send_email_webhook_url: props.settings.n8nSendEmailWebhookUrl || '',
  embed_allowed_origins: props.settings.embedAllowedOrigins || '',
  departments: props.settings.departments || [],
  locations: props.settings.locations || []
})

const newDepartment = ref('')
const newLocation = ref('')

const newQuestion = ref({
  label: '',
  kind: 'long_text',
  required: false,
  options: ''
})

function submit() {
  router.patch('/app/settings', {
    outbound_webhook_url: form.value.outbound_webhook_url,
    n8n_send_email_webhook_url: form.value.n8n_send_email_webhook_url,
    embed_allowed_origins: form.value.embed_allowed_origins,
    departments: JSON.stringify(form.value.departments),
    locations: JSON.stringify(form.value.locations)
  })
}

function addDepartment() {
  if (!newDepartment.value.trim()) return
  if (form.value.departments.includes(newDepartment.value.trim())) return
  form.value.departments.push(newDepartment.value.trim())
  newDepartment.value = ''
}

function removeDepartment(index) {
  form.value.departments.splice(index, 1)
}

function addLocation() {
  if (!newLocation.value.trim()) return
  if (form.value.locations.includes(newLocation.value.trim())) return
  form.value.locations.push(newLocation.value.trim())
  newLocation.value = ''
}

function removeLocation(index) {
  form.value.locations.splice(index, 1)
}

function addGlobalQuestion() {
  if (!newQuestion.value.label) return
  
  const options = newQuestion.value.kind === 'select' 
    ? newQuestion.value.options.split(',').map(o => o.trim()).filter(Boolean)
    : null

  router.post('/app/global_questions', {
    global_question: {
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

function removeGlobalQuestion(id) {
  if (confirm('Remove this global question?')) {
    router.delete(`/app/global_questions/${id}`, {
      preserveScroll: true
    })
  }
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
        <p class="text-gray-600">Configure your ATS settings</p>
      </div>

      <!-- Departments & Locations -->
      <div class="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 class="text-lg font-semibold text-gray-900">Job Configuration</h2>

        <!-- Departments -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Departments</label>
          <div v-if="form.departments.length > 0" class="flex flex-wrap gap-2 mb-3">
            <span 
              v-for="(dept, index) in form.departments" 
              :key="index"
              class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-indigo-100 text-indigo-800"
            >
              {{ dept }}
              <button @click="removeDepartment(index)" class="ml-2 text-indigo-600 hover:text-indigo-900">
                &times;
              </button>
            </span>
          </div>
          <div class="flex gap-2">
            <input 
              v-model="newDepartment"
              type="text"
              placeholder="Add department..."
              @keyup.enter="addDepartment"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
            <button 
              @click="addDepartment"
              type="button"
              class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
            >
              Add
            </button>
          </div>
        </div>

        <!-- Locations -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Locations</label>
          <div v-if="form.locations.length > 0" class="flex flex-wrap gap-2 mb-3">
            <span 
              v-for="(loc, index) in form.locations" 
              :key="index"
              class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-green-100 text-green-800"
            >
              {{ loc }}
              <button @click="removeLocation(index)" class="ml-2 text-green-600 hover:text-green-900">
                &times;
              </button>
            </span>
          </div>
          <div class="flex gap-2">
            <input 
              v-model="newLocation"
              type="text"
              placeholder="Add location..."
              @keyup.enter="addLocation"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
            <button 
              @click="addLocation"
              type="button"
              class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
            >
              Add
            </button>
          </div>
        </div>

        <div class="flex justify-end pt-4 border-t">
          <button 
            @click="submit"
            type="button"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Save Departments & Locations
          </button>
        </div>
      </div>

      <!-- Global Questions -->
      <div class="bg-white rounded-lg shadow p-6 space-y-6">
        <div>
          <h2 class="text-lg font-semibold text-gray-900">Global Application Questions</h2>
          <p class="text-sm text-gray-500 mt-1">These questions will appear in all job applications</p>
        </div>

        <!-- Existing Global Questions -->
        <div v-if="globalQuestions && globalQuestions.length > 0" class="space-y-3">
          <div v-for="q in globalQuestions" :key="q.id" class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div>
              <span class="font-medium">{{ q.label }}</span>
              <span v-if="q.required" class="text-red-500 ml-1">*</span>
              <span class="text-sm text-gray-500 ml-2">({{ q.kind }})</span>
            </div>
            <button @click="removeGlobalQuestion(q.id)" class="text-red-600 hover:text-red-800 text-sm">
              Remove
            </button>
          </div>
        </div>

        <!-- Add Global Question -->
        <div class="border-t pt-6">
          <h3 class="text-sm font-medium text-gray-700 mb-4">Add Global Question</h3>
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
              @click="addGlobalQuestion"
              type="button"
              class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition"
            >
              Add Global Question
            </button>
          </div>
        </div>
      </div>

      <!-- Webhooks -->
      <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 class="text-lg font-semibold text-gray-900">Webhooks & Integrations</h2>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Outbound Webhook URL</label>
          <input 
            v-model="form.outbound_webhook_url"
            type="url"
            placeholder="https://n8n.example.com/webhook/..."
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
          <p class="text-xs text-gray-500 mt-1">
            Receives POST for new applications.
            <span v-if="envSettings.outboundWebhookUrl" class="text-indigo-600">
              ENV fallback: {{ envSettings.outboundWebhookUrl.substring(0, 50) }}...
            </span>
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">n8n Send Email Webhook URL</label>
          <input 
            v-model="form.n8n_send_email_webhook_url"
            type="url"
            placeholder="https://n8n.example.com/webhook/..."
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
          <p class="text-xs text-gray-500 mt-1">
            n8n will receive email send requests here.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Embed Allowed Origins</label>
          <input 
            v-model="form.embed_allowed_origins"
            type="text"
            placeholder="https://fintoc.com,https://www.fintoc.com"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
          <p class="text-xs text-gray-500 mt-1">
            Comma-separated list of origins allowed to embed the jobs widget.
          </p>
        </div>

        <div class="flex justify-end pt-4">
          <button 
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Save Settings
          </button>
        </div>
      </form>

      <!-- API Info -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">API Information</h2>
        <div class="space-y-4 text-sm">
          <div>
            <h3 class="font-medium text-gray-700">API Base URL</h3>
            <code class="text-gray-600">/api/v1</code>
          </div>
          <div>
            <h3 class="font-medium text-gray-700">Authentication</h3>
            <p class="text-gray-600">Bearer token via <code>N8N_API_TOKEN</code> environment variable</p>
            <code class="block mt-1 p-2 bg-gray-100 rounded">Authorization: Bearer YOUR_TOKEN</code>
          </div>
          <div>
            <h3 class="font-medium text-gray-700">Available Endpoints</h3>
            <ul class="list-disc list-inside text-gray-600 space-y-1 mt-2">
              <li><code>POST /api/v1/application_events</code> - Create timeline events</li>
              <li><code>POST /api/v1/email_messages</code> - Upsert email messages</li>
              <li><code>POST /api/v1/interviews</code> - Create interview events</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
