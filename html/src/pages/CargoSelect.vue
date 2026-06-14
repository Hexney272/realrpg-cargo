<template>
  <div class="cargo-select">
    <div v-for="cargo in shipments" :key="cargo.id" class="cargo-item">
      <!-- Header -->
      <div class="cargo-header">
        <div class="icons">
          <div v-for="prop in getProperties(cargo)" :key="prop" class="property-icon-wrapper">
            <img :src="`img/${prop}.png`" class="property-icon" />
            <span class="property-tooltip">{{ getPropertyLabel(prop) }}</span>
          </div>
        </div>
        <h2 :class="['item-header', { disabled: isUnavailable(cargo) }]">{{ cargo.label }}</h2>
      </div>

      <!-- Content -->
      <div class="cargo-data">
        <div class="item-img" :style="{ backgroundImage: `url('img/${cargo.trailer}.jpg')` }">
      <span v-if="isUnavailable(cargo)" class="available-alert no-available">
            {{ getUnavailableText(cargo) }}
          </span>
        </div>

        <!-- Destination table + actions -->
        <div class="cargo-form">
          <table class="cargo-destination-table">
            <tr
              v-for="(dZone, idx) in cargo.destinationZones"
              :key="idx"
              :class="[
                'destination-row',
                { disabled: isUnavailable(cargo), 'tr-selected': selectedRow === `${cargo.id}_${idx}`, 'in-mission': getMissionInfo(cargo).isMission }
              ]"
              @click="!isUnavailable(cargo) && selectDestination(cargo, dZone, idx)"
            >
              <td>
                <span class="cargo-name">{{ dZone.name }}</span>
                <span class="cargo-description small">{{ dZone.description }}</span>
              </td>
          <td width="80" align="center">Kaució: <span>{{ formatMoney(cargo.caution_money) }}</span></td>
              <td width="120" align="center"><span class="cargo-defenders-cell"></span></td>
              <td width="70"><span class="cargo-distance">{{ dZone.distance }} Km</span></td>
              <td width="80"><span class="freight-fee">{{ formatMoney(dZone.priceData.freightFee) }}</span></td>
            </tr>
          </table>

          <!-- Mission info badge -->
          <p v-if="getMissionInfo(cargo).isMission" class="mission-info">Hasznald a '/mission' parancsot!</p>

          <!-- Defender info -->
          <div v-if="cargo.defender" class="cargo-defenders">
            Vedelem: ({{ cargo.required_defenders }} fo) {{ cargo.defenderLabel }}
          </div>

          <!-- Action buttons -->
          <div class="cargo-actions" v-if="selectedCargo?.id === cargo.id">
            <button
              v-if="showSubmitBtn(cargo)"
              class="btn submit-btn"
              @click="submitCargo(cargo)"
            >Kaució befizetése és indulás!</button>

            <button
              v-if="showMissionBtn(cargo)"
              class="btn mission-register-btn"
              @click="registerMission(cargo)"
            >Védőkíséret hívása!</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, inject } from 'vue'
import { useNui, MONEY, jsonParse, isEmpty } from '../composables/useNui'

const props = defineProps({
  data: { type: Object, required: true }
})

const { post } = useNui()
const closePage = inject('closePage')

const shipments = computed(() => {
  if (!props.data?.shipments) return []
  return Object.values(props.data.shipments).filter(Boolean)
})

const player = computed(() => props.data?.player || {})
const mission = computed(() => props.data?.mission || {})
const currentZone = computed(() => props.data?.currentZone || {})
const disableMissionStart = computed(() => props.data?.disableMissionStartForDefenders || false)

const selectedRow = ref(null)
const selectedCargo = ref(null)
const selectedDestination = ref(null)

function formatMoney(val) {
  return MONEY.format(val || 0)
}

function getProperties(cargo) {
  return jsonParse(cargo.properties) || []
}

// Property name → Hungarian label for tooltips
const propertyLabels = {
  fragile: 'Törékeny',
  explosive: 'Robbanásveszélyes',
  flammable: 'Tűzveszélyes',
  toxic: 'Mérgező',
  corrodent: 'Maró',
  pollutant: 'Szennyező',
  heavy: 'Túlsúlyos',
  refrigerate: 'Hűtendő',
  high_value: 'Nagyértékű',
  illegal: 'Illegális',
  marked_on_the_map: 'Jelölt árú',
  high_sensitivity: 'Magas érzékenység'
}

