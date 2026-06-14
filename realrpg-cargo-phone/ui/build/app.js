'use strict';

// ============================================================
// QUASAR PHONE BRIDGE
// ============================================================

const { bridge, api } = QSPhoneBridge.create({
    appId: 'realrpg_cargo',
    targetOrigin: 'https://cfx-nui-qs-smartphone',
});

const RESOURCE_NAME = 'realrpg-cargo-phone'; // Phone resource handles its own NUI callbacks

// Money formatter
const MONEY = new Intl.NumberFormat('hu-HU', { style: 'currency', currency: 'HUF', minimumFractionDigits: 0, maximumFractionDigits: 0 });

// ============================================================
// NUI COMMUNICATION
// ============================================================

function nuiPost(event, data = {}) {
    return new Promise((resolve) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', `https://${RESOURCE_NAME}/${event}`, true);
        xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) resolve(xhr.responseText || 'ok');
        };
        xhr.onerror = function() { resolve(false); };
        xhr.send(JSON.stringify(data));
    });
}

// Listen for NUI messages (SendNUIMessage from Lua goes to nui.html which forwards here)
window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.type) return;

    switch (msg.type) {
        case 'COMPANY_DATA':
            renderCompany(msg.data);
            break;
        case 'CONTRACTS_DATA':
            renderContracts(msg.data);
            break;
        case 'STATS_DATA':
            renderStats(msg.data);
            break;
        case 'ACTION_RESULT':
            if (msg.data && msg.data.message) {
                api.showToastNotification({ title: 'RealRPG Cargo', text: msg.data.message });
            }
            setTimeout(loadData, 500);
            break;
    }
});

// ============================================================
// TAB NAVIGATION
// ============================================================

function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));

    document.getElementById('tab-' + tabName).classList.add('active');
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // Load data when switching tabs
    if (tabName === 'contracts') nuiPost('phone:getContracts');
    if (tabName === 'stats') nuiPost('phone:getStats');
    if (tabName === 'finance') nuiPost('phone:getCompany');
}

// ============================================================
// RENDER FUNCTIONS
// ============================================================

function renderCompany(data) {
    if (data && data.company_name) {
        document.getElementById('company-info').classList.remove('hidden');
        document.getElementById('no-company').classList.add('hidden');

        document.getElementById('company-name').textContent = data.company_name;
        document.getElementById('company-balance').textContent = MONEY.format(data.balance || 0);
        document.getElementById('company-rep').textContent = data.reputation || 0;
        document.getElementById('company-deliveries').textContent = data.total_deliveries || 0;
        document.getElementById('company-employees').textContent = data.employee_count || 0;
        document.getElementById('finance-balance').textContent = MONEY.format(data.balance || 0);

        const roleLabels = { owner: 'Tulajdonos', manager: 'Menedzser', dispatcher: 'Diszpécser', driver: 'Sofőr' };
        document.getElementById('my-role').textContent = roleLabels[data.my_role] || data.my_role;
    } else {
        document.getElementById('company-info').classList.add('hidden');
        document.getElementById('no-company').classList.remove('hidden');
    }
}

function renderContracts(contracts) {
    const list = document.getElementById('contracts-list');
    const noContracts = document.getElementById('no-contracts');

    if (!contracts || contracts.length === 0) {
        list.innerHTML = '';
        noContracts.classList.remove('hidden');
        return;
    }

    noContracts.classList.add('hidden');
    list.innerHTML = contracts.map(c => `
        <div class="contract-card">
            <div class="contract-top">
                <span class="contract-product">${c.product_name || 'Ismeretlen'}</span>
                <span class="contract-reward">${MONEY.format(c.reward)}</span>
            </div>
            <div class="contract-route">
                <span class="material-icons">location_on</span>
                ${c.zone_from_name || '?'} → ${c.zone_to_name || '?'}
            </div>
            <div class="contract-meta">
                <span><span class="material-icons">timer</span>${c.deadline_hours}h</span>
                <span><span class="material-icons">star</span>${c.required_quality}%</span>
                ${c.product_defender ? '<span class="defender-badge">Védett</span>' : ''}
            </div>
            <button class="btn btn-accept" onclick="acceptContract(${c.id})">Elfogadás</button>
        </div>
    `).join('');
}

function renderStats(data) {
    if (!data) return;

    const allDone = (data.done_delivery || 0) + (data.done_mission || 0);
    const allStarted = (data.started_delivery || 0) + (data.started_mission || 0);
    const quality = allDone > 0 ? Math.round((data.goods_quality || 0) / allDone) : 0;
    const success = allStarted > 0 ? Math.round((allDone / allStarted) * 100) : 0;

    document.getElementById('stat-deliveries').textContent = allDone;
    document.getElementById('stat-distance').textContent = Math.round(data.distance || 0) + ' km';
    document.getElementById('stat-quality').textContent = quality + '%';
    document.getElementById('stat-success').textContent = success + '%';
}

// ============================================================
// ACTIONS
// ============================================================

function acceptContract(contractId) {
    nuiPost('phone:acceptContract', { contractId });
    api.showToastNotification({ title: 'RealRPG Cargo', text: 'Szerződés elfogadva!' });
    setTimeout(() => nuiPost('phone:getContracts'), 1000);
}

function doDeposit() {
    const amount = parseInt(document.getElementById('finance-amount').value);
    if (!amount || amount <= 0) return;
    nuiPost('phone:deposit', { amount });
    document.getElementById('finance-amount').value = '';
}

function doWithdraw() {
    const amount = parseInt(document.getElementById('finance-amount').value);
    if (!amount || amount <= 0) return;
    nuiPost('phone:withdraw', { amount });
    document.getElementById('finance-amount').value = '';
}

// ============================================================
// INIT
// ============================================================

function loadData() {
    nuiPost('phone:getCompany');
    nuiPost('phone:getStats');
}

api.onReady(() => {
    console.log('[RealRPG Cargo Phone] Bridge ready');
    loadData();
});
