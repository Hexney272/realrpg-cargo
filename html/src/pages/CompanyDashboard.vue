<template>
  <div class="company-dashboard" v-if="company">
    <!-- Company Header -->
    <div class="company-header glass-card">
      <div class="company-info">
        <h2 class="company-name">{{ company.name }}</h2>
        <div class="company-level">
          <span class="material-icons">stars</span>
          <span>{{ company.level.name }} (Szint {{ company.level.level }})</span>
        </div>
        <div class="company-rep">
          <span class="material-icons">trending_up</span>
          <span>Reputáció: <strong>{{ company.reputation }}</strong></span>
        </div>
      </div>
      <div class="company-balance">
        <span class="balance-label">Egyenleg</span>
        <span class="balance-value">{{ formatMoney(company.balance) }}</span>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="stats-grid">
      <div class="stat-card glass-card">
        <span class="material-icons">local_shipping</span>
        <div class="stat-data">
          <span class="stat-number">{{ company.totalDeliveries }}</span>
          <span class="stat-label">Szállítás</span>
        </div>
      </div>
      <div class="stat-card glass-card">
        <span class="material-icons">straighten</span>
        <div class="stat-data">
          <span class="stat-number">{{ Math.round(company.totalDistance) }} km</span>
          <span class="stat-label">Távolság</span>
        </div>
      </div>
      <div class="stat-card glass-card">
        <span class="material-icons">people</span>
        <div class="stat-data">
          <span class="stat-number">{{ employees.length }}</span>
          <span class="stat-label">Alkalmazott</span>
        </div>
      </div>
      <div class="stat-card glass-card">
        <span class="material-icons">directions_car</span>
        <div class="stat-data">
          <span class="stat-number">{{ vehicles.length }}</span>
          <span class="stat-label">Jármű</span>
        </div>
      </div>
    </div>

    <!-- Navigation Tabs -->
    <div class="tab-nav">
      <button :class="['tab-btn', { active: tab === 'overview' }]" @click="tab = 'overview'">
        <span class="material-icons">dashboard</span> Áttekintés
      </button>
      <button :class="['tab-btn', { active: tab === 'employees' }]" @click="tab = 'employees'">
        <span class="material-icons">people</span> Alkalmazottak
      </button>
      <button :class="['tab-btn', { active: tab === 'vehicles' }]" @click="tab = 'vehicles'">
        <span class="material-icons">directions_car</span> Járműpark
      </button>
      <button :class="['tab-btn', { active: tab === 'contracts' }]" @click="tab = 'contracts'">
        <span class="material-icons">description</span> Szerződések
      </button>
      <button :class="['tab-btn', { active: tab === 'finances' }]" @click="tab = 'finances'">
        <span class="material-icons">account_balance</span> Pénzügyek
      </button>
    </div>

    <!-- Tab Content -->
    <div class="tab-content">
      <!-- OVERVIEW TAB -->
      <div v-if="tab === 'overview'" class="tab-panel">
        <div class="overview-grid">
          <div class="overview-card glass-card">
            <h3>Bevétel összesen</h3>
            <span class="big-number">{{ formatMoney(company.totalRevenue) }}</span>
          </div>
          <div class="overview-card glass-card">
            <h3>Befizetett adó</h3>
            <span class="big-number tax">{{ formatMoney(company.taxPaid) }}</span>
          </div>
          <div class="overview-card glass-card">
            <h3>Következő szint</h3>
            <div class="next-level" v-if="nextLevel">
              <span>{{ nextLevel.name }} - Rep: {{ nextLevel.reputationNeeded }} / Szállítás: {{ nextLevel.deliveriesNeeded }}</span>
              <div class="progress-bar">
                <div class="progress-fill" :style="{ width: progressPercent + '%' }"></div>
              </div>
            </div>
            <span v-else class="max-level">Maximális szint!</span>
          </div>
        </div>

        <!-- Recent Transactions -->
        <div class="section-title">Utolsó tranzakciók</div>
        <div class="transactions-list glass-card">
          <div v-for="tx in transactions.slice(0, 10)" :key="tx.id" class="transaction-row">
            <span :class="['tx-amount', tx.amount >= 0 ? 'positive' : 'negative']">
              {{ tx.amount >= 0 ? '+' : '' }}{{ formatMoney(tx.amount) }}
            </span>
            <span class="tx-desc">{{ tx.description }}</span>
            <span class="tx-date">{{ formatDate(tx.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- EMPLOYEES TAB -->
      <CompanyEmployees
        v-if="tab === 'employees'"
        :employees="employees"
        :myRole="myRole"
        :config="config"
        @refresh="loadData"
      />

      <!-- VEHICLES TAB -->
      <CompanyVehicles
        v-if="tab === 'vehicles'"
        :vehicles="vehicles"
        :myRole="myRole"
        :config="config"
        :companyBalance="company.balance"
        @refresh="loadData"
      />

      <!-- CONTRACTS TAB -->
      <CompanyContracts
        v-if="tab === 'contracts'"
        :contracts="contracts"
        :myRole="myRole"
        @refresh="loadData"
      />

      <!-- FINANCES TAB -->
      <div v-if="tab === 'finances'" class="tab-panel">
        <div class="finance-actions glass-card">
          <h3>Kassza kezelése</h3>
          <div class="finance-row">
            <input v-model.number="depositAmount" type="number" placeholder="Összeg (Ft)" class="finance-input" />
            <button class="btn btn-deposit" @click="deposit">Befizetés</button>
            <button class="btn btn-withdraw" @click="withdraw">Kivétel</button>
          </div>
        </div>

        <div class="section-title">Összes tranzakció</div>
        <div class="transactions-list glass-card">
          <div v-for="tx in transactions" :key="tx.id" class="transaction-row">
            <span :class="['tx-amount', tx.amount >= 0 ? 'positive' : 'negative']">
              {{ tx.amount >= 0 ? '+' : '' }}{{ formatMoney(tx.amount) }}
            </span>
            <span class="tx-desc">{{ tx.description }}</span>
            <span class="tx-date">{{ formatDate(tx.created_at) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- NO COMPANY: Create or accept invite -->
  <div v-else class="no-company">
    <div class="create-company glass-card">
      <h2>Kamionos Vállalkozás</h2>
      <p class="create-desc">Alapíts saját fuvarozó céget, vegyél fel sofőröket, és építsd ki a birodalmadat!</p>

      <div class="create-form">
        <input v-model="newCompanyName" type="text" placeholder="Cégnév" class="form-input" maxlength="30" />
        <input v-model="newCompanyDesc" type="text" placeholder="Leírás (opcionális)" class="form-input" />
        <button class="btn btn-create" @click="createCompany">
          <span class="material-icons">add_business</span>
          Cég alapítása ({{ formatMoney(registrationFee) }})
        </button>
      </div>
    </div>

    <!-- Pending invites -->
    <div v-if="invites.length" class="invites-section glass-card">
      <h3>Meghívások</h3>
      <div v-for="inv in invites" :key="inv.id" class="invite-row">
        <div class="invite-info">
          <strong>{{ inv.company_name }}</strong>
          <span>Pozíció: {{ getRoleLabel(inv.role) }} | Fizetés: {{ formatMoney(inv.salary) }}/szállítás</span>
        </div>
        <button class="btn" @click="acceptInvite(inv.id)">Elfogadás</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, inject } from 'vue'
import { useNui, MONEY } from '../composables/useNui'
import CompanyEmployees from '../components/CompanyEmployees.vue'
import CompanyVehicles from '../components/CompanyVehicles.vue'
import CompanyContracts from '../components/CompanyContracts.vue'

const { post } = useNui()

const tab = ref('overview')
const company = ref(null)
const myRole = ref('driver')
const employees = ref([])
const vehicles = ref([])
const contracts = ref([])
const transactions = ref([])
const config = ref({})
const invites = ref([])

const newCompanyName = ref('')
const newCompanyDesc = ref('')
const depositAmount = ref(null)
const registrationFee = 500000

function formatMoney(val) { return MONEY.format(val || 0) }

function formatDate(dt) {
  if (!dt) return '-'
  return new Date(dt).toLocaleDateString('hu-HU', { month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}

function getRoleLabel(role) {
  const labels = { driver: 'Sofőr', dispatcher: 'Diszpécser', manager: 'Menedzser', owner: 'Tulajdonos' }
  return labels[role] || role
}

const nextLevel = computed(() => {
  if (!company.value || !config.value.levels) return null
  const levels = config.value.levels
  const current = company.value.level.level
  return levels.find(l => l.level === current + 1) || null
})

const progressPercent = computed(() => {
  if (!nextLevel.value || !company.value) return 100
  const repProgress = Math.min(100, (company.value.reputation / nextLevel.value.reputationNeeded) * 100)
  const delProgress = Math.min(100, (company.value.totalDeliveries / nextLevel.value.deliveriesNeeded) * 100)
  return Math.min(repProgress, delProgress)
})

async function loadData() {
  const data = await post('company_getData', {})
  if (data && data.company) {
    company.value = data.company
    myRole.value = data.myRole
    employees.value = data.employees || []
    vehicles.value = data.vehicles || []
    contracts.value = data.contracts || []
    transactions.value = data.transactions || []
    config.value = data.config || {}
  } else {
    company.value = null
    // Load invites for players without company
    const inv = await post('company_getInvites', {})
    if (inv && Array.isArray(inv)) invites.value = inv
  }
}

async function createCompany() {
  if (!newCompanyName.value) {
    alert('Kérlek adj meg egy cégnevet!')
    return
  }
  // Send request - response comes via Lua notification (DoCustomHudText)
  await post('company_create', { name: newCompanyName.value, description: newCompanyDesc.value })
  // Close the panel - if successful, notification will show and player can reopen
  // The Lua side handles success/error notifications
}

async function acceptInvite(inviteId) {
  const result = await post('company_acceptInvite', { inviteId })
  if (result?.success) await loadData()
}

async function deposit() {
  if (!depositAmount.value || depositAmount.value <= 0) return
  await post('company_deposit', { amount: depositAmount.value })
  depositAmount.value = null
  await loadData()
}

async function withdraw() {
  if (!depositAmount.value || depositAmount.value <= 0) return
  await post('company_withdraw', { amount: depositAmount.value })
  depositAmount.value = null
  await loadData()
}

onMounted(loadData)
</script>

<style scoped>
.company-dashboard {
  padding: 0 5px;
}

.company-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  margin-bottom: 15px;
}

.company-name {
  font-size: 24px;
  margin: 0;
  background: var(--gradient-accent);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.company-level, .company-rep {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 6px;
  color: var(--color-text-secondary);
  font-size: 13px;
}

.company-level .material-icons,
.company-rep .material-icons {
  font-size: 18px;
  color: var(--color-accent);
}

.company-balance {
  text-align: right;
}

.balance-label {
  display: block;
  font-size: 12px;
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 1px;
}

.balance-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--color-accent);
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin-bottom: 15px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px;
}

.stat-card .material-icons {
  font-size: 32px;
  color: var(--color-accent);
  opacity: 0.8;
}

.stat-number {
  display: block;
  font-size: 20px;
  font-weight: 700;
}

.stat-label {
  font-size: 11px;
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Tabs */
.tab-nav {
  display: flex;
  gap: 4px;
  margin-bottom: 15px;
  border-bottom: 1px solid var(--color-border);
  padding-bottom: 10px;
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 8px 14px;
  background: transparent;
  border: 1px solid transparent;
  color: var(--color-text-secondary);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  border-radius: var(--radius-sm);
  transition: all var(--transition-fast);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.tab-btn .material-icons { font-size: 16px; }

.tab-btn:hover {
  color: var(--color-text-primary);
  background: rgba(255,255,255,0.03);
}

.tab-btn.active {
  color: var(--color-accent);
  border-color: var(--color-border-accent);
  background: rgba(237, 192, 84, 0.06);
}

/* Overview */
.overview-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin-bottom: 15px;
}

.overview-card {
  padding: 16px;
}

.overview-card h3 {
  margin: 0 0 8px;
  font-size: 12px;
  text-transform: uppercase;
  color: var(--color-text-secondary);
  letter-spacing: 0.5px;
}

.big-number {
  font-size: 22px;
  font-weight: 700;
  color: var(--color-success);
}

.big-number.tax {
  color: var(--color-danger);
}

.progress-bar {
  height: 6px;
  background: rgba(255,255,255,0.05);
  border-radius: 3px;
  margin-top: 8px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--gradient-accent);
  border-radius: 3px;
  transition: width 0.5s ease;
}

.max-level {
  color: var(--color-accent);
  font-weight: 700;
}

/* Transactions */
.section-title {
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--color-text-secondary);
  margin: 15px 0 8px;
}

.transactions-list {
  padding: 10px;
  max-height: 300px;
  overflow-y: auto;
}

.transaction-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid var(--color-border);
  font-size: 13px;
}

.transaction-row:last-child { border-bottom: none; }

.tx-amount {
  font-weight: 700;
  min-width: 100px;
}
.tx-amount.positive { color: var(--color-success); }
.tx-amount.negative { color: var(--color-danger); }

.tx-desc { flex: 1; color: var(--color-text-secondary); }
.tx-date { color: var(--color-text-muted); font-size: 11px; }

/* Finances */
.finance-actions {
  padding: 16px;
  margin-bottom: 15px;
}

.finance-actions h3 {
  margin: 0 0 12px;
  font-size: 16px;
}

.finance-row {
  display: flex;
  gap: 10px;
  align-items: center;
}

.finance-input {
  flex: 1;
  padding: 8px 12px;
  background: rgba(255,255,255,0.03);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  color: var(--color-text-primary);
  font-size: 14px;
  outline: none;
}

.finance-input:focus {
  border-color: var(--color-border-accent);
}

.btn-deposit { background: var(--gradient-accent); color: #1a1a1a; }
.btn-withdraw { background: rgba(227,24,55,0.15); color: var(--color-danger); border: 1px solid rgba(227,24,55,0.3); }

/* No Company */
.no-company {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  gap: 20px;
}

.create-company {
  max-width: 500px;
  width: 100%;
  padding: 30px;
  text-align: center;
}

.create-company h2 {
  margin: 0 0 8px;
  font-size: 24px;
  background: var(--gradient-accent);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.create-desc {
  color: var(--color-text-secondary);
  margin-bottom: 20px;
}

.create-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.form-input {
  padding: 10px 14px;
  background: rgba(255,255,255,0.03);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  color: var(--color-text-primary);
  font-size: 14px;
  outline: none;
  transition: border-color var(--transition-fast);
}

.form-input:focus { border-color: var(--color-border-accent); }

.btn-create {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px;
  margin-top: 5px;
}

/* Invites */
.invites-section {
  max-width: 500px;
  width: 100%;
  padding: 20px;
}

.invites-section h3 { margin: 0 0 12px; }

.invite-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid var(--color-border);
}

.invite-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.invite-info span {
  font-size: 12px;
  color: var(--color-text-secondary);
}

/* Glass card from global */
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
  transition: all var(--transition-fast);
  text-transform: uppercase;
  letter-spacing: 0.3px;
  background: var(--gradient-accent);
  color: #1a1a1a;
}

.btn:hover { box-shadow: var(--shadow-glow); transform: translateY(-1px); }
</style>
