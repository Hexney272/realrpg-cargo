<template>
  <li class="stat-item">
    <span class="material-icons stat-icon">{{ icon }}</span>
    <span class="stat-content">
      <span class="stat-value">{{ value }}</span>
      <slot>
        <span class="stat-desc">{{ desc }}</span>
      </slot>
    </span>
  </li>
</template>

<script setup>
defineProps({
  icon: { type: String, required: true },
  value: { type: [String, Number], default: 0 },
  desc: { type: String, default: '' }
})
</script>

<style scoped>
.stat-item {
  display: grid;
  grid-template-columns: max-content auto;
  padding: 10px;
  align-content: center;
}

.stat-icon {
  font-size: 90px;
  background-color: orange;
  width: 110px;
  height: 110px;
  margin-right: 10px;
  text-align: center;
  line-height: 110px;
}

.stat-content {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.stat-value {
  font-size: 50px;
  color: #f6bb42;
  font-weight: bold;
}

.stat-desc {
  display: block;
}

.stat-desc :deep(span) {
  color: #f6bb42;
  font-weight: bold;
}
</style>
