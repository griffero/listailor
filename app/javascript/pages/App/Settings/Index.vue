<script setup>
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  settings: Object,
  envSettings: Object,
  currentUser: Object
})

const form = ref({
  outbound_webhook_url: props.settings.outboundWebhookUrl || '',
  n8n_send_email_webhook_url: props.settings.n8nSendEmailWebhookUrl || '',
  embed_allowed_origins: props.settings.embedAllowedOrigins || ''
})

function submit() {
  router.patch('/app/settings', form.value)
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
        <p class="text-gray-600">Configure your ATS settings</p>
      </div>

      <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-6">
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
