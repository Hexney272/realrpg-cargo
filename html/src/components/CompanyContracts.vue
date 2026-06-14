<template>
  <div class="contracts-panel">
    <div class="section-header">
      <h3>Szerződések ({{ contracts.length }})</h3>
    </div>

    <div v-if="!contracts.length" class="empty-state glass-card">
      <span class="material-icons">description</span>
      <p>Jelenleg nincsenek elérhető szerződések.</p>
    </div>

    <div class="contract-list">
      <div v-for="contract in contracts" :key="contract.id" :class="['contract-card', 'glass-card', 'status-border-' + contract.status]">
        <div class="contract-header">
          <span :class="['contract-status', 'cs-' + contract.status]">{{ getStatusLabel(contract.status) }}</span>
          <span class="contract-reward">{{ formatMoney(contract.reward) }}</span>
        </div>

        <div class="contract-details">
          <div class="contract-route">
            <span class="material-icons">location_on</span>
            <span>Zóna {{ contract.zone_from }} → Zóna {{ contract.zone_to }}</span>
          </div>
          <div class="contract-meta">
            <span><span class="material-icons">timer</span> {{ contract.deadline_hours }}h határidő</span>
            <span><span class="material-icons">star</span> Min. {{ contract.required_quality }}% minőség</span>
            <span v-if="contract.bonus_reward"><span class="material-icons">emoji_events</span> Bónusz: {{ formatMoney(contract.bonus_reward) }}</span>
          </div>
        </div>

        <div class="contract-actions" v-if="contract.status === 'available' && canAccept">
          <button class="btn" @click="acceptContract(contract.id)">Elfogadás</button>
        </div>

        <div v-if="contract.status === 'completed'" class="contract-result">
          <span class="material-icons">check_circle</span>
          Teljesítve - Minőség: {{ contract.delivery_quality }}%
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useNui, MONEY } from '../composables/useNui'

const props = defineProps({
  contracts: { type: Array, default: () => [] },
  myRole: { type: String, default: 'driver' }
})

const emit = defineEmits(['refresh'])
const { post } = useNui()

const canAccept = computed(() => ['owner', 'manager', 'dispatcher'].includes(props.myRole))

function formatMoney(val) { return MONEY.format(val || 0) }

function getStatusLabel(status) {
  const labels = {
    available: 'Elérhető',
    accepted: 'Elfogadva',
    in_progress: 'Folyamatban',
    completed: 'Teljesítve',
    failed: 'Sikertelen',
    expired: 'Lejárt'
  }
  return labels[status] || status
}

async function acceptContract(contractId) {
  await post('company_acceptContract', { contractId })
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

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
  color: var(--color-text-muted);
  gap: 10px;
}

.empty-state .material-icons { font-size: 48px; opacity: 0.3; }

.contract-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.contract-card {
  padding: 14px;
  transition: all var(--transition-fast);
}

.contract-card:hover { border-color: var(--color-border-accent); }

.status-border-available { border-left: 3px solid var(--color-success); }
.status-border-accepted { border-left: 3px solid var(--color-accent); }
.status-border-in_progress { border-left: 3px solid var(--color-info); }
.status-border-completed { border-left: 3px solid var(--color-success); }
.status-border-failed { border-left: 3px solid var(--color-danger); }
.status-border-expired { border-left: 3px solid var(--color-text-muted); }

.contract-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.contract-status {
  padding: 3px 8px;
  border-radius: 3px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.cs-available { color: var(--color-success); background: rgba(73,195,79,0.1); }
.cs-accepted { color: var(--color-accent); background: rgba(237,192,84,0.1); }
.cs-in_progress { color: var(--color-info); background: rgba(85,150,193,0.1); }
.cs-completed { color: var(--color-success); background: rgba(73,195,79,0.1); }
.cs-failed { color: var(--color-danger); background: rgba(227,24,55,0.1); }
.cs-expired { color: var(--color-text-muted); background: rgba(100,100,100,0.1); }

.contract-reward {
  font-size: 18px;
  font-weight: 700;
  color: var(--color-accent);
}

.contract-route {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 14px;
}

.contract-route .material-icons { font-size: 18px; color: var(--color-info); }

.contract-meta {
  display: flex;
  gap: 15px;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.contract-meta span {
  display: flex;
  align-items: center;
  gap: 3px;
}

.contract-meta .material-icons { font-size: 14px; }

.contract-actions {
  margin-top: 12px;
  text-align: right;
}

.contract-result {
  margin-top: 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--color-success);
  font-weight: 600;
  font-size: 13px;
}

.contract-result .material-icons { font-size: 18px; }

.glass-card {
  background: var(--color-bg-card);
  backdrop-filter: var(--glass-blur);
  border: var(--glass-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
}

.btn {
  border: none;
  font-size: 12px;
  font-weight: 600;
  padding: 8px 16px;
  cursor: pointer;
  border-radius: var(--radius-sm);
  background: var(--gradient-accent);
  color: #1a1a1a;
  text-transform: uppercase;
}
</style>
