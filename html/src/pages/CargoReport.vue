<template>
  <div class="cargo-report" v-if="report">
    <table class="report-table">
      <!-- Sender / Destination -->
      <tr class="tr-hl"><td>Megrendelő:</td><td>Célállomás:</td></tr>
      <tr>
        <td>
          <span class="big">{{ report.loadingZone?.name }}</span>
          <span class="block">{{ report.loadingZone?.address }}</span>
          <span class="block small">{{ report.loadingZone?.description }}</span>
        </td>
        <td>
          <span class="big">{{ report.targetZone?.name }}</span>
          <span class="block">{{ report.targetZone?.address }}</span>
          <span class="block small">{{ report.targetZone?.description }}</span>
        </td>
      </tr>

      <!-- Driver -->
      <tr class="tr-hl"><td colspan="2">Fuvarozó:</td></tr>
      <tr>
        <td>{{ report.owner?.characterName }}</td>
        <td>Magánvállalkozó</td>
      </tr>

      <!-- Product -->
      <tr class="tr-hl"><td>Árú megnevezése:</td><td>Távolság:</td></tr>
      <tr>
        <td>
          <span class="big">{{ report.product?.name }}</span>
          <span class="prop-names" v-if="report.product?.propnames"> ({{ report.product.propnames }})</span>
        </td>
        <td>{{ report.km }} Km</td>
      </tr>

      <!-- Payment -->
      <tr v-if="report.showPayData">
        <td colspan="2">
          <!-- Legal payment -->
          <table v-if="!report.stolen" class="payment-table tbl-theme1">
            <thead>
              <tr>
                <th class="left">Tétel</th>
                <th>Összeg</th>
                <th>Állapot</th>
                <th>Levonás</th>
                <th>Kifizetés</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="left">Fuvardíj</td>
                <td>{{ money(report.payData?.freightFee) }}</td>
                <td>(rakomany) {{ Math.round(report.quality) }} %</td>
                <td>{{ money(report.payData?.priceDeduction) }}</td>
                <td>{{ money(report.payData?.pricePayment) }}</td>
              </tr>
              <tr>
                <td class="left">Kaució</td>
                <td>{{ money(report.cautionMoney) }}</td>
                <td>(trailer) {{ Math.round(report.trailerHealth * 0.1) }} %</td>
                <td>{{ money(report.payData?.cautionDeduction) }}</td>
                <td>{{ money(report.payData?.cautionPayment) }}</td>
              </tr>
              <tr class="tr-h4">
                <td class="left">Összesen</td>
                <td></td><td></td><td></td>
                <td class="payable">{{ money(report.payData?.payable) }}</td>
              </tr>
              <tr v-if="report.payData?.defenderSocietyPayable > 0" class="tr-h4">
                <td class="left">Védő frakció</td>
                <td></td><td></td><td></td>
                <td>{{ money(report.payData.defenderSocietyPayable) }}</td>
              </tr>
            </tbody>
          </table>

          <!-- Illegal payment (stolen) -->
          <table v-else class="payment-table tbl-theme2">
            <thead>
              <tr>
                <th class="left">Tétel</th>
                <th>Teljes érték</th>
                <th>Állapot</th>
                <th>Levonás</th>
                <th>Kifizetés</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="left">Árú</td>
                <td>{{ money(report.illegalPrice) }}</td>
                <td>(rakomany) {{ Math.round(report.quality) }} %</td>
                <td>{{ money(report.payData?.priceDeduction) }}</td>
                <td class="payable">{{ money(report.payData?.payable) }}</td>
              </tr>
            </tbody>
          </table>
        </td>
      </tr>

      <!-- Vehicle -->
      <tr class="tr-hl"><td colspan="2">Jármű:</td></tr>
      <tr>
        <td colspan="2">
          <div class="vehicle-grid">
            <div class="item-img" :style="{ backgroundImage: `url('img/${report.product?.trailer}.jpg')` }"></div>
            <div class="vehicle-info">
              <div class="vehicle-row">
                <span>Rendszám</span>
                <span class="right">{{ report.trailerPlate }}</span>
              </div>
              <div class="vehicle-row">
                <span>Állapot (trailer)</span>
                <span class="right">{{ Math.round(report.trailerHealth * 0.1) }} %</span>
              </div>
              <div class="vehicle-row">
                <span>Állapot (rakomány)</span>
                <span class="right">{{ Math.round(report.quality) }} %</span>
              </div>
            </div>
            <div class="vehicle-info">
              <div class="vehicle-row">
                <span>Max sebesség (Város)</span>
                <span class="right">{{ report.maxSpeed?.city || 0 }} Km/h</span>
              </div>
              <div class="vehicle-row">
                <span>Max sebesség (Vidék)</span>
                <span class="right">{{ report.maxSpeed?.country || 0 }} Km/h</span>
              </div>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { MONEY } from '../composables/useNui'

const props = defineProps({
  data: { type: Object, default: null }
})

const report = computed(() => props.data)

function money(val) {
  return MONEY.format(val || 0)
}
</script>

<style scoped>
.cargo-report {
  padding: 0 10px;
}

.report-table {
  width: 100%;
  border-collapse: collapse;
}

.report-table td {
  padding: 8px 10px;
  border-bottom: 3px solid #121212;
  background: #1d1d1d;
  vertical-align: top;
}

.tr-hl td {
  background-color: #3c3c3c;
  color: #5596c1;
  font-weight: bold;
}

.tr-h4 td {
  background-color: #ffcc8c !important;
  color: #1a1a1a;
}

.big {
  font-size: 24px;
}

.block {
  display: block;
}

.small {
  font-size: 14px;
  color: #a0a0a0;
}

.prop-names {
  color: #a0a0a0;
  font-size: 14px;
}

.left {
  text-align: left !important;
}

.right {
  float: right;
}

.payable {
  font-size: 16px;
  font-weight: bold;
}

/* Payment tables */
.payment-table {
  width: 100%;
  border-collapse: collapse;
  margin: 10px 0;
}

.payment-table td,
.payment-table th {
  margin: 0;
  padding: 5px 15px;
  text-align: right;
}

.tbl-theme1 { color: #1A1A1A; }
.tbl-theme1 th { background: #dc8532; }
.tbl-theme1 tr { background: #f49d31; }

.tbl-theme2 { color: #fdf9ec; }
.tbl-theme2 th { background: #f42632; }
.tbl-theme2 tr { background: #f42632; }

/* Vehicle section */
.vehicle-grid {
  display: grid;
  grid-template-columns: 250px 1fr 1fr;
  gap: 15px;
  align-items: start;
}

.item-img {
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  width: 250px;
  height: 140px;
}

.vehicle-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.vehicle-row {
  display: flex;
  justify-content: space-between;
  padding: 4px 0;
  border-bottom: 1px solid #333;
}
</style>
