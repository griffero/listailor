<script setup>
import { Link } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'

defineProps({
  templates: Array,
  variables: Array,
  currentUser: Object
})
</script>

<template>
  <AppLayout :currentUser="currentUser">
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Email Templates</h1>
          <p class="text-gray-600">Manage your email templates</p>
        </div>
        <Link 
          href="/app/email_templates/new"
          class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
        >
          Create Template
        </Link>
      </div>

      <!-- Variables Reference -->
      <div class="bg-indigo-50 rounded-lg p-4">
        <h3 class="text-sm font-medium text-indigo-800 mb-2">Available Variables</h3>
        <div class="flex flex-wrap gap-2">
          <code v-for="v in variables" :key="v" class="px-2 py-1 bg-white rounded text-xs text-indigo-700">
            {{ "{{" + v + "}}" }}
          </code>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="template in templates" :key="template.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 font-medium text-gray-900">{{ template.name }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ template.subject }}</td>
              <td class="px-6 py-4 text-right">
                <Link :href="`/app/email_templates/${template.id}/edit`" class="text-indigo-600 hover:text-indigo-800 text-sm mr-4">
                  Edit
                </Link>
                <Link 
                  :href="`/app/email_templates/${template.id}`"
                  method="delete"
                  as="button"
                  class="text-red-600 hover:text-red-800 text-sm"
                  @click="(e) => !confirm('Delete this template?') && e.preventDefault()"
                >
                  Delete
                </Link>
              </td>
            </tr>
            <tr v-if="templates.length === 0">
              <td colspan="3" class="px-6 py-8 text-center text-gray-500">
                No templates yet
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AppLayout>
</template>
