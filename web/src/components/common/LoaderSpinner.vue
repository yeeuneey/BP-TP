<!-- src/components/common/LoaderSpinner.vue -->
<template>
  <div class="loader-wrap">
    <div class="spinner"></div>
  </div>
</template>

<script setup lang="ts"></script>

<style scoped>
.loader-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 2rem 0;
}
.spinner {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 3px solid rgba(255, 255, 255, 0.2);
  border-top-color: #e50914;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
