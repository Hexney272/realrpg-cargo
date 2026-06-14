<template>
  <div class="notification-container">
    <TransitionGroup name="notif">
      <div
        v-for="notif in notifications"
        :key="notif.id"
        :class="['notification', notif.type]"
        :style="notif.customStyle"
        v-html="notif.text"
      ></div>
    </TransitionGroup>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useNuiEvent } from '../composables/useNui'

const notifications = ref([])
const persistentNotifs = ref({})
let notifCounter = 0

function addNotification(data) {
  const id = ++notifCounter
  const notif = {
    id,
    type: data.type || 'information',
    text: data.text || '',
    customStyle: data.style || {}
  }

  if (!data.persist) {
    notifications.value.push(notif)
    const duration = data.length || 8000
    setTimeout(() => {
      removeNotification(id)
    }, duration)
  } else {
    if (data.persist.toUpperCase() === 'START') {
      if (!persistentNotifs.value[data.id]) {
        notifications.value.push(notif)
        persistentNotifs.value[data.id] = id
      } else {
        // Update existing
        const existingId = persistentNotifs.value[data.id]
        const idx = notifications.value.findIndex(n => n.id === existingId)
        if (idx !== -1) {
          notifications.value[idx].type = notif.type
          notifications.value[idx].text = notif.text
          notifications.value[idx].customStyle = notif.customStyle
        }
      }
    } else if (data.persist.toUpperCase() === 'END') {
      const existingId = persistentNotifs.value[data.id]
      if (existingId) {
        removeNotification(existingId)
        delete persistentNotifs.value[data.id]
      }
    }
  }
}

function removeNotification(id) {
  const idx = notifications.value.findIndex(n => n.id === id)
  if (idx !== -1) notifications.value.splice(idx, 1)
}

// Listen for notification events from Lua
useNuiEvent('NOTIFICATION', (data) => {
  addNotification(data)
})

// Expose for external use (e.g. from other components)
defineExpose({ addNotification })
</script>

<style scoped>
.notification-container {
  z-index: 100;
}

.notification {
  display: grid;
  grid-template-columns: min-content auto;
  padding: 0.2vw 0.6vw 0.2vw 0;
  box-sizing: border-box;
  margin: 5px 0;
  font-size: 0.8vw;
  font-weight: bold;
  align-items: center;
}

/* Type styles with Material Icons pseudo-elements */
.success::before,
.information::before,
.warning::before,
.money::before,
.fail::before {
  position: relative;
  display: inherit;
  font-family: 'Material Icons';
  font-size: 2vw;
  margin: 0 1vw 0 0;
  background: blanchedalmond;
  height: 100%;
  align-content: center;
  padding: 0.2vw 0.6vw;
  color: #fff;
}

.success { background: #a0d468; color: #5b793b; }
.success::before { content: "done_outline"; background-color: #8cc152; }

.money { background: #88c6a3; color: #2a593f; }
.money::before { content: "attach_money"; background-color: #689e80; }

.information { background-color: #4fc1e9; color: #396677; }
.information::before { content: "notifications"; background-color: #3bafda; }

.warning { background-color: #ffce54; color: #9b6f00; }
.warning::before { content: "warning"; background-color: #f6bb42; }

.fail { background: #ed5565; color: #8a313a; }
.fail::before { background-color: #da4453; content: "error"; }

/* Transitions */
.notif-enter-active {
  transition: all 0.3s ease;
}
.notif-leave-active {
  transition: all 0.3s ease;
}
.notif-enter-from {
  opacity: 0;
  transform: translateX(30px);
}
.notif-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}
</style>
