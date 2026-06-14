<template>
  <transition name="hud-fade">
    <div v-if="visible" class="hud-delivery">
      <div class="hud-header">
        <div class="hud-product-name">{{ productName }}</div>
        <div class="hud-properties">
          <img
            v-for="prop in properties"
            :key="prop"
            :src="`img/${prop}.png`"
            class="hud-prop-icon"
          />
        </div>
      </div>

      <div class="hud-display-bar">
        <!-- Speed Limit -->
        <div class="hud-db-bg hud-speed">
          <span :class="['hud-speed-value', { blink: overSpeed }]" :style="{ color: overSpeed ? 'red' : 'white' }">
            {{ speedLimit }}
          </span>
        </div>

        <!-- Wheel alert -->
        <div :class="['hud-db-bg hud-icon-wheel', { 'alert-icon': alerts.wheel }]"></div>

        <!-- Roll alert -->
        <div :class="['hud-db-bg hud-icon-roll', { 'alert-icon': alerts.roll }]"></div>

        <!-- Damage alert -->
        <div :class="['hud-db-bg hud-icon-damage', { 'alert-icon': alerts.damage }]"></div>

        <!-- Trailer health bar -->
        <div class="hud-db-bg hud-progbar">
          <div class="hud-bar trailer-bar" :style="{ width: trailerHealth + '%' }"></div>
          <div class="hud-bar-text">Pot: <span>{{ trailerHealth }}</span>%</div>
        </div>

        <!-- Goods quality bar -->
        <div class="hud-db-bg hud-progbar">
          <div class="hud-bar goods-bar" :style="{ width: goodsQuality + '%' }"></div>
          <div class="hud-bar-text">Aru: <span>{{ goodsQuality }}</span>%</div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useNuiEvent, jsonParse } from '../composables/useNui'

const visible = ref(false)
const productName = ref('')
const properties = ref([])
const speedLimit = ref(90)
const trailerHealth = ref(100)
const goodsQuality = ref(100)
const overSpeed = ref(false)
const alerts = ref({ wheel: false, roll: false, damage: false })

// Alert timeout manager
function triggerAlert(type) {
  if (alerts.value[type]) return
  alerts.value[type] = true
  setTimeout(() => { alerts.value[type] = false }, 5000)
}

// Show delivery HUD
useNuiEvent('DELIVERY_INFO', (data) => {
  if (data.operation === 'close') {
    visible.value = false
    return
  }

  const info = data.deliveryData
  if (!info) return

  productName.value = info.productName || ''
  properties.value = jsonParse(info.productProperties) || []
  speedLimit.value = info.speedLimit || 90
  trailerHealth.value = Math.max(0, info.trailerHealth || 0)
  goodsQuality.value = Math.max(0, info.goodsQuality || 0)
  overSpeed.value = false
  visible.value = true
})

// Close HUD
useNuiEvent('CLOSE_INFO', () => {
  visible.value = false
})

// Live updates
useNuiEvent('UPDATE', (data) => {
  switch (data.paramName) {
    case 'trailerHealth':
      trailerHealth.value = data.value
      triggerAlert('damage')
      break
    case 'goodsQuality':
      goodsQuality.value = Math.max(0, data.value)
      break
    case 'wheel':
      triggerAlert('wheel')
      break
    case 'roll':
      triggerAlert('roll')
      break
    case 'speedLimit':
      speedLimit.value = data.value
      break
    case 'overSpeed':
      overSpeed.value = data.value === 1
      break
  }
})
</script>

<style scoped>
.hud-delivery {
  background-color: rgba(28, 28, 28, 0.7);
  font-family: Verdana, Geneva, sans-serif;
  font-size: 0.7vw;
}

.hud-header {
  display: grid;
  grid-template-columns: auto 30%;
  gap: 5px;
  padding: 2px 5px;
}

.hud-product-name {
  font-size: 1vw;
  white-space: nowrap;
  overflow: hidden;
}

.hud-properties {
  text-align: right;
}

.hud-prop-icon {
  display: inline-block;
  width: 1vw;
  height: 1vw;
  background: lightgray;
  padding: 0.1vw;
  margin: 0.1vw 0;
}

.hud-display-bar {
  display: grid;
  grid-template-columns: 2.2vw 2.2vw 2.2vw 2.2vw auto auto;
  gap: 5px;
  padding: 5px;
}

.hud-db-bg {
  position: relative;
  background-color: #3a3230;
  padding: 0;
  height: 2.2vw;
  border: 1px solid #3a3230;
}

.hud-speed {
  text-align: center;
  font-size: 1.2vw;
  line-height: 2.2vw;
}

.hud-speed-value {
  transition: color 0.2s;
}

.hud-icon-wheel,
.hud-icon-roll,
.hud-icon-damage {
  background-image: url('/img/cargo_icons35x35.png');
  background-size: 6.2vw 4.4vw;
}

.hud-icon-wheel { background-position: 0 0; }
.hud-icon-roll { background-position: 4.21vw 0; }
.hud-icon-damage { background-position: 2.2vw 0; }

.alert-icon {
  background-position-y: 2.2vw !important;
  border-color: #c3121a;
}

.hud-progbar {
  background: linear-gradient(180deg, red 45%, transparent 45%);
}

.hud-bar {
  position: absolute;
  width: 0;
  height: 45%;
  background-color: green;
  transition: width 0.3s ease;
}

.hud-bar-text {
  position: absolute;
  bottom: 1px;
  left: 1px;
}

.blink {
  animation: blinker 0.6s ease-in-out infinite alternate;
}

@keyframes blinker {
  from { opacity: 1.0; }
  to { opacity: 0.0; }
}

.hud-fade-enter-active,
.hud-fade-leave-active {
  transition: opacity 0.3s;
}
.hud-fade-enter-from,
.hud-fade-leave-to {
  opacity: 0;
}
</style>
