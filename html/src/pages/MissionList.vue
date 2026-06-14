<template>
  <div class="mission-list">
    <div v-for="(mission, key) in missions" :key="key" class="mission-item">
      <!-- Header -->
      <div class="cargo-header">
        <div class="icons">
          <img v-for="prop in getProperties(mission)" :key="prop" :src="`img/${prop}.png`" class="property-icon" />
        </div>
        <h2 class="item-header">{{ mission.product.label }}</h2>
      </div>

      <!-- Content -->
      <div class="cargo-data">
        <div class="item-img" :style="{ backgroundImage: `url('img/${mission.product.trailer}.jpg')` }"></div>

        <div class="mission-form">
          <table class="mission-table">
            <tr>
              <td width="120">Start:</td>
              <td>
                <span>{{ mission.loadingZone?.address }}</span>
                <button class="btn2 right" @click="setWaypoint(key)">Rakodasi hely</button>
              </td>
            </tr>
            <tr>
              <td>Inditotta:</td>
              <td>
                <span>{{ getOwnerDisplay(mission) }}</span>
                <button
                  v-if="canShowDestination(key, mission)"
                  class="btn2 right"
                  @click="setDestinationWaypoint(key)"
                >Celallomas hely</button>
              </td>
            </tr>
            <tr>
              <td>Vedok:</td>
              <td>
                <span>{{ getDefenderDisplay(mission) }}</span>
                (<span>{{ getJoinedDisplay(mission) }}</span> fo)
              </td>
            </tr>
          </table>

          <!-- Action buttons -->
          <div class="mission-actions">
            <button
              v-if="canJoin(key, mission)"
              class="btn right"
              @click="joinMission(key, mission)"
            >Csatlakozas</button>

            <button
              v-if="canLeave(key, mission)"
              class="btn3 right"
              @click="leaveMission(key, mission)"
            >Kilepes</button>

            <button
              v-if="canDelete(mission)"
              class="btn3 right"
              @click="deleteMission(key, mission)"
            >Kuldetes torlese</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, inject } from 'vue'
import { useNui, jsonParse, isEmpty } from '../composables/useNui'

const props = defineProps({
  data: { type: Object, required: true }
})

const { post } = useNui()
const closePage = inject('closePage')

const missions = computed(() => props.data?.mission || {})
const player = computed(() => props.data?.player || {})

// Check if current player is a defender in any mission
const playerDefenderKey = computed(() => {
  for (const key in missions.value) {
    const defenders = missions.value[key].joined
    if (!isEmpty(defenders)) {
      for (const k in defenders) {
        if (defenders[k] === player.value.identifier) return key
      }
    }
  }
  return false
})

function getProperties(mission) {
  return jsonParse(mission.product?.properties) || []
}

function isConfidential(mission) {
  if (player.value.group === 'superadmin') return true
  if (player.value.identifier === mission.owner?.identifier) return true
  if (player.value.job?.name === mission.defender) return true
  return false
}

function getOwnerDisplay(mission) {
  return isConfidential(mission) ? mission.owner?.characterName : 'Bizalmas informacio'
}

function getDefenderDisplay(mission) {
  return isConfidential(mission) ? mission.product?.defenderLabel : '?'
}

function getJoinedDisplay(mission) {
  return isConfidential(mission) ? Object.keys(mission.joined || {}).length : '?'
}

function canShowDestination(key, mission) {
  return playerDefenderKey.value && playerDefenderKey.value === key && mission.destinationZoneId
}

function canJoin(key, mission) {
  return mission.owner?.identifier !== player.value.identifier &&
    !playerDefenderKey.value &&
    mission.product?.defender === player.value.job?.name
}

function canLeave(key, mission) {
  return mission.owner?.identifier !== player.value.identifier &&
    key === playerDefenderKey.value
}

function canDelete(mission) {
  return mission.owner?.identifier === player.value.identifier && !mission.trailerPlate
}

function setWaypoint(key) {
  post('setWaypoint', { missionId: key })
  closePage()
}

function setDestinationWaypoint(key) {
  post('setDestinationWaypoint', { missionId: key })
  closePage()
}

function joinMission(key, mission) {
  post('missionJoin', {
    missionId: key,
    defender: mission.product.defender,
    owner: mission.owner,
    player: player.value
  })
  closePage()
}

function leaveMission(key, mission) {
  post('missionLeave', {
    missionId: key,
    defender: mission.product.defender,
    owner: mission.owner,
    player: player.value
  })
  closePage()
}

function deleteMission(key, mission) {
  post('missionDelete', {
    missionId: key,
    defender: mission.product.defender
  })
  closePage()
}
</script>

<style scoped>
.mission-item {
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
  margin: 10px 0;
  padding: 10px;
  background-color: #292929;
  text-transform: uppercase;
  font-size: 26px;
  flex: 1;
}

.cargo-data {
  display: grid;
  grid-template-columns: 250px auto;
  margin: 10px 0;
}

.item-img {
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  width: 250px;
  height: 140px;
}

.mission-form {
  padding: 0 0 0 10px;
}

.mission-table {
  width: 100%;
  border-collapse: collapse;
}

.mission-table td {
  padding: 5px;
  border-bottom: 3px solid #121212;
  background: #292929;
}

.mission-actions {
  margin: 10px 0;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn {
  border: none;
  font-size: 1.0em;
  padding: 5px 10px;
  cursor: pointer;
  background-color: var(--color-accent, #edc054);
  color: #303030;
}

.btn2 {
  border: none;
  font-size: 1.0em;
  padding: 5px 10px;
  cursor: pointer;
  background-color: #fdf9ec;
  color: #303030;
  float: right;
}

.btn3 {
  border: none;
  font-size: 1.0em;
  padding: 5px 10px;
  cursor: pointer;
  background-color: #f40827;
  color: #fdf9ec;
}

.right {
  float: right;
}
</style>
