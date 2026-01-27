<script setup>
import { ref, computed } from 'vue'
import { Link, usePage } from '@inertiajs/vue3'

defineProps({
  currentUser: Object
})

const page = usePage()
const mobileMenuOpen = ref(false)

const navigation = [
  { name: 'Dashboard', href: '/app', icon: 'dashboard' },
  { name: 'Pipeline', href: '/app/pipeline', icon: 'pipeline' },
  { name: 'Jobs', href: '/app/jobs', icon: 'briefcase' },
  { name: 'Applications', href: '/app/applications', icon: 'users' },
  { name: 'Templates', href: '/app/email_templates', icon: 'template' },
  { name: 'Reports', href: '/app/reports', icon: 'chart' },
  { name: 'Settings', href: '/app/settings', icon: 'settings' }
]

function isActive(href) {
  const url = page.url
  if (href === '/app') return url === '/app' || url === '/app/'
  return url.startsWith(href)
}
</script>

<template>
  <div class="min-h-screen bg-zinc-50">
    <!-- Navigation -->
    <nav class="sticky top-0 z-40 bg-white/80 backdrop-blur-lg border-b border-zinc-200/80">
      <div class="max-w-[1400px] mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-14">
          <div class="flex items-center">
            <!-- Logo -->
            <Link href="/app" class="flex items-center gap-2 group">
              <div class="w-8 h-8 bg-zinc-900 rounded-lg flex items-center justify-center">
                <span class="text-white font-bold text-sm">L</span>
              </div>
              <span class="text-lg font-semibold text-zinc-900 hidden sm:block">Listailor</span>
            </Link>
            
            <!-- Desktop Nav -->
            <div class="hidden lg:flex lg:ml-8 lg:gap-1">
              <Link
                v-for="item in navigation"
                :key="item.name"
                :href="item.href"
                :class="[
                  'px-3 py-1.5 text-sm font-medium rounded-lg transition-all duration-150',
                  isActive(item.href)
                    ? 'bg-zinc-900 text-white'
                    : 'text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100'
                ]"
              >
                {{ item.name }}
              </Link>
            </div>
          </div>
          
          <!-- Right side -->
          <div class="flex items-center gap-4">
            <!-- Search shortcut hint -->
            <div class="hidden md:flex items-center gap-2 px-3 py-1.5 bg-zinc-100 rounded-lg text-sm text-zinc-500">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <span class="text-zinc-400">Search...</span>
              <kbd class="hidden sm:inline-flex items-center px-1.5 py-0.5 bg-white rounded text-xs font-mono text-zinc-500 border border-zinc-200">⌘K</kbd>
            </div>
            
            <!-- User menu -->
            <div class="flex items-center gap-3">
              <span v-if="currentUser" class="text-sm text-zinc-500 hidden sm:block font-mono">
                {{ currentUser.email }}
              </span>
              <Link
                href="/auth/logout"
                method="post"
                as="button"
                class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 rounded-lg transition-colors"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                <span class="hidden sm:inline">Logout</span>
              </Link>
            </div>
            
            <!-- Mobile menu button -->
            <button
              @click="mobileMenuOpen = !mobileMenuOpen"
              class="lg:hidden p-2 rounded-lg text-zinc-500 hover:text-zinc-900 hover:bg-zinc-100"
            >
              <svg v-if="!mobileMenuOpen" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
              </svg>
              <svg v-else class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      
      <!-- Mobile menu -->
      <div v-if="mobileMenuOpen" class="lg:hidden border-t border-zinc-200 bg-white">
        <div class="px-4 py-3 space-y-1">
          <Link
            v-for="item in navigation"
            :key="item.name"
            :href="item.href"
            @click="mobileMenuOpen = false"
            :class="[
              'block px-3 py-2 text-sm font-medium rounded-lg transition-colors',
              isActive(item.href)
                ? 'bg-zinc-900 text-white'
                : 'text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100'
            ]"
          >
            {{ item.name }}
          </Link>
        </div>
      </div>
    </nav>

    <!-- Page Content -->
    <main class="py-6 lg:py-8">
      <div class="max-w-[1400px] mx-auto px-4 sm:px-6 lg:px-8">
        <slot />
      </div>
    </main>
    
    <!-- Footer -->
    <footer class="border-t border-zinc-200 bg-white mt-auto">
      <div class="max-w-[1400px] mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div class="flex items-center justify-between text-xs text-zinc-400">
          <span>Listailor ATS</span>
          <span class="font-mono">v1.0.0</span>
        </div>
      </div>
    </footer>
  </div>
</template>
