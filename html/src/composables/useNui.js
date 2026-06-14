/**
 * ECO Cargo - NUI Communication Composable
 * Handles all communication between Vue frontend and FiveM Lua backend.
 * Uses XMLHttpRequest (fetch is not supported in FiveM NUI environment).
 */

import { ref, onMounted, onUnmounted } from 'vue'

// Resolve resource name dynamically (FiveM provides GetParentResourceName)
const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
  ? GetParentResourceName()
  : 'eco_cargo'

/**
 * Send data to a registered NUI callback on the Lua side
 * @param {string} eventName - NUI callback name (must match RegisterNUICallback)
 * @param {object} data - Payload to send
 * @returns {Promise<any>} Parsed response or false on error
 */
function post(eventName, data = {}) {
  return new Promise((resolve) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', `https://${RESOURCE_NAME}/${eventName}`, true)
    xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          try {
            const parsed = JSON.parse(xhr.responseText)
            resolve(parsed)
          } catch {
            resolve(xhr.responseText)
          }
        } else {
          resolve(false)
        }
      }
    }
    xhr.onerror = function () {
      console.error(`[ECO CARGO] NUI post error: ${eventName}`)
      resolve(false)
    }
    xhr.send(JSON.stringify(data))
  })
}

// Shared message listeners
const listeners = new Set()

// Global message handler (registered once)
let globalListenerRegistered = false

function registerGlobalListener() {
  if (globalListenerRegistered) return
  globalListenerRegistered = true

  window.addEventListener('message', (event) => {
    for (const listener of listeners) {
      listener(event)
    }
  })
}

/**
 * Main NUI composable
 * Provides post() for sending callbacks and onMessage() for listening to Lua SendNUIMessage
 */
export function useNui() {

  /**
   * Register a message listener for NUI messages from Lua
   * Automatically cleans up on component unmount
   * @param {function} handler - Callback receiving the MessageEvent
   */
  function onMessage(handler) {
    registerGlobalListener()
    listeners.add(handler)

    onUnmounted(() => {
      listeners.delete(handler)
    })
  }

  return {
    post,
    onMessage,
    RESOURCE_NAME
  }
}

/**
 * Reactive NUI message hook - subscribes to specific subjects
 * @param {string|string[]} subjects - Subject(s) to listen for
 * @param {function} handler - Callback receiving event.data when subject matches
 */
export function useNuiEvent(subjects, handler) {
  const subjectList = Array.isArray(subjects) ? subjects : [subjects]

  const { onMessage } = useNui()

  onMessage((event) => {
    if (subjectList.includes(event.data?.subject)) {
      handler(event.data)
    }
  })
}

/**
 * Currency formatter (USD)
 */
export const MONEY = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
  minimumFractionDigits: 0
})

/**
 * Format elapsed time
 * @param {number} seconds
 * @returns {{ time: number, unit: string }}
 */
export function formatTime(seconds) {
  if (seconds < 60) return { time: seconds, unit: 'sec' }
  const hours = Math.floor(seconds / 3600)
  if (hours < 1) return { time: Math.floor(seconds / 60), unit: 'min' }
  const minutes = parseFloat((Math.floor(seconds % 3600) / 3600).toFixed(1))
  return { time: hours + minutes, unit: 'h' }
}

/**
 * Check if value is empty (null, undefined, empty object/array)
 */
export function isEmpty(obj) {
  if (obj === null || obj === undefined) return true
  if (Array.isArray(obj)) return obj.length === 0
  if (typeof obj === 'object') return Object.keys(obj).length === 0
  return false
}

/**
 * Safe JSON parse
 */
export function jsonParse(str) {
  if (!str || (typeof str === 'string' && str.trim() === '')) return null
  try { return JSON.parse(str) } catch { return null }
}
