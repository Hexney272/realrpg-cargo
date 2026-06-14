<template>
  <div class="vehicles-panel">
    <div class="section-header">
      <h3>Járműpark ({{ vehicles.length }})</h3>
      <button v-if="canManage" class="btn btn-sm" @click="showShop = !showShop">
        <span class="material-icons">add</span> Vásárlás
      </button>
    </div>

    <!-- Vehicle Shop -->
    <div v-if="showShop" class="vehicle-shop glass-card">
      <h4>Elérhető járművek</h4>
      <div class="shop-grid">
        <div v-for="v in availableVehicles" :key="v.model" class="shop-item">
          <span class="shop-name">{{ v.name }}</span>
          <span class="shop-price">{{ formatMoney(v.price) }}</span>
          <span class="shop-maintenance">Szervíz: {{ formatMoney(v.maintenanceCost) }}</span>
          <button class="btn btn-buy" @click="buyVehicle(v.model)" :disabled="companyBalance < v.price">
            Megvásárlás
          </button>
        </div>
      </div>
    </div>

    <!-- Vehicle List -->
    <div class="vehicle-list">
      <div v-for="veh in vehicles" :key="veh.id" class="vehicle-card glass-card">
        <div class="veh-icon">
          <span class="material-icons">local_shipping</span>
        </div>
        <div class="veh-info">
          <span class="veh-name">{{ veh.display_name || veh.model }}</span>
          <span class="veh-plate">{{ veh.plate }}</span>
        </div>
        <div class="veh-stats">
          <div class="veh-stat">
            <span class="material-icons">speed</span>
            {{ Math.round(veh.mileage) }} km
          </div>
          <div class="veh-stat">
            <span class="material-icons">healing</span>
            {{ Math.round(veh.health / 10) }}%
          </div>
          <div :class="['veh-status', 'status-' + veh.status]">{{ getStatusLabel(veh.status) }}</div>
        </div>
        <div class="veh-actions" v-if="canManage">
          <button class="btn-icon-sell" @click="sellVehicle(veh.id)" title="Eladás">
            <span class="material-icons">sell</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useNui, MONEY } from '../composables/useNui'

const props = defineProps({
  vehicles: { type: Array, default: () => [] },
  myRole: { type: String, default: 'driver' },
  config: { type: Object, default: () => ({}) },
  companyBalance: { type: Number, default: 0 }
})

const emit = defineEmits(['refresh'])
const { post } = useNui()

const showShop = ref(false)
const canManage = computed(() => ['owner', 'manager'].includes(props.myRole))
const availableVehicles = computed(() => props.config?.vehiclesAvailable || [])

function formatMoney(val) { return MONEY.format(val || 0) }

function getStatusLabel(status) {
  const labels = { available: 'Szabad', in_use: 'Használatban', maintenance: 'Szervízben', destroyed: 'Megsemmisült' }
  return labels[status] || status
}

async function buyVehicle(model) {
  await post('company_buyVehicle', { model })
  showShop.value = false
  emit('refresh')
}

async function sellVehicle(vehicleId) {
  await post('company_sellVehicle', { vehicleId })
  emit('refresh')
}
</script>

<style scoped>
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.section-header h3 { margin: 0; font-size: 16px; }

.btn-sm {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  padding: 6px 12px;
  border: none;
  border-radius: var(--radius-sm);
  background: var(--gradient-accent);
  color: #1a1a1a;
  cursor: pointer;
  font-weight: 600;
  text-transform: uppercase;
}

.btn-sm .material-icons { font-size: 16px; }

.vehicle-shop {
  padding: 16px;
  margin-bottom: 12px;
}

.vehicle-shop h4 { margin: 0 0 12px; font-size: 14px; }

.shop-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.shop-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px;
  background: rgba(255,255,255,0.02);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
}

.shop-name { font-weight: 700; font-size: 14px; }
.shop-price { color: var(--color-accent); font-weight: 600; }
.shop-maintenance { font-size: 11px; color: var(--color-text-secondary); }

.btn-buy {
  margin-top: 6px;
  border: none;
  padding: 6px 10px;
  font-size: 11px;
  font-weight: 600;
  border-radius: var(--radius-sm);
  background: var(--gradient-accent);
  color: #1a1a1a;
  cursor: pointer;
  text-transform: uppercase;
}

.btn-buy:disabled { opacity: 0.4; cursor: not-allowed; }

.vehicle-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.vehicle-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  transition: border-color var(--transition-fast);
}

.vehicle-card:hover { border-color: var(--color-border-accent); }

.veh-icon {
  width: 44px;
  height: 44px;
  border-radius: 8px;
  background: rgba(237,192,84,0.08);
  display: flex;
  align-items: center;
  justify-content: center;
}

.veh-icon .material-icons { font-size: 24px; color: var(--color-accent); }

.veh-info { flex: 1; }
.veh-name { display: block; font-weight: 600; font-size: 14px; }
.veh-plate { font-size: 11px; color: var(--color-text-muted); font-family: monospace; }

.veh-stats {
  display: flex;
  gap: 12px;
  align-items: center;
}

.veh-stat {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.veh-stat .material-icons { font-size: 16px; }

.veh-status {
  padding: 3px 8px;
  border-radius: 3px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-available { color: var(--color-success); background: rgba(73,195,79,0.1); }
.status-in_use { color: var(--color-accent); background: rgba(237,192,84,0.1); }
.status-maintenance { color: var(--color-warning); background: rgba(246,187,66,0.1); }
.status-destroyed { color: var(--color-danger); background: rgba(227,24,55,0.1); }

.btn-icon-sell {
  background: rgba(237,192,84,0.1);
  border: 1px solid var(--color-border-accent);
  border-radius: var(--radius-sm);
  padding: 5px;
  cursor: pointer;
}

.btn-icon-sell .material-icons { font-size: 18px; color: var(--color-accent); }

.glass-card {
  background: var(--color-bg-card);
  backdrop-filter: var(--glass-blur);
  border: var(--glass-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
}
</style>
