<script setup>
import { Link } from '@inertiajs/vue3'

defineProps({
  currentUser: Object
})
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <!-- Navigation -->
    <nav class="bg-white border-b border-slate-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <Link href="/app" class="text-xl font-bold text-indigo-600">
                Listailor
              </Link>
            </div>
            <div class="hidden sm:ml-8 sm:flex sm:space-x-6">
              <Link
                href="/app/pipeline"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Pipeline
              </Link>
              <Link
                href="/app/jobs"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Jobs
              </Link>
              <Link
                href="/app/applications"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Applications
              </Link>
              <Link
                href="/app/email_templates"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Templates
              </Link>
              <Link
                href="/app/reports"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Reports
              </Link>
              <Link
                href="/app/settings"
                class="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-slate-600 hover:text-slate-900 hover:border-slate-300"
              >
                Settings
              </Link>
            </div>
          </div>
          <div class="flex items-center">
            <span v-if="currentUser" class="text-sm text-slate-500 mr-4">
              {{ currentUser.email }}
            </span>
            <Link
              href="/auth/logout"
              method="post"
              as="button"
              class="text-sm text-slate-600 hover:text-slate-900"
            >
              Logout
            </Link>
          </div>
        </div>
      </div>
    </nav>

    <!-- Page Content -->
    <main class="py-6">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <slot />
      </div>
    </main>
  </div>
</template>
