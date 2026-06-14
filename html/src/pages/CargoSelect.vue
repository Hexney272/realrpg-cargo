<template>
  <div class="cargo-select">
    <div v-for="cargo in shipments" :key="cargo.id" class="cargo-item">
      <!-- Header -->
      <div class="cargo-header">
        <div class="icons">
          <img v-for="prop in getProperties(cargo)" :key="prop" :src="`img/${prop}.png`" class="property-icon" />
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
              <td width="80" align="center">Kaucio: <span>{{ formatMoney(cargo.caution_money) }}</span></td>
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
            >Kaucio befizetese es indulas!</button>

            <button
              v-if="showMissionBtn(cargo)"
              class="btn mission-register-btn"
              @click="registerMission(cargo)"
            >Vedokiseret hivasa!</button>
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

function isUnavailable(cargo) {
  const hasRemaining = cargo.remainingTime !== 0
  const playerInDefJob = player.value.job?.name === cargo.defender
  return hasRemaining || (playerInDefJob && disableMissionStart.value)
}

function getUnavailableText(cargo) {
  if (cargo.remainingTime !== 0) return cargo.remainingTimeDisplay || ''
  return 'Vedokent nem indithato'
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
  margin: 10px 0;
  padding: 0 10px;
  background-color: #1d1d1d;
}

.cargo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.icons {
  display: flex;
  gap: 10px;
}

.property-icon {
  width: 32px;
  height: 32px;
}

.item-header {
  position: relative;
  margin: 10px 0;
  padding: 10px;
  background-color: #292929;
  text-transform: uppercase;
  font-size: 26px;
  flex: 1;
}

.item-header.disabled {
  background-color: grey;
}

.cargo-data {
  display: grid;
  grid-template-columns: 250px auto;
  margin: 10px 0;
}

.item-img {
  position: relative;
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  width: 250px;
  height: 140px;
}

.available-alert.no-available {
  display: block;
  position: absolute;
  text-align: right;
  bottom: 0;
  right: 0;
  background: red;
  width: 100%;
  padding: 5px;
  font-weight: bold;
  box-sizing: border-box;
  font-size: 16px;
}

.cargo-form {
  padding: 0 0 0 10px;
}

.cargo-destination-table {
  width: 100%;
  border-collapse: collapse;
}

.destination-row {
  background: #292929;
  cursor: pointer;
  transition: background-color 0.15s;
}

.destination-row:hover {
  background-color: #121212;
}

.destination-row.disabled {
  background-color: grey !important;
  cursor: default;
}

.destination-row.tr-selected {
  background-color: #121212;
}

.destination-row.in-mission {
  background-color: #f43b14 !important;
}

.destination-row td {
  margin: 0;
  padding: 5px;
  border-bottom: 3px solid #121212;
}

.cargo-name {
  display: block;
}

.small {
  font-size: 14px;
  color: #a0a0a0;
}

.freight-fee {
  text-align: right;
  margin-right: 15px;
  float: right;
}

.cargo-distance {
  display: block;
  text-align: right;
}

.mission-info {
  display: inline-block;
  float: right;
  background: #e31837;
  padding: 5px 10px;
}

.cargo-defenders {
  margin: 10px 0;
}

.cargo-actions {
  margin: 10px 0;
  display: flex;
  gap: 10px;
}

.btn {
  border: none;
  font-size: 1.0em;
  padding: 5px 10px;
  cursor: pointer;
}

.submit-btn {
  background-color: var(--color-accent, #edc054);
  color: #303030;
}

.mission-register-btn {
  background-color: #ed5c11;
  color: #fff;
}
</style>
