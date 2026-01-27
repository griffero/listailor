<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { UiCard, UiBadge, UiButton, UiSelect } from '@/components/ui'

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
  const icons = {
    application_created: '📥',
    stage_change: '➡️',
    email_sent: '📤',
    email_received: '📩',
    interview: '📅',
    note: '📝'
  }
  return icons[type] || '•'
}

function formatDirection(direction) {
  return direction === 'inbound' ? 'Inbound' : 'Outbound'
}

function answerLink(value) {
  if (!value || typeof value !== 'string') return null
  const trimmed = value.trim()
  if (/^https?:\/\//i.test(trimmed)) return trimmed
  if (/^www\./i.test(trimmed)) return `https://${trimmed}`
  return null
}

function formatWorkDate(dateStr) {
  if (!dateStr) return ''
  if (/^\d{4}-\d{2}$/.test(dateStr)) {
    const [year, month] = dateStr.split('-')
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    return `${monthNames[parseInt(month) - 1]} ${year}`
  }
  if (/^\d{4}$/.test(dateStr)) {
    return dateStr
  }
  return dateStr
}

function getInitials(name) {
  return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
}
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <Link href="/app/applications" class="inline-flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 mb-3 transition-colors">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Back to Applications
          </Link>
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 bg-zinc-100 rounded-full flex items-center justify-center">
              <span class="text-lg font-medium text-zinc-600">{{ getInitials(application.candidate.name) }}</span>
            </div>
            <div>
              <h1 class="text-2xl font-semibold text-zinc-900">{{ application.candidate.name }}</h1>
              <div class="text-zinc-500 font-mono text-sm">{{ application.candidate.email }}</div>
            </div>
          </div>
        </div>
        <UiButton :href="`/app/applications/${application.id}/emails/new`">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
          Send Email
        </UiButton>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Stage Selector -->
          <UiCard>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-base font-semibold text-zinc-900">Current Stage</h2>
              <UiBadge 
                v-if="application.stage"
                :variant="application.stage.kind === 'hired' ? 'success' : application.stage.kind === 'rejected' ? 'danger' : 'default'"
              >
                {{ application.stage.name }}
              </UiBadge>
            </div>
            <div class="flex items-center gap-3">
              <div class="flex-1">
                <UiSelect v-model="selectedStage">
                  <option v-for="stage in stages" :key="stage.id" :value="stage.id">
                    {{ stage.name }}
                  </option>
                </UiSelect>
              </div>
              <UiButton 
                @click="moveStage"
                :disabled="selectedStage === application.stage?.id"
              >
                Move
              </UiButton>
            </div>
          </UiCard>

          <!-- Timeline -->
          <UiCard padding="none">
            <div class="px-6 py-4 border-b border-zinc-100">
              <h2 class="text-base font-semibold text-zinc-900">Timeline</h2>
            </div>
            <div class="p-6">
              <div v-if="timeline.length > 0" class="space-y-4">
                <div v-for="(item, index) in timeline" :key="index" class="flex gap-3">
                  <div class="text-lg">{{ getTimelineIcon(item.type) }}</div>
                  <div class="flex-1 min-w-0">
                    <div class="text-sm text-zinc-900">{{ item.message }}</div>
                    <div class="text-xs text-zinc-400 font-mono mt-0.5">{{ formatDate(item.occurred_at) }}</div>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-8 text-zinc-500 text-sm">
                No timeline events yet
              </div>
            </div>
          </UiCard>

          <!-- Messages -->
          <UiCard padding="none">
            <div class="px-6 py-4 border-b border-zinc-100">
              <h2 class="text-base font-semibold text-zinc-900">Messages</h2>
            </div>
            <div class="p-6">
              <div v-if="application.emails && application.emails.length > 0" class="space-y-4">
                <div v-for="email in application.emails" :key="email.id" class="border border-zinc-200 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-3">
                    <UiBadge :variant="email.direction === 'inbound' ? 'info' : 'default'" size="sm">
                      {{ formatDirection(email.direction) }}
                    </UiBadge>
                    <span class="text-xs text-zinc-400 font-mono">
                      {{ formatDate(email.sentAt || email.receivedAt) }}
                    </span>
                  </div>
                  <div class="text-xs text-zinc-500 space-y-1 mb-3">
                    <div><span class="font-medium">From:</span> {{ email.from }}</div>
                    <div><span class="font-medium">To:</span> {{ email.to }}</div>
                  </div>
                  <div class="font-medium text-zinc-900 mb-2">{{ email.subject }}</div>
                  <div class="text-sm text-zinc-600 whitespace-pre-wrap" v-html="email.body"></div>
                </div>
              </div>
              <div v-else class="text-center py-8 text-zinc-500 text-sm">
                No messages yet
              </div>
            </div>
          </UiCard>

          <!-- Add Note -->
          <UiCard>
            <h2 class="text-base font-semibold text-zinc-900 mb-4">Add Note</h2>
            <div class="space-y-4">
              <textarea 
                v-model="newNote"
                rows="3"
                placeholder="Write a note..."
                class="w-full px-3 py-2 text-sm border border-zinc-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-900 transition-colors resize-none"
              ></textarea>
              <UiButton 
                @click="addNote"
                :disabled="!newNote.trim()"
                variant="secondary"
              >
                Add Note
              </UiButton>
            </div>
          </UiCard>

          <!-- Answers -->
          <UiCard v-if="application.answers && application.answers.length > 0" padding="none">
            <div class="px-6 py-4 border-b border-zinc-100">
              <h2 class="text-base font-semibold text-zinc-900">Application Answers</h2>
            </div>
            <div class="divide-y divide-zinc-100">
              <div v-for="answer in application.answers" :key="answer.question" class="px-6 py-4">
                <div class="text-sm font-medium text-zinc-700 mb-1">{{ answer.question }}</div>
                <div class="text-sm text-zinc-600">
                  <a
                    v-if="answerLink(answer.value)"
                    :href="answerLink(answer.value)"
                    target="_blank"
                    rel="noopener"
                    class="text-zinc-900 underline decoration-zinc-300 hover:decoration-zinc-900 transition-colors"
                  >
                    {{ answer.value }}
                  </a>
                  <span v-else>{{ answer.value || '—' }}</span>
                </div>
              </div>
            </div>
          </UiCard>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Candidate Info -->
          <UiCard>
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Candidate</h3>
            <div class="space-y-3 text-sm">
              <div>
                <span class="text-zinc-500 text-xs uppercase tracking-wide">Name</span>
                <div class="font-medium text-zinc-900 mt-0.5">{{ application.candidate.name }}</div>
              </div>
              <div>
                <span class="text-zinc-500 text-xs uppercase tracking-wide">Email</span>
                <div class="font-mono text-zinc-900 mt-0.5">{{ application.candidate.email }}</div>
              </div>
              <div v-if="application.candidate.phone">
                <span class="text-zinc-500 text-xs uppercase tracking-wide">Phone</span>
                <div class="font-mono text-zinc-900 mt-0.5">{{ application.candidate.phone }}</div>
              </div>
              <div v-if="application.candidate.linkedinUrl">
                <span class="text-zinc-500 text-xs uppercase tracking-wide">LinkedIn</span>
                <div class="mt-0.5">
                  <a :href="application.candidate.linkedinUrl" target="_blank" class="text-zinc-900 underline decoration-zinc-300 hover:decoration-zinc-900 transition-colors">
                    View Profile
                  </a>
                </div>
              </div>
            </div>
          </UiCard>

          <!-- Job Info -->
          <UiCard>
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Job</h3>
            <Link :href="`/app/jobs/${application.job.id}`" class="text-zinc-900 underline decoration-zinc-300 hover:decoration-zinc-900 transition-colors">
              {{ application.job.title }}
            </Link>
          </UiCard>

          <!-- Source -->
          <UiCard>
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Source</h3>
            <div class="text-sm space-y-1">
              <div v-if="application.source" class="text-zinc-900">{{ application.source }}</div>
              <div v-if="application.utmSource" class="text-zinc-500 font-mono text-xs">
                UTM: {{ application.utmSource }}
              </div>
              <div v-if="!application.source && !application.utmSource" class="text-zinc-400">—</div>
            </div>
          </UiCard>

          <!-- Insights -->
          <UiCard v-if="application.hasStartupExperience || application.hasYearTenure || application.hasPersonalProjects || (application.cvUrl && !application.processingCompleted)">
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Insights</h3>
            
            <div v-if="application.cvUrl && !application.processingCompleted && !application.hasStartupExperience && !application.hasYearTenure && !application.hasPersonalProjects" class="flex items-center gap-2 text-sm text-zinc-500">
              <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Extracting from CV...
            </div>
            
            <div v-else class="space-y-2">
              <div v-if="application.hasStartupExperience" class="flex items-center gap-2 text-sm">
                <span class="inline-flex items-center justify-center w-6 h-6 rounded bg-violet-100 text-violet-600">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </span>
                <span class="text-zinc-700">Experiencia en startups</span>
              </div>
              <div v-if="application.hasYearTenure" class="flex items-center gap-2 text-sm">
                <span class="inline-flex items-center justify-center w-6 h-6 rounded bg-emerald-100 text-emerald-600">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </span>
                <span class="text-zinc-700">+1 año en algún rol</span>
              </div>
              <div v-if="application.hasPersonalProjects" class="flex items-center gap-2 text-sm">
                <span class="inline-flex items-center justify-center w-6 h-6 rounded bg-amber-100 text-amber-600">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </span>
                <span class="text-zinc-700">Proyectos propios</span>
              </div>
              <div v-if="!application.hasStartupExperience && !application.hasYearTenure && !application.hasPersonalProjects && application.processingCompleted" class="text-zinc-400 text-sm italic">
                No insights detected
              </div>
            </div>
          </UiCard>

          <!-- CV -->
          <UiCard v-if="application.cvUrl">
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Resume</h3>
            <a 
              :href="application.cvUrl" 
              target="_blank" 
              class="inline-flex items-center gap-2 px-4 py-2 bg-zinc-900 text-white rounded-lg hover:bg-zinc-800 transition-colors text-sm font-medium"
            >
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Download CV
            </a>
          </UiCard>

          <!-- Education -->
          <UiCard v-if="application.education || (application.cvUrl && !application.processingCompleted)">
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Education</h3>
            
            <div v-if="application.cvUrl && !application.processingCompleted && !application.education" class="flex items-center gap-2 text-sm text-zinc-500">
              <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Extracting from CV...
            </div>
            
            <div v-else-if="application.education" class="space-y-4 text-sm">
              <div v-if="application.education.university">
                <span class="text-zinc-500 text-xs uppercase tracking-wide">University</span>
                <div class="font-medium text-zinc-900 mt-0.5">{{ application.education.university.name }}</div>
                <div v-if="application.education.university.degree" class="text-zinc-600 text-sm">
                  {{ application.education.university.degree }}
                </div>
                <div v-if="application.education.university.graduation_year" class="text-zinc-400 text-xs font-mono">
                  {{ application.education.university.graduation_year }}
                </div>
              </div>
              
              <div v-if="application.education.school">
                <span class="text-zinc-500 text-xs uppercase tracking-wide">School</span>
                <div class="font-medium text-zinc-900 mt-0.5">{{ application.education.school.name }}</div>
              </div>
              
              <div v-if="!application.education.university && !application.education.school" class="text-zinc-400 italic">
                No education found
              </div>
            </div>
          </UiCard>

          <!-- Work Experience -->
          <UiCard v-if="application.workExperience?.length > 0 || (application.cvUrl && !application.processingCompleted)">
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Work Experience</h3>
            
            <div v-if="application.cvUrl && !application.processingCompleted && !application.workExperience?.length" class="flex items-center gap-2 text-sm text-zinc-500">
              <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Extracting from CV...
            </div>
            
            <div v-else-if="application.workExperience?.length > 0" class="space-y-3">
              <div v-for="(job, index) in application.workExperience" :key="index" class="pb-3 border-b border-zinc-100 last:border-0 last:pb-0">
                <div class="font-medium text-zinc-900 text-sm">{{ job.company_normalized || job.company }}</div>
                <div v-if="job.position" class="text-zinc-600 text-sm">{{ job.position }}</div>
                <div class="text-zinc-400 text-xs font-mono mt-1">
                  {{ formatWorkDate(job.start_date) }} - {{ job.is_current ? 'Present' : formatWorkDate(job.end_date) }}
                </div>
              </div>
            </div>
            
            <div v-else class="text-zinc-400 italic text-sm">
              No work experience found
            </div>
          </UiCard>

          <!-- Interviews -->
          <UiCard v-if="application.interviews && application.interviews.length > 0">
            <h3 class="text-sm font-semibold text-zinc-900 mb-4">Interviews</h3>
            <div class="space-y-3">
              <div v-for="interview in application.interviews" :key="interview.id" class="text-sm">
                <div class="font-medium text-zinc-900">{{ interview.title }}</div>
                <div class="text-zinc-500 font-mono text-xs">{{ formatDate(interview.scheduledAt) }}</div>
                <a v-if="interview.meetingUrl" :href="interview.meetingUrl" target="_blank" class="text-zinc-900 underline decoration-zinc-300 hover:decoration-zinc-900 transition-colors text-xs">
                  Join Meeting
                </a>
              </div>
            </div>
          </UiCard>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
