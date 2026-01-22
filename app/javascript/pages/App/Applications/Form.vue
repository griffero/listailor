<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  jobs: Array,
  currentUser: Object
})

const form = ref({
  job_posting_id: '',
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  linkedin_url: '',
  source: 'manual',
  notes: '',
  cv: null
})

function submit() {
  const formData = new FormData()
  
  Object.keys(form.value).forEach(key => {
    if (form.value[key] !== null && form.value[key] !== '') {
      formData.append(`application[${key}]`, form.value[key])
    }
  })

  router.post('/app/applications', formData, {
    forceFormData: true
  })
}

function handleFileChange(e) {
  form.value.cv = e.target.files[0]
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="max-w-2xl mx-auto space-y-6">
      <div>
        <Link href="/app/applications" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
          ← Back to Applications
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">Add Application Manually</h1>
        <p class="text-gray-600">Create an application for an existing or new candidate</p>
      </div>

      <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <!-- Job Selection -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Job Posting *</label>
          <select 
            v-model="form.job_posting_id"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">Select a job...</option>
            <option v-for="job in jobs" :key="job.id" :value="job.id">{{ job.title }}</option>
          </select>
        </div>

        <!-- Candidate Info -->
        <div class="border-t pt-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Candidate Information</h3>
          
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
              <input 
                v-model="form.first_name"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Last Name *</label>
              <input 
                v-model="form.last_name"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
            </div>
          </div>

          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Email *</label>
            <input 
              v-model="form.email"
              type="email"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
            <p class="text-xs text-gray-500 mt-1">If email exists, this will link to existing candidate</p>
          </div>

          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input 
              v-model="form.phone"
              type="tel"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
          </div>

          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">LinkedIn URL</label>
            <input 
              v-model="form.linkedin_url"
              type="url"
              placeholder="https://linkedin.com/in/..."
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
          </div>
        </div>

        <!-- CV Upload -->
        <div class="border-t pt-6">
          <label class="block text-sm font-medium text-gray-700 mb-1">CV / Resume</label>
          <input 
            type="file"
            @change="handleFileChange"
            accept=".pdf,.doc,.docx"
            class="w-full"
          >
          <p class="text-xs text-gray-500 mt-1">PDF, DOC, or DOCX</p>
        </div>

        <!-- Source -->
        <div class="border-t pt-6">
          <label class="block text-sm font-medium text-gray-700 mb-1">Source</label>
          <input 
            v-model="form.source"
            type="text"
            placeholder="e.g., Referral, LinkedIn, Manual"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
        </div>

        <!-- Notes -->
        <div class="border-t pt-6">
          <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
          <textarea 
            v-model="form.notes"
            rows="4"
            placeholder="Any initial notes about this candidate..."
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          ></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Link href="/app/applications" class="px-4 py-2 text-gray-700 hover:text-gray-900">Cancel</Link>
          <button 
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
          >
            Create Application
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>
