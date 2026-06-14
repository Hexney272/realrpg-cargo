<template>
  <TransitionGroup name="achievement" tag="div" class="achievement-container">
    <div
      v-for="ach in achievements"
      :key="ach.id"
      class="achievement-popup"
    >
      <div class="achievement-icon">
        <span class="material-icons">{{ ach.icon || 'emoji_events' }}</span>
      </div>
      <div class="achievement-content">
        <div class="achievement-title">Achievement Unlocked!</div>
        <div class="achievement-name">{{ ach.name }}</div>
        <div class="achievement-desc">{{ ach.description }}</div>
      </div>
    </div>
  </TransitionGroup>
</template>

<script setup>
import { ref } from 'vue'
import { useNuiEvent } from '../composables/useNui'

const achievements = ref([])
let counter = 0

useNuiEvent('ACHIEVEMENT', (data) => {
  const ach = {
    id: ++counter,
    icon: data.achievement?.icon || 'emoji_events',
    name: data.achievement?.name || 'Unknown',
    description: data.achievement?.description || ''
  }

  achievements.value.push(ach)

  // Auto-remove after 6 seconds
  setTimeout(() => {
    const idx = achievements.value.findIndex(a => a.id === ach.id)
    if (idx !== -1) achievements.value.splice(idx, 1)
  }, 6000)
})
</script>

<style scoped>
.achievement-container {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 10px;
  pointer-events: none;
}

.achievement-popup {
  display: flex;
  align-items: center;
  gap: 15px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  border: 2px solid #e6b422;
  border-radius: 8px;
  padding: 15px 25px;
  box-shadow: 0 8px 32px rgba(230, 180, 34, 0.3);
  min-width: 300px;
  pointer-events: auto;
}

.achievement-icon {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #e6b422, #f5d061);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.achievement-icon .material-icons {
  font-size: 28px;
  color: #1a1a2e;
}

.achievement-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.achievement-title {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: #e6b422;
  font-weight: bold;
}

.achievement-name {
  font-size: 18px;
  font-weight: bold;
  color: #ffffff;
}

.achievement-desc {
  font-size: 12px;
  color: #a0a0a0;
}

/* Transitions */
.achievement-enter-active {
  transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}
.achievement-leave-active {
  transition: all 0.4s ease-in;
}
.achievement-enter-from {
  opacity: 0;
  transform: translateY(-40px) scale(0.8);
}
.achievement-leave-to {
  opacity: 0;
  transform: translateY(-20px) scale(0.9);
}
</style>