function getPropertyLabel(prop) {
  return propertyLabels[prop] || prop
}

function isUnavailable(cargo) {
  const hasRemaining = cargo.remainingTime !== 0
  const playerInDefJob = player.value.job?.name === cargo.defender
  return hasRemaining || (playerInDefJob && disableMissionStart.value)
}

function getUnavailableText(cargo) {
  if (cargo.remainingTime !== 0) return cargo.remainingTimeDisplay || ''
  return 'Védőként nem indítható'
}

function getMissionInfo(cargo) {
  let isMission = false, isOwned = false, inProgress = false

  if (cargo.defender !== '' && !isEmpty(mission.value)) {
    for (const key in mission.value) {
      const [loadingZoneId, productId] = key.split('_')
      if (productId == cargo.id && loadingZoneId == currentZone.value.id) {
        isMission = true
        if (mission.value[key].owner?.identifier === player.value.identifier) isOwned = true
        if (mission.value[key].trailerPlate) inProgress = true
      }
    }
  }

  return { isMission, isOwned, inProgress }
}

function selectDestination(cargo, dZone, idx) {
  selectedRow.value = `${cargo.id}_${idx}`
  selectedCargo.value = cargo
  selectedDestination.value = dZone
}

function showSubmitBtn(cargo) {
  if (!selectedCargo.value || selectedCargo.value.id !== cargo.id) return false
  const mi = getMissionInfo(cargo)
  if ((!mi.isMission && !player.value.InMission) || mi.isOwned) {
    return cargo.defender === '' || (mi.isOwned && !mi.inProgress)
  }
  return false
}

function showMissionBtn(cargo) {
  if (!selectedCargo.value || selectedCargo.value.id !== cargo.id) return false
  const mi = getMissionInfo(cargo)
  if ((!mi.isMission && !player.value.InMission) || mi.isOwned) {
    return cargo.defender !== '' && (mi.isOwned || !mi.inProgress)
  }
  return false
}

async function submitCargo(cargo) {
  const cargoData = buildCargoData(cargo)

  if (cargo.defender !== '') {
    const response = await post('checkDefense', cargoData)
    if (response?.message) {
      // Notification handled by Lua side
    }
    if (response?.state) {
      closePage()
      post('registerCargo', cargoData)
    }
  } else {
    closePage()
    post('registerCargo', cargoData)
  }
}

async function registerMission(cargo) {
  const cargoData = buildCargoData(cargo)
  const response = await post('missionRegister', cargoData)

  if (response?.state) {
    player.value.InMission = true
  }
}

function buildCargoData(cargo) {
  return {
    trailerModel: cargo.trailer,
    cautionMoney: cargo.caution_money,
    goodsValue: cargo.value,
    productId: cargo.id,
    km: selectedDestination.value.distance,
    destinationId: selectedDestination.value.id,
    freightFee: selectedDestination.value.priceData.freightFee,
    illegalPrice: selectedDestination.value.priceData.illegalPrice,
    params: cargo.params,
    required_defenders: cargo.required_defenders,
    defender: cargo.defender,
    loadingZoneId: currentZone.value.id
  }
}
</script>

<style scoped>
.cargo-item {
  position: relative;
  margin: 12px 0;
  padding: 16px;
  background: var(--color-bg-card);
  backdrop-filter: var(--glass-blur);
  border: var(--glass-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  transition: all var(--transition-normal);
}

.cargo-item:hover {
  border-color: var(--color-border-accent);
  box-shadow: var(--shadow-card), var(--shadow-glow);
}

.cargo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.icons {
  display: flex;
  gap: 8px;
}

.property-icon-wrapper {
  position: relative;
  display: inline-block;
}

.property-icon {
  width: 28px;
  height: 28px;
  padding: 3px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 4px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: transform var(--transition-fast);
  cursor: pointer;
}

.property-icon:hover {
  transform: scale(1.15);
}

.property-tooltip {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%) scale(0.9);
  background: rgba(10, 10, 20, 0.95);
  border: 1px solid var(--color-border-accent);
  color: var(--color-text-accent);
  padding: 5px 10px;
  border-radius: var(--radius-sm);
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
  z-index: 100;
}

