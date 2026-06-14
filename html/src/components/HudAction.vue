<template>
  <transition name="action-fade">
    <div v-if="visible" class="action-information">
      <span class="msg-company-name">{{ actionData.name }}</span>
      <span class="msg-description">{{ actionData.description }}</span>
      <span class="msg-action-msg">{{ actionData.message }}</span>
    </div>
  </transition>
</template>

<script setup>
import { ref } from 'vue'
import { useNuiEvent } from '../composables/useNui'

const visible = ref(false)
const actionData = ref({ name: '', description: '', message: '' })

useNuiEvent('ACTION_INFO', (data) => {
  if (data.operation === 'close') {
    visible.value = false
    return
  }

  // Don't show if a page is open
  const page = document.getElementById('page')
  if (page && page.children.length > 0) return

  actionData.value = data.actionData || {}
  visible.value = true
})

// Also close when delivery info or page opens
useNuiEvent(['CLOSE_INFO', 'CLOSE_PAGE'], () => {
  visible.value = false
})
</script>

<style scoped>
.action-information {
  display: flex;
  flex-direction: column;
  background: #3a576a;
  padding: 0.3vw;
  margin: 0.3vw 0;
  font-family: Verdana, Geneva, sans-serif;
  font-size: 0.7vw;
}

.msg-company-name {
  font-size: 1vw;
  padding: 0.1vw;
  display: block;
}

.msg-description {
  padding: 0.1vw;
  display: block;
}

.msg-action-msg {
  display: block;
  padding: 0.1vw;
  background-color: var(--color-accent, #edc054);
  text-align: center;
  color: #000;
  font-weight: bold;
  margin-top: 0.3vw;
}

.action-fade-enter-active,
.action-fade-leave-active {
  transition: opacity 0.3s;
}
.action-fade-enter-from,
.action-fade-leave-to {
  opacity: 0;
}
</style>
