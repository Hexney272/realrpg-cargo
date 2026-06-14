<template>
  <!-- HUD Layer (always visible when active) -->
  <div id="hudWrapper">
    <HudDelivery />
    <HudAction />
    <NotificationList />
  </div>

  <!-- Page Layer (modal pages) -->
  <transition name="page-fade">
    <div v-if="currentPage" class="pageWrapper" @keyup.esc="closePage">
      <header class="header">
        <h1>ECO CARGO</h1>
        <button class="btnClose" @click="closePage">Bezar</button>
      </header>

      <div class="titleContainer" v-if="pageTitle">
        <h1 class="title">{{ pageTitle }}</h1>
        <span class="description">{{ pageDescription }}</span>
      </div>

      <div id="page">
        <CargoSelect v-if="currentPage === 'CARGO_SELECT'" :data="pageData" />
        <CargoReport v-if="currentPage === 'CARGO_REPORT'" :data="pageData" />
        <MissionList v-if="currentPage === 'MISSION_LIST'" :data="pageData" />
        <Statistics v-if="currentPage === 'STATISTICS'" :data="pageData" />
        <Maintenance v-if="currentPage === 'MAINTENANCE'" :data="pageData" />
      </div>
    </div>
  </transition>

  <!-- Achievement Popup -->
  <AchievementPopup />
</template>

<script setup>
import { ref, provide } from 'vue'
import { useNui } from './composables/useNui'
import HudDelivery from './components/HudDelivery.vue'
import HudAction from './components/HudAction.vue'
import NotificationList from './components/NotificationList.vue'
import AchievementPopup from './components/AchievementPopup.vue'
import CargoSelect from './pages/CargoSelect.vue'
import CargoReport from './pages/CargoReport.vue'
import MissionList from './pages/MissionList.vue'
import Statistics from './pages/Statistics.vue'
import Maintenance from './pages/Maintenance.vue'

const currentPage = ref(null)
const pageData = ref(null)
const pageTitle = ref('')
const pageDescription = ref('')

const { post } = useNui()

function closePage() {
  currentPage.value = null
  pageData.value = null
  pageTitle.value = ''
  pageDescription.value = ''
  post('exit')
}

function openPage(page, data, title = '', description = '') {
  currentPage.value = page
  pageData.value = data
  pageTitle.value = title
  pageDescription.value = description
}

// Provide to children
provide('closePage', closePage)
provide('openPage', openPage)
provide('pageTitle', pageTitle)
provide('pageDescription', pageDescription)

// Listen for NUI messages from Lua
useNui().onMessage((event) => {
  const item = event.data

  switch (item.subject) {
    case 'CARGO_SELECT':
      openPage('CARGO_SELECT', {
        shipments: item.data,
        currentZone: item.currentZone,
        player: item.player,
        mission: item.mission,
        disableMissionStartForDefenders: item.disableMissionStartForDefenders
      }, item.currentZone?.name, `${item.currentZone?.address || ''}, ${item.currentZone?.description || ''}`)
      break

    case 'CARGO_REPORT':
      openPage('CARGO_REPORT', item.data, 'Szallitoevel', '')
      break

    case 'MISSION_LIST':
      openPage('MISSION_LIST', { mission: item.mission, player: item.player }, 'Kuldetes lista', 'Csatlakozhatsz vedonek, jelolheted a rakodasi hely es a celallomas pontokat.')
      break

    case 'STATISTICS':
      openPage('STATISTICS', item.data)
      break

    case 'MAINTENANCE':
      openPage('MAINTENANCE', item.data)
      break

    case 'CLOSE_PAGE':
      currentPage.value = null
      pageData.value = null
      break
  }
})

// ESC key handler
document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape' || e.key === 'Backspace') {
    closePage()
  }
})
</script>
