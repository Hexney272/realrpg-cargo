/**
 * ECO Cargo - Helper utilities (Modern vanilla JS)
 */

'use strict';

const MONEY = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0
});

/**
 * Simple string format replacement (%s placeholders)
 * @param {string} str - Template string with %s placeholders
 * @param {...any} args - Values to insert
 * @returns {string}
 */
function formatStr(str, ...args) {
    return args.reduce((p, c) => p.replace(/%s/, c), str);
}

// Keep backward compat with old .format() usage
String.prototype.format = function () {
    return [...arguments].reduce((p, c) => p.replace(/%s/, c), this);
};

/**
 * Convert milliseconds to locale date string
 * @param {number} millisecond
 * @param {string} locale
 * @param {object} options
 * @returns {string}
 */
function millisecond2date(millisecond, locale = 'hu-HU', options = { month: 'short', day: '2-digit' }) {
    return new Date(millisecond).toLocaleDateString(locale, options);
}

/**
 * Format elapsed time into human-readable format
 * @param {number} elapsedTime - Time in seconds
 * @returns {{time: number, unit: string}}
 */
function displayElapsedTime(elapsedTime) {
    if (elapsedTime < 60) {
        return { time: elapsedTime, unit: 'sec' };
    }

    const hours = Math.floor(elapsedTime / 3600);
    let minutes = Math.floor(elapsedTime % 3600) / 3600;
    minutes = parseFloat(minutes.toFixed(1));

    if (hours < 1) {
        return { time: Math.floor(elapsedTime / 60), unit: 'min' };
    }

    return { time: hours + minutes, unit: 'h' };
}

/**
 * Safe JSON parse with fallback
 * @param {string|any} str
 * @returns {any|false}
 */
function jsonParse(str) {
    if (str === undefined || str === null || (typeof str === 'string' && str.trim() === '')) {
        return false;
    }
    try {
        return JSON.parse(str);
    } catch (e) {
        return false;
    }
}

/**
 * Prepare statistics data for display
 * @param {object} data - Raw stat record
 */
function prepareStatData(data) {
    const displayTime = displayElapsedTime(data.working_time);
    const name = `${data.firstname || ''} ${data.lastname || ''}`;

    data.character_name = name.substring(0, 20).trim();
    data.distance = parseFloat((data.distance * 1).toFixed(1));
    data.quality_rate = data.quality_rate ? parseFloat((data.quality_rate * 1).toFixed(1)) : 0;
    data.success_rate = data.success_rate ? parseFloat((data.success_rate * 1).toFixed(1)) : 0;
    data.working_time = displayTime.time * 1;
    data.working_time_unit = displayTime.unit;
    data.registered = millisecond2date(data.registered, 'hu-HU');
    data.last_activity = millisecond2date(data.last_activity, 'hu-HU');
}

/**
 * Get current timestamp in seconds
 * @returns {number}
 */
function getTimeStamp() {
    return Date.now() / 1000;
}

/**
 * Check if an object/array is empty
 * @param {any} obj
 * @returns {boolean}
 */
function isEmpty(obj) {
    if (obj === null || obj === undefined) return true;
    if (Array.isArray(obj)) return obj.length === 0;
    if (typeof obj === 'object') return Object.keys(obj).length === 0;
    return false;
}

/**
 * Post data to NUI callback (replaces $.post)
 * @param {string} eventName - NUI callback name
 * @param {object} data - Data to send
 * @returns {Promise<any>}
 */
async function nuiPost(eventName, data = {}) {
    try {
        const resp = await fetch(`https://eco_cargo/${eventName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        const text = await resp.text();
        return jsonParse(text) || text;
    } catch (e) {
        console.error(`[ECO CARGO] NUI Post error (${eventName}):`, e);
        return false;
    }
}

/**
 * Generate property icons HTML
 * @param {string[]|string} properties - Property names array or JSON string
 * @returns {string} HTML string of icons
 */
function icons(properties) {
    if (typeof properties === 'string') {
        properties = jsonParse(properties);
    }
    if (!properties || isEmpty(properties)) return '';

    return properties.map(v => `<img src='img/${v}.png' class='propertyIcon'>`).join('');
}

/**
 * Select a single element
 * @param {string} selector
 * @param {Element} parent
 * @returns {Element|null}
 */
function $(selector, parent = document) {
    return parent.querySelector(selector);
}

/**
 * Select all elements
 * @param {string} selector
 * @param {Element} parent
 * @returns {NodeList}
 */
function $$(selector, parent = document) {
    return parent.querySelectorAll(selector);
}