.property-tooltip::after {
  content: '';
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border: 5px solid transparent;
  border-top-color: var(--color-border-accent);
}

.property-icon-wrapper:hover .property-tooltip {
  opacity: 1;
  transform: translateX(-50%) scale(1);
}

.item-header {
  position: relative;
  margin: 0;
  padding: 10px 16px;
  background: linear-gradient(135deg, rgba(30, 30, 45, 0.8) 0%, rgba(20, 20, 30, 0.9) 100%);
  text-transform: uppercase;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  flex: 1;
  border-radius: var(--radius-sm);
  border-left: 3px solid var(--color-accent);
}

.item-header.disabled {
  background: rgba(80, 80, 80, 0.4);
  border-left-color: #555;
  opacity: 0.6;
}

.cargo-data {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 16px;
}

.item-img {
  position: relative;
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  width: 240px;
  height: 135px;
  border-radius: var(--radius-sm);
  overflow: hidden;
  border: 1px solid var(--color-border);
}

.item-img::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 40%;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.6));
  pointer-events: none;
}

.available-alert.no-available {
  display: flex;
  align-items: center;
  justify-content: center;
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(135deg, rgba(227, 24, 55, 0.9), rgba(180, 20, 45, 0.95));
  padding: 6px 10px;
  font-weight: 700;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  z-index: 2;
}

.cargo-form {
  padding: 0;
}

.cargo-destination-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 4px;
}

.destination-row {
  background: rgba(30, 30, 45, 0.6);
  cursor: pointer;
  transition: all var(--transition-fast);
  border-radius: var(--radius-sm);
}

.destination-row:hover {
  background: rgba(237, 192, 84, 0.08);
  transform: translateX(3px);
}

.destination-row.disabled {
  background: rgba(60, 60, 60, 0.4) !important;
  cursor: default;
  opacity: 0.5;
}

.destination-row.disabled:hover {
  transform: none;
}

.destination-row.tr-selected {
  background: rgba(237, 192, 84, 0.12);
  border-left: 3px solid var(--color-accent);
}

.destination-row.in-mission {
  background: linear-gradient(135deg, rgba(244, 59, 20, 0.2), rgba(227, 24, 55, 0.15)) !important;
  border-left: 3px solid var(--color-mission);
}

.destination-row td {
  margin: 0;
  padding: 8px 10px;
  border: none;
  vertical-align: middle;
}

.cargo-name {
  display: block;
  font-weight: 600;
  font-size: 14px;
}

.small {
  font-size: 12px;
  color: var(--color-text-secondary);
}

.freight-fee {
  text-align: right;
  font-weight: 700;
  color: var(--color-text-accent);
}

.cargo-distance {
  display: block;
  text-align: right;
  color: var(--color-text-secondary);
  font-size: 13px;
}

.mission-info {
  display: inline-block;
  float: right;
  background: linear-gradient(135deg, var(--color-danger), #c41230);
  padding: 5px 12px;
  border-radius: var(--radius-sm);
  font-size: 12px;
  font-weight: 600;
}

.cargo-defenders {
  margin: 12px 0 0;
  padding: 8px 12px;
  background: rgba(237, 192, 84, 0.06);
  border: 1px solid var(--color-border-accent);
  border-radius: var(--radius-sm);
  font-size: 13px;
}

.cargo-actions {
  margin: 14px 0 0;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.submit-btn {
  background: var(--gradient-accent);
  color: #1a1a1a;
  font-weight: 700;
  padding: 10px 20px;
  border-radius: var(--radius-sm);
  border: none;
  cursor: pointer;
  transition: all var(--transition-fast);
  text-transform: uppercase;
  font-size: 12px;
  letter-spacing: 0.5px;
}

.submit-btn:hover {
  box-shadow: var(--shadow-glow);
  transform: translateY(-2px);
}

.mission-register-btn {
  background: linear-gradient(135deg, #ed5c11, #f0a030);
  color: #fff;
  font-weight: 700;
  padding: 10px 20px;
  border-radius: var(--radius-sm);
  border: none;
  cursor: pointer;
  transition: all var(--transition-fast);
  text-transform: uppercase;
  font-size: 12px;
  letter-spacing: 0.5px;
}

.mission-register-btn:hover {
  box-shadow: 0 0 15px rgba(237, 92, 17, 0.4);
  transform: translateY(-2px);
}
</style>
