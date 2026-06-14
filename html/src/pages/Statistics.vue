<template>
  <div class="statistics-container">
    <div class="cargo-header">
      <h2 class="item-header">Statisztika</h2>
    </div>

    <!-- Tab buttons -->
    <ul class="statistics-menu">
      <li class="btn" :class="{ active: tab === 'my' }" @click="switchTab('my')">Sajat statisztika</li>
      <li class="btn" :class="{ active: tab === 'all' }" @click="switchTab('all')">Osszesitett lista</li>
      <li class="btn" :class="{ active: tab === 'ranks' }" @click="switchTab('ranks')">Rangok</li>
    </ul>

    <!-- MY STATISTICS -->
    <div v-if="tab === 'my' && myStats" class="my-statistics">
      <ul class="st-ul1">
        <li>
          <span class="stat-value-big">{{ myStats.quality_rate }}%</span>
          <span class="stat-desc padding-desc"><span>Elegedettsegi mutato</span><br/>a leszallitott aruk minosege alapjan</span>
        </li>
        <li>
          <span class="stat-value-big">{{ myStats.success_rate }}%</span>
          <span class="stat-desc padding-desc"><span>Siker mutato</span><br/>vallalt es leszallitott fuvarok aranya</span>
        </li>
      </ul>

      <ul class="st-ul2">
        <StatItem icon="open_in_full" :value="myStats.distance" desc="Megtett tavolsag [km]" />
        <StatItem icon="query_builder" :value="myStats.working_time">
          <span class="stat-desc">Munkaido [{{ myStats.working_time_unit }}]<br/>Munkavallalas: {{ myStats.registered }}</span>
        </StatItem>
        <StatItem icon="content_paste" :value="myStats.all_started">
          <span class="stat-desc">Elvallalt fuvarjaid<br/>{{ myStats.started_mission }} kuldetes<br/>{{ myStats.started_delivery }} magan</span>
        </StatItem>
        <StatItem icon="add_task" :value="myStats.all_done">
          <span class="stat-desc">Teljesitett fuvarjaid<br/>{{ myStats.done_mission }} kuldetes<br/>{{ myStats.done_delivery }} magan</span>
        </StatItem>
        <StatItem icon="local_bar" :value="myStats.vulnerable" desc="Serulekeny fuvarok" />
        <StatItem icon="verified_user" :value="myStats.defender" desc="Kuldetesek, melyekben vedo voltal" />
        <StatItem icon="disabled_by_default" :value="myStats.destroyed_trailer" desc="Totalkaros felpotkocsi" />
        <StatItem icon="content_paste_off" :value="myStats.all_stolen">
          <span class="stat-desc">Altalad eltulajdonitott fuvarok<br/>{{ myStats.stolen_mission }} kuldetes<br/>{{ myStats.stolen_delivery }} magan</span>
        </StatItem>
      </ul>
    </div>

    <!-- LEADERBOARD -->
    <div v-if="tab === 'all' && allStats.length" class="summary-statistics">
      <div class="order-by-form">
        <select class="statistics-order-menu" v-model="orderBy" @change="fetchAll">
          <option value="firstname">Nev</option>
          <option value="distance">Megtett tavolsag</option>
          <option value="working_time">Munkaido</option>
          <option value="all_started">Elvallalt fuvarok</option>
          <option value="all_done">Teljesitett fuvarok</option>
          <option value="vulnerable">Serulekeny fuvarok</option>
          <option value="quality_rate">Elegedettsegi mutato</option>
          <option value="success_rate">Siker mutato</option>
        </select>
      </div>

      <div
        v-for="(stat, i) in allStats"
        :key="i"
        :class="['summary-item', `item-style-${stat.rank}`]"
        @click="toggleDropdown(i)"
      >
        <div class="stat-item-main">
          <span class="stat-value-name">{{ i + 1 }}. {{ stat.character_name }}</span>
          <span :class="['stat-value-title', `label-style-${stat.rank}`]">{{ stat.titleLabel }}</span>
          <span :class="['stat-value-rank', `label-style-${stat.rank}`]">{{ stat.rankLabel }}</span>
          <div class="stat-item-right">
            <span>{{ stat.distance }} km</span>
            <span>{{ stat.working_time }} {{ stat.working_time_unit }}</span>
            <span>{{ stat.all_started }} fuvar</span>
          </div>
        </div>
        <transition name="dropdown">
          <div v-if="expandedIdx === i" class="stat-item-dropdown">
            <span v-if="stat.all_started - stat.all_done > 0" class="failed">{{ stat.all_started - stat.all_done }} sikertelen</span>
            <span>{{ stat.vulnerable }} serulekeny</span>
            <span>{{ stat.success_rate }}% sikeresseg</span>
            <span>{{ stat.quality_rate }}% elegedettseg</span>
            <span>{{ stat.registered }} - {{ stat.last_activity }}</span>
          </div>
        </transition>
      </div>
    </div>

    <!-- RANKS -->
    <div v-if="tab === 'ranks' && ranksData" class="rank-list">
      <h3 class="center">Az alabbi tablazatok tartalmazzak azokat az ertekhatarokat, amiket adott ranghoz / cimhez teljesiteni szukseges.</h3>

      <div class="tables-container">
        <table class="tbl-theme3 statistics-titles">
          <tr><th>Cim</th><th>Kilometer</th><th>Rang</th></tr>
          <tr v-for="(t, i) in ranksData.titles" :key="'t'+i">
            <td>{{ ranksData.titleLabels[i] }}</td>
            <td>{{ t.distance }}</td>
            <td>{{ ranksData.rankLabels[t.rank - 1] }}</td>
          </tr>
        </table>

        <table class="tbl-theme3 statistics-ranks">
          <tr><th>Rang</th><th>Serulekeny</th><th>Fuvarok</th><th>Elegedettseg</th><th>Sikeresseg</th></tr>
          <tr v-for="(r, i) in ranksData.ranks" :key="'r'+i">
            <td>{{ ranksData.rankLabels[i] }}</td>
            <td>{{ r.vulnerable }}</td>
            <td>{{ r.all_done }}</td>
            <td>{{ r.quality_rate }}%</td>
            <td>{{ r.success_rate }}%</td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useNui, formatTime, isEmpty } from '../composables/useNui'
