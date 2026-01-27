<script setup>
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiPageHeader, UiBadge, UiButton, UiInput, UiSelect } from '@/components/ui'

const props = defineProps({
  settings: Object,
  envSettings: Object,
  globalQuestions: Array,
  members: Array,
  currentUser: Object,
  defaultCoverLetterPrompt: String
})

function formatDate(dateStr) {
  if (!dateStr) return 'Never'
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

function formatDateTime(dateStr) {
  if (!dateStr) return 'Never'
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const form = ref({
  outbound_webhook_url: props.settings.outboundWebhookUrl || '',
  n8n_send_email_webhook_url: props.settings.n8nSendEmailWebhookUrl || '',
  embed_allowed_origins: props.settings.embedAllowedOrigins || '',
  cover_letter_evaluation_prompt: props.settings.coverLetterEvaluationPrompt || '',
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
    cover_letter_evaluation_prompt: form.value.cover_letter_evaluation_prompt,
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
    <div class="max-w-3xl mx-auto space-y-8">
      <UiPageHeader 
        title="Settings" 
        description="Configure your ATS settings"
      />

      <!-- Team Members -->
      <UiCard>
        <div class="flex items-center justify-between mb-6">
          <div>
            <h2 class="text-base font-semibold text-zinc-900">Team Members</h2>
            <p class="text-sm text-zinc-500 mt-1">People with @fintoc.com accounts who have signed in</p>
          </div>
          <UiBadge variant="outline">{{ members.length }} members</UiBadge>
        </div>

        <div class="divide-y divide-zinc-100">
          <div 
            v-for="member in members" 
            :key="member.id"
            class="flex items-center justify-between py-3 first:pt-0 last:pb-0"
          >
            <div class="flex items-center gap-3">
              <div class="w-9 h-9 rounded-full bg-zinc-100 flex items-center justify-center">
                <span class="text-sm font-medium text-zinc-600">
                  {{ member.email.charAt(0).toUpperCase() }}
                </span>
              </div>
              <div>
                <div class="font-medium text-zinc-900 text-sm">{{ member.email }}</div>
                <div class="text-xs text-zinc-400 font-mono">
                  Joined {{ formatDate(member.createdAt) }}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-xs text-zinc-500">Last active</div>
              <div class="text-xs text-zinc-400 font-mono">
                {{ member.lastSignedInAt ? formatDateTime(member.lastSignedInAt) : 'Never' }}
              </div>
            </div>
          </div>
        </div>

        <div v-if="members.length === 0" class="text-center py-8 text-zinc-500 text-sm">
          No team members yet
        </div>
      </UiCard>

      <!-- Departments & Locations -->
      <UiCard>
        <h2 class="text-base font-semibold text-zinc-900 mb-6">Job Configuration</h2>

        <!-- Departments -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-zinc-700 mb-2">Departments</label>
          <div v-if="form.departments.length > 0" class="flex flex-wrap gap-2 mb-3">
            <span 
              v-for="(dept, index) in form.departments" 
              :key="index"
              class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-zinc-100 text-zinc-700"
            >
              {{ dept }}
              <button @click="removeDepartment(index)" class="ml-2 text-zinc-500 hover:text-zinc-900 transition-colors">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </span>
          </div>
          <div class="flex gap-2">
            <input 
              v-model="newDepartment"
              type="text"
              placeholder="Add department..."
              @keyup.enter="addDepartment"
              class="flex-1 px-3 py-2 text-sm border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-900 transition-colors"
            >
            <UiButton @click="addDepartment" variant="secondary">Add</UiButton>
          </div>
        </div>

        <!-- Locations -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-zinc-700 mb-2">Locations</label>
          <div v-if="form.locations.length > 0" class="flex flex-wrap gap-2 mb-3">
            <span 
              v-for="(loc, index) in form.locations" 
              :key="index"
              class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-emerald-50 text-emerald-700"
            >
              {{ loc }}
              <button @click="removeLocation(index)" class="ml-2 text-emerald-600 hover:text-emerald-900 transition-colors">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </span>
          </div>
          <div class="flex gap-2">
            <input 
              v-model="newLocation"
              type="text"
              placeholder="Add location..."
              @keyup.enter="addLocation"
              class="flex-1 px-3 py-2 text-sm border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-900 transition-colors"
            >
            <UiButton @click="addLocation" variant="secondary">Add</UiButton>
          </div>
        </div>

        <div class="flex justify-end pt-4 border-t border-zinc-100">
          <UiButton @click="submit">Save Departments & Locations</UiButton>
        </div>
      </UiCard>

      <!-- Global Questions -->
      <UiCard>
        <div class="mb-6">
          <h2 class="text-base font-semibold text-zinc-900">Global Application Questions</h2>
          <p class="text-sm text-zinc-500 mt-1">These questions will appear in all job applications</p>
        </div>

        <!-- Existing Global Questions -->
        <div v-if="globalQuestions && globalQuestions.length > 0" class="space-y-2 mb-6">
          <div v-for="q in globalQuestions" :key="q.id" class="flex items-center justify-between p-3 bg-zinc-50 rounded-lg">
            <div class="flex items-center gap-2">
              <span class="font-medium text-zinc-900">{{ q.label }}</span>
              <UiBadge v-if="q.required" variant="danger" size="sm">Required</UiBadge>
              <UiBadge variant="outline" size="sm">{{ q.kind }}</UiBadge>
            </div>
            <button @click="removeGlobalQuestion(q.id)" class="text-zinc-400 hover:text-red-600 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Add Global Question -->
        <div class="border-t border-zinc-100 pt-6">
          <h3 class="text-sm font-medium text-zinc-700 mb-4">Add Global Question</h3>
          <div class="space-y-4">
            <UiInput 
              v-model="newQuestion.label"
              placeholder="Question text"
            />
            <div class="grid grid-cols-2 gap-4">
              <UiSelect v-model="newQuestion.kind">
                <option value="long_text">Long Text</option>
                <option value="short_text">Short Text</option>
                <option value="number">Number</option>
                <option value="checkbox">Checkbox</option>
                <option value="select">Select</option>
              </UiSelect>
              <div class="flex items-center">
                <label class="flex items-center cursor-pointer">
                  <input type="checkbox" v-model="newQuestion.required" class="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900">
                  <span class="ml-2 text-sm text-zinc-700">Required</span>
                </label>
              </div>
            </div>
            <UiInput 
              v-if="newQuestion.kind === 'select'"
              v-model="newQuestion.options"
              placeholder="Options (comma separated)"
            />
            <UiButton @click="addGlobalQuestion" variant="secondary">
              Add Global Question
            </UiButton>
          </div>
        </div>
      </UiCard>

      <!-- AI Configuration -->
      <UiCard>
        <div class="mb-6">
          <h2 class="text-base font-semibold text-zinc-900">AI Cover Letter Evaluation</h2>
          <p class="text-sm text-zinc-500 mt-1">Customize the prompt used to evaluate cover letters</p>
        </div>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-zinc-700 mb-2">Evaluation Prompt</label>
            <textarea 
              v-model="form.cover_letter_evaluation_prompt"
              rows="12"
              :placeholder="defaultCoverLetterPrompt"
              class="w-full px-3 py-2 text-sm border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-900 transition-colors resize-none font-mono"
            ></textarea>
            <p class="mt-2 text-xs text-zinc-500">
              Leave empty to use the default prompt. The cover letter text will be appended after your prompt.
            </p>
          </div>
          
          <div class="flex items-center justify-between pt-4 border-t border-zinc-100">
            <button 
              @click="form.cover_letter_evaluation_prompt = ''"
              class="text-sm text-zinc-500 hover:text-zinc-700 transition-colors"
            >
              Reset to default
            </button>
            <UiButton @click="submit">Save Prompt</UiButton>
          </div>
        </div>
      </UiCard>

      <!-- Webhooks -->
      <UiCard>
        <h2 class="text-base font-semibold text-zinc-900 mb-6">Webhooks & Integrations</h2>

        <div class="space-y-6">
          <div>
            <UiInput 
              v-model="form.outbound_webhook_url"
              label="Outbound Webhook URL"
              placeholder="https://n8n.example.com/webhook/..."
              :hint="envSettings.outboundWebhookUrl ? `ENV fallback: ${envSettings.outboundWebhookUrl.substring(0, 50)}...` : 'Receives POST for new applications'"
            />
          </div>

          <div>
            <UiInput 
              v-model="form.n8n_send_email_webhook_url"
              label="n8n Send Email Webhook URL"
              placeholder="https://n8n.example.com/webhook/..."
              hint="n8n will receive email send requests here"
            />
          </div>

          <div>
            <UiInput 
              v-model="form.embed_allowed_origins"
              label="Embed Allowed Origins"
              placeholder="https://fintoc.com,https://www.fintoc.com"
              hint="Comma-separated list of origins allowed to embed the jobs widget"
            />
          </div>

          <div class="flex justify-end pt-4 border-t border-zinc-100">
            <UiButton @click="submit">Save Settings</UiButton>
          </div>
        </div>
      </UiCard>

      <!-- API Info -->
      <UiCard>
        <h2 class="text-base font-semibold text-zinc-900 mb-6">API Information</h2>
        <div class="space-y-6 text-sm">
          <div>
            <h3 class="font-medium text-zinc-700 mb-1">API Base URL</h3>
            <code class="px-2 py-1 bg-zinc-100 rounded text-zinc-800 font-mono text-xs">/api/v1</code>
          </div>
          <div>
            <h3 class="font-medium text-zinc-700 mb-2">Authentication</h3>
            <p class="text-zinc-600 mb-2">Bearer token via <code class="px-1.5 py-0.5 bg-zinc-100 rounded font-mono text-xs">N8N_API_TOKEN</code> environment variable</p>
            <div class="bg-zinc-900 rounded-lg p-3 font-mono text-xs text-zinc-300">
              Authorization: Bearer YOUR_TOKEN
            </div>
          </div>
          <div>
            <h3 class="font-medium text-zinc-700 mb-2">Available Endpoints</h3>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <UiBadge variant="success" size="sm">POST</UiBadge>
                <code class="font-mono text-xs text-zinc-600">/api/v1/application_events</code>
                <span class="text-xs text-zinc-400">Create timeline events</span>
              </div>
              <div class="flex items-center gap-2">
                <UiBadge variant="success" size="sm">POST</UiBadge>
                <code class="font-mono text-xs text-zinc-600">/api/v1/email_messages</code>
                <span class="text-xs text-zinc-400">Upsert email messages</span>
              </div>
              <div class="flex items-center gap-2">
                <UiBadge variant="success" size="sm">POST</UiBadge>
                <code class="font-mono text-xs text-zinc-600">/api/v1/interviews</code>
                <span class="text-xs text-zinc-400">Create interview events</span>
              </div>
            </div>
          </div>
        </div>
      </UiCard>
    </div>
  </AppLayout>
</template>
