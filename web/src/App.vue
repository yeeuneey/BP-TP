<!-- App.vue -->
<template>
  <div id="app" class="app-shell">
    <HeaderBar v-if="showHeader" />

    <main class="app-main">
      <RouterView v-slot="{ Component }">
        <transition name="route-fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </RouterView>
    </main>
  </div>
</template>


<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import HeaderBar from '@/components/layout/HeaderBar.vue'

const route = useRoute()

const showHeader = computed(() => route.name !== 'signin')
</script>

<style>
.route-fade-enter-active,
.route-fade-leave-active {
  transition: opacity 0.3s ease;
}
.route-fade-enter-from,
.route-fade-leave-to {
  opacity: 0;
}
</style>