import StatItem from '../components/StatItem.vue'

const props = defineProps({
  data: { type: [Object, Array], default: null }
})

const { post } = useNui()

const tab = ref('my')
const orderBy = ref('all_started')
const expandedIdx = ref(null)
const myStats = ref(null)
const allStats = ref([])
const ranksData = ref(null)

// Prepare stat data for display
function prepareStat(data) {
  const t = formatTime(data.working_time || 0)
  const name = `${data.firstname || ''} ${data.lastname || ''}`.trim()
  return {
    ...data,
    character_name: name.substring(0, 20),
    distance: parseFloat(((data.distance || 0) * 1).toFixed(1)),
    quality_rate: data.quality_rate ? parseFloat((data.quality_rate * 1).toFixed(1)) : 0,
    success_rate: data.success_rate ? parseFloat((data.success_rate * 1).toFixed(1)) : 0,
    working_time: t.time,
    working_time_unit: t.unit,
    registered: formatDate(data.registered),
    last_activity: formatDate(data.last_activity)
  }
}

function formatDate(ms) {
  if (!ms) return '-'
  return new Date(ms).toLocaleDateString('hu-HU', { month: 'short', day: '2-digit' })
}

// Initialize with passed data (myStatistics first load)
onMounted(() => {
  if (props.data && !Array.isArray(props.data) && !isEmpty(props.data)) {
    myStats.value = prepareStat(props.data)
  }
})

async function switchTab(newTab) {
  tab.value = newTab
  expandedIdx.value = null

  if (newTab === 'my') {
    const resp = await post('myStatistics', {})
    // Lua side re-sends STATISTICS message, handled by App.vue
  } else if (newTab === 'all') {
    await fetchAll()
  } else if (newTab === 'ranks') {
    const resp = await post('getRanks', {})
    if (resp) ranksData.value = resp
  }
}

async function fetchAll() {
  const resp = await post('getAllStatistics', { orderBy: orderBy.value })
  if (resp && Array.isArray(resp)) {
    allStats.value = resp.map(prepareStat)
  }
}

function toggleDropdown(idx) {
  expandedIdx.value = expandedIdx.value === idx ? null : idx
}
</script>

