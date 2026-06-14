<template>
  <div class="employees-panel">
    <div class="section-header">
      <h3>Alkalmazottak ({{ employees.length }})</h3>
      <button v-if="canHire" class="btn btn-sm" @click="showInviteForm = !showInviteForm">
        <span class="material-icons">person_add</span> Meghívás
      </button>
    </div>

    <!-- Invite form -->
    <div v-if="showInviteForm" class="invite-form glass-card">
      <input v-model="inviteTarget" type="text" placeholder="Játékos azonosító (ID)" class="form-input" />
      <select v-model="inviteRole" class="form-input">
        <option value="driver">Sofőr</option>
        <option value="dispatcher">Diszpécser</option>
        <option value="manager">Menedzser</option>
      </select>
      <input v-model.number="inviteSalary" type="number" placeholder="Fizetés (Ft/szállítás)" class="form-input" />
      <button class="btn" @click="sendInvite">Meghívás küldése</button>
    </div>

    <!-- Employee List -->
    <div class="employee-list">
      <div v-for="emp in employees" :key="emp.id" class="employee-card glass-card">
        <div class="emp-avatar">
          <span class="material-icons">{{ getRoleIcon(emp.role) }}</span>
        </div>
        <div class="emp-info">
          <span class="emp-name">{{ emp.firstname }} {{ emp.lastname }}</span>
          <span class="emp-role" :class="'role-' + emp.role">{{ getRoleLabel(emp.role) }}</span>
        </div>
        <div class="emp-stats">
          <span>{{ emp.deliveries_done }} szállítás</span>
          <span>{{ Math.round(emp.distance_driven) }} km</span>
          <span>{{ formatMoney(emp.salary) }}/fuvar</span>
        </div>
        <div class="emp-actions" v-if="canHire && emp.role !== 'owner'">
          <button class="btn-icon" @click="fireEmployee(emp.identifier)" title="Elbocsátás">
            <span class="material-icons">person_remove</span>
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
  employees: { type: Array, default: () => [] },
  myRole: { type: String, default: 'driver' },
  config: { type: Object, default: () => ({}) }
})

const emit = defineEmits(['refresh'])
const { post } = useNui()

const showInviteForm = ref(false)
const inviteTarget = ref('')
const inviteRole = ref('driver')
const inviteSalary = ref(15000)

const canHire = computed(() => ['owner', 'manager'].includes(props.myRole))

function formatMoney(val) { return MONEY.format(val || 0) }

function getRoleLabel(role) {
  const labels = { driver: 'Sofőr', dispatcher: 'Diszpécser', manager: 'Menedzser', owner: 'Tulajdonos' }
  return labels[role] || role
}

function getRoleIcon(role) {
  const icons = { driver: 'local_shipping', dispatcher: 'headset_mic', manager: 'manage_accounts', owner: 'diamond' }
  return icons[role] || 'person'
}

async function sendInvite() {
  if (!inviteTarget.value) return
  await post('company_invite', {
    targetIdentifier: inviteTarget.value,
    role: inviteRole.value,
    salary: inviteSalary.value
  })
  showInviteForm.value = false
  inviteTarget.value = ''
  emit('refresh')
}

async function fireEmployee(identifier) {
  await post('company_fire', { targetIdentifier: identifier })
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
}

.btn-sm .material-icons { font-size: 16px; }

.invite-form {
  display: flex;
  gap: 8px;
  padding: 12px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.form-input {
  padding: 8px 12px;
  background: rgba(255,255,255,0.03);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  color: var(--color-text-primary);
  font-size: 13px;
  outline: none;
  flex: 1;
  min-width: 120px;
}

.form-input:focus { border-color: var(--color-border-accent); }

.employee-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.employee-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  transition: border-color var(--transition-fast);
}

.employee-card:hover { border-color: var(--color-border-accent); }

.emp-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(237, 192, 84, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
}

.emp-avatar .material-icons {
  font-size: 22px;
  color: var(--color-accent);
}

.emp-info { flex: 1; }

.emp-name {
  display: block;
  font-weight: 600;
  font-size: 14px;
}

.emp-role {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 2px 6px;
  border-radius: 3px;
  font-weight: 600;
}

.role-owner { color: #f5d061; background: rgba(245,208,97,0.1); }
.role-manager { color: #5596c1; background: rgba(85,150,193,0.1); }
.role-dispatcher { color: #a78bfa; background: rgba(167,139,250,0.1); }
.role-driver { color: #8a8a9a; background: rgba(138,138,154,0.1); }

.emp-stats {
  display: flex;
  gap: 15px;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.emp-actions { margin-left: auto; }

.btn-icon {
  background: rgba(227,24,55,0.1);
  border: 1px solid rgba(227,24,55,0.2);
  border-radius: var(--radius-sm);
  padding: 5px;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-icon .material-icons { font-size: 18px; color: var(--color-danger); }
.btn-icon:hover { background: var(--color-danger); }
.btn-icon:hover .material-icons { color: white; }

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
