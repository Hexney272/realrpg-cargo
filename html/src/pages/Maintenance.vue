<template>
  <div class="maintenance" v-if="diag">
    <div class="cargo-header">
      <h2 class="item-header">Adatbazis diagnosztika, karbantartas</h2>
    </div>

    <table class="diagnostics-table">
      <tr>
        <td>Termekek: <span class="desc-text">Osszes termek</span></td>
        <td align="right">{{ diag.countProducts }}</td>
        <td width="40" :class="marker(diag.countProducts > 0)"></td>
      </tr>
      <tr>
        <td colspan="3">Hianyzo termeknev forditasok a nyelvi fajlban:
          <span class="missing-locales">{{ JSON.stringify(diag.missingLocales) }}</span>
        </td>
      </tr>
      <tr>
        <td>Arva termekek: <span class="desc-text">Olyan termek, amihez nem tartozik leado vagy felvevopont</span></td>
        <td align="right"><span v-html="renderList(diag.orphanProduct, p => `${p.id}. ${p.transName}`)"></span></td>
        <td :class="marker(isEmpty(diag.orphanProduct))"></td>
      </tr>
      <tr>
        <td>Utvonalak: <span class="desc-text">Osszes utvonal, benne vannak az ismetlodo utvonalak is</span></td>
        <td align="right">{{ diag.countRoutes }}</td>
        <td :class="marker(diag.countRoutes > 0)"></td>
      </tr>
      <tr>
        <td>Egyedi utvonalak: <span class="desc-text">Utvonalak szama, ismetlodes nelkul</span></td>
        <td align="right">{{ diag.countUniqueRoutes }}</td>
        <td :class="marker(diag.countUniqueRoutes > 0)"></td>
      </tr>
      <tr>
        <td>Hibas tavolsag bejegyzesek: <span class="desc-text">distances tablaban elavult bejegyzes</span></td>
        <td align="right">{{ diag.wrongDistanceRecord }}</td>
        <td :class="marker(diag.wrongDistanceRecord === 0)"></td>
      </tr>
      <tr>
        <td>Arva tavolsag bejegyzesek: <span class="desc-text">distances tablaban letezo bejegyzes, amihez nem tartozik utvonal</span></td>
        <td align="right"><span v-html="renderList(diag.orphanDistanceRecord, id => id)"></span></td>
        <td :class="marker(isEmpty(diag.orphanDistanceRecord))"></td>
      </tr>
      <tr>
        <td>Hianyzo tavolsag bejegyzesek: <span class="desc-text">distances tablabol hianyzo bejegyzes</span></td>
        <td align="right">{{ diag.missingDistanceRecord }}</td>
        <td :class="marker(diag.missingDistanceRecord === 0)"></td>
      </tr>
      <tr>
        <td>Zonak (actionpoints) szama: <span class="desc-text">A zones tablaban szereplo record-ok szama</span></td>
        <td align="right">{{ diag.countActionPoints }}</td>
        <td :class="marker(diag.countActionPoints > 0)"></td>
      </tr>
      <tr>
        <td>Hianyzo zonak: <span class="desc-text">Olyan zona, amire a products tablaban van hivatkozas, de a zones tablaban nem letezik</span></td>
        <td align="right"><span v-html="renderObjList(diag.missingActionPoints, v => `Zone: ${v.zoneId}, Product: ${v.productId}. ${v.productLabel}`)"></span></td>
        <td :class="marker(isEmpty(diag.missingActionPoints))"></td>
      </tr>
      <tr>
        <td>Arva zonak: <span class="desc-text">A zones tablaban levo bejegyzes, ami nincs hasznalatban (torolheto)</span></td>
        <td align="right"><span v-html="renderList(diag.orphanActionPoints, v => `${v.id}. ${v.name}`)"></span></td>
        <td :class="marker(isEmpty(diag.orphanActionPoints))"></td>
      </tr>

      <!-- Actions -->
      <tr>
        <td colspan="3">
          Hianyzo tavolsagok ujraszamitasa, potlasa:
          <span class="desc-text">A distances tabla karbantartasa. <strong>A muvelet kozben megnyilik a terkep, ne zard be!</strong></span>
          <button class="btn action-btn" @click="distanceCalc">Tavolsag bejegyzesek felvetele / javitasa</button>
        </td>
      </tr>
      <tr>
        <td colspan="3">
          Zonak megjelenitese:
          <span class="desc-text">Megjeleníti az osszes zonat</span>
          <button class="btn action-btn" @click="showZones">Zonajelzes be/ki</button>
        </td>
      </tr>
      <tr>
        <td colspan="3">
          <p><strong>ADMIN TOOLS:</strong></p>
          <ul class="admin-list">
            <li>Uj akciopontok (zonak) felvetele: ECO_COORDS</li>
            <li>Uj trailer spawnpoint-ok felvetele: ECO_PLACE</li>
            <li>Termek es zona manager: webes felulet</li>
          </ul>
        </td>
      </tr>
    </table>

    <p class="footer-text">ECO CARGO 2025</p>
  </div>
</template>

<script setup>
import { computed, inject } from 'vue'
import { useNui, isEmpty as isEmptyFn } from '../composables/useNui'

const props = defineProps({
  data: { type: Object, default: null }
})

const { post } = useNui()
const closePage = inject('closePage')

const diag = computed(() => props.data)

function isEmpty(val) {
  return isEmptyFn(val)
}

function marker(isGood) {
  return isGood ? 'marker good' : 'marker fault'
}

function renderList(arr, formatter) {
  if (!arr || !arr.length) return '0'
  return '<ul>' + arr.map(item => `<li>${formatter(item)}</li>`).join('') + '</ul>'
}

function renderObjList(obj, formatter) {
  if (!obj || Object.keys(obj).length === 0) return '0'
  const items = Object.values(obj).map(v => `<li>${formatter(v)}</li>`).join('')
  return '<ul>' + items + '</ul>'
}

function distanceCalc() {
  post('distanceCalc', {})
  closePage()
}

function showZones() {
  post('showAllActionPoints', {})
  closePage()
}
</script>

<style scoped>
.maintenance {
  padding: 0 10px;
}

.item-header {
  margin: 10px 0;
  padding: 10px;
  background-color: #292929;
  text-transform: uppercase;
  font-size: 26px;
}

.diagnostics-table {
  width: 100%;
  border-collapse: collapse;
}

.diagnostics-table td {
  padding: 8px 10px;
  border-bottom: 3px solid #121212;
  background: #1d1d1d;
  vertical-align: top;
}

.desc-text {
  display: block;
  margin: 5px 0;
  font-size: 13px;
  color: #a0a0a0;
}

.missing-locales {
  color: #da4453;
}

.marker {
  width: 40px;
  text-align: center;
}

.marker.good::before {
  content: "done";
  font-family: 'Material Icons';
  font-size: 24px;
  color: #49c34f;
}

.marker.fault::before {
  content: "disabled_by_default";
  font-family: 'Material Icons';
  font-size: 24px;
  color: #da4453;
}

.action-btn {
  float: right;
  margin: 5px 0;
}

.btn {
  border: none;
  font-size: 1.0em;
  padding: 5px 10px;
  cursor: pointer;
  background-color: var(--color-accent, #edc054);
  color: #303030;
}

.admin-list {
  list-style: disc;
  padding-left: 20px;
  margin: 10px 0;
}

.admin-list li {
  padding: 3px 0;
}

.footer-text {
  text-align: center;
  padding: 30px;
  color: #666;
}

:deep(ul) {
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