<style scoped>
.statistics-container {
  padding: 0 10px;
}

.item-header {
  margin: 10px 0;
  padding: 10px;
  background-color: #292929;
  text-transform: uppercase;
  font-size: 26px;
}

.statistics-menu {
  display: flex;
  gap: 10px;
  list-style: none;
  margin: 0 0 15px 0;
  padding: 0;
}

.statistics-menu .btn {
  border: none;
  padding: 8px 16px;
  font-size: 1em;
  cursor: pointer;
  background-color: var(--color-accent, #edc054);
  color: #303030;
  transition: opacity 0.2s;
}

.statistics-menu .btn.active {
  opacity: 0.6;
  cursor: default;
}

/* MY STATISTICS */
.st-ul1 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin: 10px 0;
  padding: 0;
  list-style: none;
  border-bottom: 2px solid orange;
  background-color: #292929;
}

.st-ul1 li {
  display: grid;
  grid-template-columns: max-content auto;
  padding: 10px;
}

.st-ul2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  padding: 10px;
  margin: 0;
  list-style: none;
  background-color: #292929;
}

.stat-value-big {
  font-size: 70px;
  color: #f6bb42;
  font-weight: bold;
}

.stat-desc {
  display: block;
}

.stat-desc span {
  color: #f6bb42;
  font-weight: bold;
}

.padding-desc {
  padding: 15px 0 0 15px;
}

/* LEADERBOARD */
.summary-statistics {
  position: relative;
}

.order-by-form {
  position: absolute;
  top: -45px;
  right: 0;
}

.statistics-order-menu {
  padding: 3px;
  background: var(--color-accent, #edc054);
  border: none;
  outline: none;
}

.summary-item {
  border-width: 1px;
  border-style: solid;
  position: relative;
  font-size: 16px;
  color: whitesmoke;
  margin: 5px 0;
  cursor: pointer;
  transition: transform 0.1s;
}

.summary-item:hover {
  transform: scale(1.005);
}

.stat-item-main {
  padding: 8px;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.stat-value-name {
  text-transform: uppercase;
  font-size: 18px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 280px;
}

.stat-value-title {
  text-transform: uppercase;
  font-size: 18px;
  width: 160px;
}

.stat-value-rank {
  text-transform: uppercase;
  font-size: 14px;
}

.stat-item-right {
  margin-left: auto;
  display: flex;
  gap: 20px;
}

.stat-item-dropdown {
  display: flex;
  justify-content: space-between;
  padding: 8px;
  overflow: hidden;
}

.failed { color: red; }

/* Rank colors */
.item-style-1 { border-color: #747478; background: url('/img/statitem_bg1.jpg'); }
.item-style-2 { border-color: #8f6f64; background: url('/img/statitem_bg2.jpg'); }
.item-style-3 { border-color: #9f9fa7; background: url('/img/statitem_bg3.jpg'); }
.item-style-4 { border-color: #cbba6e; background: url('/img/statitem_bg4.jpg'); }
.item-style-5 { border-color: #56d3ff; background: url('/img/statitem_bg5.jpg'); }

.label-style-1 { color: #747478; }
.label-style-2 { color: #8f6f64; }
.label-style-3 { color: #9f9fa7; }
.label-style-4 { color: #cbba6e; }
.label-style-5 { color: #56d3ff; }

/* RANKS */
.rank-list { padding: 10px; }

.center { text-align: center; }

.tables-container {
  display: flex;
  justify-content: space-evenly;
  gap: 20px;
  flex-wrap: wrap;
}

.tbl-theme3 { color: #edc054; }
.tbl-theme3 td:first-child,
.tbl-theme3 th:first-child { text-align: left; color: whitesmoke; }
.tbl-theme3 td { padding: 15px; text-align: right; border: none; vertical-align: top; }
.tbl-theme3 th { padding: 5px 15px; background: #3c3c3c; text-align: right; }
.tbl-theme3 tr { background: #242424; }
.tbl-theme3 tr:nth-child(2n) { background: #161616; }

.statistics-titles { width: 410px; }
.statistics-ranks { width: 550px; }

/* Dropdown transition */
.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.3s ease;
}
.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  max-height: 0;
}
</style>
