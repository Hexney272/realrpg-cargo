/**
 * ECO Cargo - HUD Module (Modern vanilla JS)
 * Handles delivery info display, notifications, and action prompts
 */

'use strict';

const hudWrapper = document.getElementById('hudWrapper');
const deliveryWrapper = document.getElementById('deliveryWrapper');
const generalWrapper = document.getElementById('generalWrapper');
const actionWrapper = document.getElementById('actionWrapper');

let hud = {};
let monitor = {};
let persistentNotifs = {};

/**
 * Display delivery information HUD
 * @param {object} data - Delivery data from Lua
 */
function deliveryInfo(data) {
    if (isEmpty(data)) return;

    deliveryWrapper.innerHTML = '';

    data.goodsQuality = Math.max(0, data.goodsQuality);
    const properties = jsonParse(data.productProperties);

    const template = document.querySelector('.hud').cloneNode(true);
    template.classList.remove('template');
    template.classList.add('dInfo');

    hud = {
        wheel: $('.wheel', template),
        roll: $('.roll', template),
        damage: $('.damage', template),
        trailerHealth: $('.trailerHealth', template),
        trailerBar: $('.trailerBar', template),
        goodsQuality: $('.goodsQuality', template),
        goodsBar: $('.goodsBar', template),
        speedLimit: $('.speedLimit', template)
    };

    $('.hudProperties', template).innerHTML = icons(properties);
    $('.productName', template).textContent = data.productName;

    hud.trailerBar.style.width = data.trailerHealth + '%';
    hud.goodsBar.style.width = data.goodsQuality + '%';
    hud.trailerHealth.textContent = data.trailerHealth;
    hud.goodsQuality.textContent = data.goodsQuality;
    hud.speedLimit.textContent = data.speedLimit;

    deliveryWrapper.appendChild(template);
    hudWrapper.style.display = 'block';
}

/**
 * Update HUD live data
 * @param {string} paramName - Parameter to update
 * @param {any} value - New value
 */
function updateHud(paramName, value) {
    if (isEmpty(hud)) return;

    switch (paramName) {
        case 'trailerHealth':
            hud.trailerBar.style.width = value + '%';
            hud.trailerHealth.textContent = value;

            if (monitor.damage === undefined) {
                hud.damage.classList.add('alertIcon');
                monitor.damage = true;
                setTimeout(() => {
                    hud.damage.classList.remove('alertIcon');
                    delete monitor.damage;
                }, 5000);
            }
            break;

        case 'goodsQuality':
            value = Math.max(0, value);
            hud.goodsBar.style.width = value + '%';
            hud.goodsQuality.textContent = value;
            break;

        case 'wheel':
            if (monitor.wheel === undefined) {
                hud.wheel.classList.add('alertIcon');
                monitor.wheel = true;
                setTimeout(() => {
                    hud.wheel.classList.remove('alertIcon');
                    delete monitor.wheel;
                }, 5000);
            }
            break;

        case 'roll':
            if (monitor.roll === undefined) {
                hud.roll.classList.add('alertIcon');
                monitor.roll = true;
                setTimeout(() => {
                    hud.roll.classList.remove('alertIcon');
                    delete monitor.roll;
                }, 5000);
            }
            break;

        case 'speedLimit':
            hud.speedLimit.textContent = value;
            break;

        case 'overSpeed':
            if (value === 1) {
                hud.speedLimit.style.color = 'red';
                hud.speedLimit.classList.add('blink');
                monitor.overSpeed = true;
            } else {
                hud.speedLimit.style.color = 'white';
                hud.speedLimit.classList.remove('blink');
            }
            break;
    }
}

/**
 * Show action information (marker enter)
 * @param {object} value - Zone action data
 */
function actionInfo(value) {
    actionWrapper.innerHTML = '';

    const aInfo = document.querySelector('.actionInformation').cloneNode(true);
    aInfo.classList.remove('template');
    aInfo.classList.add('aInfo');

    $('.msgCompanyName', aInfo).textContent = value.name || '';
    $('.msgDescription', aInfo).textContent = value.description || '';
    $('.msgActionMsg', aInfo).textContent = value.message || '';

    aInfo.style.display = '';
    actionWrapper.appendChild(aInfo);
}

/**
 * Create a notification element
 * @param {object} data - {type, text, length, style}
 * @returns {HTMLElement}
 */
function createNotification(data) {
    const notification = document.createElement('div');
    notification.classList.add('notification', data.type);
    notification.innerHTML = data.text;

    if (data.style) {
        Object.entries(data.style).forEach(([prop, val]) => {
            notification.style[prop] = val;
        });
    }

    return notification;
}

/**
 * Show a notification
 * @param {object} data - {type, text, length, style, persist, id}
 */
function ShowNotification(data) {
    if (!data.persist) {
        const notification = createNotification(data);
        generalWrapper.appendChild(notification);

        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transition = 'opacity 0.3s';
            setTimeout(() => notification.remove(), 300);
        }, data.length || 8000);

    } else {
        if (data.persist.toUpperCase() === 'START') {
            if (!persistentNotifs[data.id]) {
                const notification = createNotification(data);
                generalWrapper.appendChild(notification);
                persistentNotifs[data.id] = notification;
            } else {
                const notification = persistentNotifs[data.id];
                notification.className = `notification ${data.type}`;
                notification.innerHTML = data.text;
                if (data.style) {
                    Object.entries(data.style).forEach(([prop, val]) => {
                        notification.style[prop] = val;
                    });
                }
            }
        } else if (data.persist.toUpperCase() === 'END') {
            const notification = persistentNotifs[data.id];
            if (notification) {
                notification.style.opacity = '0';
                notification.style.transition = 'opacity 0.3s';
                setTimeout(() => {
                    notification.remove();
                    delete persistentNotifs[data.id];
                }, 300);
            }
        }
    }
}

/**
 * Close HUD element with fade
 * @param {string} selector
 */
function closeHud(selector) {
    const el = document.querySelector(selector);
    if (el) {
        el.style.opacity = '0';
        el.style.transition = 'opacity 0.3s';
        setTimeout(() => el.remove(), 300);
    }
}
