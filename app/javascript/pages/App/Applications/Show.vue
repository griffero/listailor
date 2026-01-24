<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

const props = defineProps({
  application: Object,
  stages: Array,
  emailTemplates: Array,
  timeline: Array,
  currentUser: Object
})

const newNote = ref('')
const selectedStage = ref(props.application.stage?.id)

function moveStage() {
  if (!selectedStage.value || selectedStage.value === props.application.stage?.id) return
  
  router.post(`/app/applications/${props.application.id}/move_stage`, {
    stage_id: selectedStage.value
  })
}

function addNote() {
  if (!newNote.value.trim()) return
  
  router.post(`/app/applications/${props.application.id}/notes`, {
    message: newNote.value
  }, {
    preserveScroll: true,
    onSuccess: () => {
      newNote.value = ''
    }
  })
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function getTimelineIcon(type) {
  switch (type) {
    case 'application_created': return '📥'
    case 'stage_change': return '➡️'
    case 'email_sent': return '📤'
    case 'email_received': return '📩'
    case 'interview': return '📅'
    case 'note': return '📝'
    default: return '•'
  }
}

function formatDirection(direction) {
  return direction === 'inbound' ? 'Inbound' : 'Outbound'
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-start">
        <div>
          <Link href="/app/applications" class="text-sm text-indigo-600 hover:text-indigo-800 mb-2 inline-block">
            ← Back to Applications
          </Link>
          <h1 class="text-2xl font-bold text-gray-900">{{ application.candidate.name }}</h1>
          <div class="text-gray-600">{{ application.candidate.email }}</div>
        </div>
        <Link 
          :href="`/app/applications/${application.id}/emails/new`"
          class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
        >
          Send Email
        </Link>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Stage Selector -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Current Stage</h2>
            <div class="flex items-center gap-4">
              <select 
                v-model="selectedStage"
                class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option v-for="stage in stages" :key="stage.id" :value="stage.id">
                  {{ stage.name }}
                </option>
              </select>
              <button 
                @click="moveStage"
                :disabled="selectedStage === application.stage?.id"
                class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Move
              </button>
            </div>
          </div>

          <!-- Timeline -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Timeline</h2>
            <div class="space-y-4">
              <div v-for="(item, index) in timeline" :key="index" class="flex gap-3">
                <div class="text-lg">{{ getTimelineIcon(item.type) }}</div>
                <div class="flex-1">
                  <div class="font-medium text-gray-900">{{ item.message }}</div>
                  <div class="text-sm text-gray-500">{{ formatDate(item.occurred_at) }}</div>
                </div>
              </div>
              <div v-if="timeline.length === 0" class="text-gray-500 text-center py-4">
                No timeline events yet
              </div>
            </div>
          </div>

          <!-- Messages -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Messages</h2>
            <div v-if="application.emails && application.emails.length > 0" class="space-y-4">
              <div v-for="email in application.emails" :key="email.id" class="border border-gray-100 rounded-lg p-4">
                <div class="flex items-center justify-between mb-2">
                  <div class="text-sm font-medium text-gray-700">
                    {{ formatDirection(email.direction) }}
                  </div>
                  <div class="text-xs text-gray-500">
                    {{ formatDate(email.sentAt || email.receivedAt) }}
                  </div>
                </div>
                <div class="text-sm text-gray-600 mb-1">
                  <span class="font-medium text-gray-700">From:</span> {{ email.from }}
                </div>
                <div class="text-sm text-gray-600 mb-3">
                  <span class="font-medium text-gray-700">To:</span> {{ email.to }}
                </div>
                <div class="font-medium text-gray-900 mb-2">{{ email.subject }}</div>
                <div class="text-sm text-gray-700 whitespace-pre-wrap" v-html="email.body"></div>
              </div>
            </div>
            <div v-else class="text-gray-500 text-center py-4">
              No messages yet
            </div>
          </div>

          <!-- Add Note -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Add Note</h2>
            <div class="space-y-4">
              <textarea 
                v-model="newNote"
                rows="3"
                placeholder="Write a note..."
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              ></textarea>
              <button 
                @click="addNote"
                :disabled="!newNote.trim()"
                class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition disabled:opacity-50"
              >
                Add Note
              </button>
            </div>
          </div>

          <!-- Answers -->
          <div v-if="application.answers && application.answers.length > 0" class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Application Answers</h2>
            <div class="space-y-4">
              <div v-for="answer in application.answers" :key="answer.question" class="border-b border-gray-100 pb-4 last:border-0">
                <div class="font-medium text-gray-700">{{ answer.question }}</div>
                <div class="text-gray-600 mt-1 whitespace-pre-wrap">{{ answer.value || '—' }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Candidate Info -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Candidate</h3>
            <div class="space-y-3 text-sm">
              <div>
                <span class="text-gray-500">Name</span>
                <div class="font-medium">{{ application.candidate.name }}</div>
              </div>
              <div>
                <span class="text-gray-500">Email</span>
                <div class="font-medium">{{ application.candidate.email }}</div>
              </div>
              <div v-if="application.candidate.phone">
                <span class="text-gray-500">Phone</span>
                <div class="font-medium">{{ application.candidate.phone }}</div>
              </div>
              <div v-if="application.candidate.linkedinUrl">
                <span class="text-gray-500">LinkedIn</span>
                <div>
                  <a :href="application.candidate.linkedinUrl" target="_blank" class="text-indigo-600 hover:text-indigo-800">
                    View Profile
                  </a>
                </div>
              </div>
            </div>
          </div>

          <!-- Job Info -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Job</h3>
            <Link :href="`/app/jobs/${application.job.id}`" class="text-indigo-600 hover:text-indigo-800">
              {{ application.job.title }}
            </Link>
          </div>

          <!-- Source -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Source</h3>
            <div class="text-sm space-y-2">
              <div v-if="application.source">{{ application.source }}</div>
              <div v-if="application.utmSource" class="text-gray-500">
                UTM: {{ application.utmSource }}
              </div>
            </div>
          </div>

          <!-- CV -->
          <div v-if="application.cvUrl" class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Resume</h3>
            <a :href="application.cvUrl" target="_blank" class="text-indigo-600 hover:text-indigo-800">
              Download CV
            </a>
          </div>

          <!-- Interviews -->
          <div v-if="application.interviews && application.interviews.length > 0" class="bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">Interviews</h3>
            <div class="space-y-3">
              <div v-for="interview in application.interviews" :key="interview.id" class="text-sm">
                <div class="font-medium">{{ interview.title }}</div>
                <div class="text-gray-500">{{ formatDate(interview.scheduledAt) }}</div>
                <a v-if="interview.meetingUrl" :href="interview.meetingUrl" target="_blank" class="text-indigo-600 hover:text-indigo-800">
                  Join Meeting
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
