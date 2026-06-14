/**
 * ECO Cargo - Main Application (Modern vanilla JS)
 * Handles all NUI page rendering, form submissions, and message routing
 */

'use strict';

let disableMissionStartForDefenders = false;
let missionOrderBy = 'all_started';
let lastEventTime = 0;
const floodProtectionTime = 3; // in sec
const floodMessage = `Flood protection: Wait ${floodProtectionTime} seconds`;

// ============================================================
// PAGE MANAGEMENT
// ============================================================

function closePage() {
    const page = document.getElementById('page');
    const wrapper = document.querySelector('.pageWrapper');

    page.style.display = 'none';
    page.innerHTML = '';
    wrapper.style.display = 'none';
}

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

function inMission(cargo, currentZone, player, mission) {
    let isMission = false;
    let isOwned = false;
    let inProgress = false;

    if (cargo.defender !== '' && !isEmpty(mission)) {
        for (const key in mission) {
            const [loadingZoneId, productId] = key.split('_');

            if (productId == cargo.id && loadingZoneId == currentZone.id) {
                isMission = true;
                if (mission[key].owner.identifier === player.identifier) isOwned = true;
                if (mission[key].trailerPlate) inProgress = true;
            }
        }
    }

    return { isMission, isOwned, inProgress };
}

function playerIsDefender(missionList, player) {
    if (isEmpty(missionList)) return false;

    for (const key in missionList) {
        const defenders = missionList[key].joined;
        if (!isEmpty(defenders)) {
            for (const k in defenders) {
                if (defenders[k] === player.identifier) return key;
            }
        }
    }
    return false;
}

function playerIsConfidential(mission, player) {
    if (player.group === 'superadmin') return true;
    if (player.identifier === mission.owner.identifier) return true;
    if (player.job.name === mission.defender) return true;
    return false;
}

function floodCheck() {
    if (lastEventTime + floodProtectionTime < getTimeStamp()) {
        lastEventTime = getTimeStamp();
        return true;
    }
    ShowNotification({ type: 'warning', text: floodMessage });
    return false;
}

// ============================================================
// CARGO SELECT PAGE
// ============================================================

function openCargoSelect(shipments, currentZone, player, mission) {
    if (isEmpty(shipments)) return;

    const pageWrapper = document.querySelector('.pageWrapper');
    const titleContainer = $('.titleContainer', pageWrapper);
    const page = document.getElementById('page');

    titleContainer.style.display = 'block';
    $('.title', pageWrapper).textContent = currentZone.name;
    $('.description', pageWrapper).textContent = `${currentZone.address}, ${currentZone.description}`;

    const cargoItemTemplate = document.querySelector('.cargoItem');
    const rowTemplate = document.querySelector('.cargoDestinationTableRow');

    Object.values(shipments).forEach(cargo => {
        if (!cargo) return;

        const missionInfo = inMission(cargo, currentZone, player, mission);
        const hasRemainingTime = cargo.remainingTime !== 0;
        const playerInDefenderJob = player.job.name === cargo.defender;
        const properties = jsonParse(cargo.properties);

        const cargoItem = cargoItemTemplate.cloneNode(true);
        cargoItem.style.display = 'grid';
        cargoItem.classList.remove('template');

        if (!isEmpty(cargo.destinationZones)) {
            const table = $('.cargoDestinationTable', cargoItem);

            Object.values(cargo.destinationZones).forEach(dZone => {
                const tr = rowTemplate.cloneNode(true);
                tr.classList.remove('template');
                tr.style.display = '';

                if (hasRemainingTime || (playerInDefenderJob && disableMissionStartForDefenders)) {
                    tr.classList.add('disabled');
                } else {
                    tr.addEventListener('click', () => {
                        page.querySelectorAll('.cargoDestinationTableRow').forEach(r => r.classList.remove('trSelected'));
                        page.querySelectorAll('.submit').forEach(b => b.style.display = 'none');
                        page.querySelectorAll('.missionRegister').forEach(b => b.style.display = 'none');

                        tr.classList.add('trSelected');

                        if ((!missionInfo.isMission && !player.InMission) || missionInfo.isOwned) {
                            cargoItem.querySelector('input[name="targetData"]').value = JSON.stringify({
                                km: dZone.distance,
                                destinationId: dZone.id,
                                freightFee: dZone.priceData.freightFee,
                                illegalPrice: dZone.priceData.illegalPrice
                            });

                            if (cargo.defender === '' || (missionInfo.isOwned && !missionInfo.inProgress)) {
                                $('.submit', cargoItem).style.display = 'inline-block';
                            }
                            if (cargo.defender !== '' && (missionInfo.isOwned || !missionInfo.inProgress)) {
                                $('.missionRegister', cargoItem).style.display = 'inline-block';
                            }
                        }
                    });
                }

                if (missionInfo.isMission) {
                    tr.classList.add('inMission');
                    $('.missionInfo', cargoItem).style.display = 'inline-block';
                }

                $('.cargoName', tr).textContent = dZone.name;
                $('.cargoDescription', tr).textContent = dZone.description;
                $('.cautionMoney', tr).textContent = MONEY.format(cargo.caution_money);
                $('.cargoDistance', tr).textContent = `${dZone.distance} Km`;
                $('.freightFee', tr).textContent = MONEY.format(dZone.priceData.freightFee);

                table.appendChild(tr);
            });
        }

            if (cargo.defender !== '') {
            const defEl = $('.cargoDefenders', cargoItem);
            if (defEl) defEl.innerHTML = `Védelem:<br />(${cargo.required_defenders} fő) ${cargo.defenderLabel}`;
        }

        $('.itemImg', cargoItem).style.backgroundImage = `url('img/${cargo.trailer}.jpg')`;
        $('.itemHeader', cargoItem).textContent = cargo.label;
        const descEl = $('.description', cargoItem);
        if (descEl) descEl.textContent = cargo.description || '';
        $('.icons', cargoItem).innerHTML = icons(properties);

        if (hasRemainingTime || (playerInDefenderJob && disableMissionStartForDefenders)) {
            $('.itemHeader', cargoItem).classList.add('disabled');
            const alertEl = $('.availableAlert', cargoItem);
            alertEl.classList.add('noAvailable');
            alertEl.textContent = hasRemainingTime ? cargo.remainingTimeDisplay : 'Vedokent nem indithato';
        }

        cargoItem.querySelector('input[name="freightData"]').value = JSON.stringify({
            trailerModel: cargo.trailer,
            cautionMoney: cargo.caution_money,
            goodsValue: cargo.value,
            productId: cargo.id,
        });

        cargoItem.querySelector('input[name="params"]').value = cargo.params;
        $('.form', cargoItem).setAttribute('name', cargo.name);

        // Form submit handler
        $('.form', cargoItem).addEventListener('submit', async (e) => {
            e.preventDefault();

            const cargoData = {
                ...JSON.parse(cargoItem.querySelector('input[name="freightData"]').value),
                ...JSON.parse(cargoItem.querySelector('input[name="targetData"]').value),
                params: cargoItem.querySelector('input[name="params"]').value,
                required_defenders: cargo.required_defenders,
                defender: cargo.defender,
                loadingZoneId: currentZone.id
            };

            if (cargo.defender !== '') {
                const response = await nuiPost('checkDefense', cargoData);
                if (response && response.message) {
                    ShowNotification({ type: response.type, text: response.message });
                }
                if (response && response.state) {
                    closePage();
                    nuiPost('registerCargo', cargoData);
                }
            } else {
                closePage();
                nuiPost('registerCargo', cargoData);
            }
        });

        // Mission register button
        $('.missionRegister', cargoItem).addEventListener('click', async () => {
            const cargoData = {
                ...JSON.parse(cargoItem.querySelector('input[name="freightData"]').value),
                ...JSON.parse(cargoItem.querySelector('input[name="targetData"]').value),
                params: cargoItem.querySelector('input[name="params"]').value,
                required_defenders: cargo.required_defenders,
                defender: cargo.defender,
                loadingZoneId: currentZone.id
            };

            const response = await nuiPost('missionRegister', cargoData);
            if (response && response.message) {
                ShowNotification({ type: response.type, text: response.message });
            }
            if (response && response.state) {
                cargoItem.querySelectorAll('tr').forEach(r => r.classList.add('inMission'));
                $('.missionInfo', cargoItem).style.display = 'inline-block';
                player.InMission = true;
                missionInfo.isOwned = true;
            }
        });

        page.appendChild(cargoItem);
    });

    pageWrapper.style.display = 'block';
    page.style.display = 'block';
}

// ============================================================
// MISSION LIST PAGE
// ============================================================

function openMissionList(missionList, player) {
    if (isEmpty(missionList)) return;

    const pageWrapper = document.querySelector('.pageWrapper');
    const page = document.getElementById('page');
    const titleContainer = $('.titleContainer', pageWrapper);

    titleContainer.style.display = 'block';
    $('.title', pageWrapper).textContent = 'Kuldetes lista';
    $('.description', pageWrapper).textContent = 'Csatlakozhatsz vedonek, jelolheted a rakodasi hely es a celallomas pontokat.';

    const isDefender = playerIsDefender(missionList, player);
    const missionItemTemplate = document.querySelector('.missionItem');

    Object.entries(missionList).forEach(([key, mission]) => {
        const properties = jsonParse(mission.product.properties);
        const missionItem = missionItemTemplate.cloneNode(true);
        missionItem.style.display = 'grid';
        missionItem.classList.remove('template');

        const isConfidentialPlayer = playerIsConfidential(mission, player);

        $('.icons', missionItem).innerHTML = icons(properties);
        $('.itemHeader', missionItem).textContent = mission.product.label;
        $('.itemImg', missionItem).style.backgroundImage = `url('img/${mission.product.trailer}.jpg')`;
        $('.missionLoadingAddress', missionItem).textContent = mission.loadingZone.address;
        $('.missionOwner', missionItem).textContent = isConfidentialPlayer ? mission.owner.characterName : 'Bizalmas informacio';
        $('.missionDefender', missionItem).textContent = isConfidentialPlayer ? mission.product.defenderLabel : '?';
        $('.missionJoined', missionItem).textContent = isConfidentialPlayer ? Object.keys(mission.joined).length : '?';

        // Waypoint buttons
        const waypointBtn = $('.missionSetWaypoint', missionItem);
        waypointBtn.addEventListener('click', () => {
            nuiPost('setWaypoint', { missionId: key });
            closePage();
        });

        if (isDefender && isDefender === key && mission.destinationZoneId) {
            const destBtn = $('.missionSetDestinationWaypoint', missionItem);
            destBtn.style.display = 'block';
            destBtn.addEventListener('click', () => {
                nuiPost('setDestinationWaypoint', { missionId: key });
                closePage();
            });
        }

        // Join button
        if (mission.owner.identifier !== player.identifier && !isDefender && mission.product.defender === player.job.name) {
            if (floodCheck()) {
                const joinBtn = $('.join', missionItem);
                joinBtn.classList.remove('hide');
                joinBtn.addEventListener('click', () => {
                    nuiPost('missionJoin', { missionId: key, defender: mission.product.defender, owner: mission.owner, player });
                    closePage();
                });
            }
        }

        // Leave button
        if (mission.owner.identifier !== player.identifier && key === isDefender) {
            if (floodCheck()) {
                const leaveBtn = $('.leave', missionItem);
                leaveBtn.classList.remove('hide');
                leaveBtn.addEventListener('click', () => {
                    nuiPost('missionLeave', { missionId: key, defender: mission.product.defender, owner: mission.owner, player });
                    closePage();
                });
            }
        }

        // Delete button
        if (mission.owner.identifier === player.identifier && !mission.trailerPlate) {
            const deleteBtn = $('.delete', missionItem);
            deleteBtn.classList.remove('hide');
            deleteBtn.addEventListener('click', () => {
                nuiPost('missionDelete', { missionId: key, defender: mission.product.defender });
                closePage();
            });
        }

        page.appendChild(missionItem);
    });

    pageWrapper.style.display = 'block';
    page.style.display = 'block';
}

// ============================================================
// CARGO REPORT PAGE
// ============================================================

function openCargoPage(report) {
    if (isEmpty(report)) return;

    const pageWrapper = document.querySelector('.pageWrapper');
    const page = document.getElementById('page');
    page.innerHTML = '';

    const reportTmp = document.querySelector('.cargoReport').cloneNode(true);
    reportTmp.classList.remove('template');

    $('.title', pageWrapper).textContent = 'Szallitoievel';
    $('.description', pageWrapper).textContent = '';

    $('.employeeName', reportTmp).textContent = report.owner.characterName;
    $('.productName', reportTmp).textContent = report.product.name;
    $('.propNames', reportTmp).textContent = report.product.propnames;

    $('.senderCompany', reportTmp).textContent = report.loadingZone.name;
    $('.senderAddress', reportTmp).textContent = report.loadingZone.address;
    $('.senderDescription', reportTmp).textContent = report.loadingZone.description;
    $('.itemImg', reportTmp).style.backgroundImage = `url('img/${report.product.trailer}.jpg')`;

    $('.deliveryCompany', reportTmp).textContent = report.targetZone.name;
    $('.deliveryAddress', reportTmp).textContent = report.targetZone.address;
    $('.deliveryDescription', reportTmp).textContent = report.targetZone.description;

    $('.km', reportTmp).textContent = report.km;
    $('.plate', reportTmp).textContent = report.trailerPlate;

    $('.trailerDamage', reportTmp).textContent = `(trailer) ${Math.round(report.trailerHealth * 0.1)} %`;
    $('.goodsDamage', reportTmp).textContent = `(rakomany) ${Math.round(report.quality)} %`;
    $('.maxSpeedCountry', reportTmp).textContent = `${report.maxSpeed.country} Km/h`;
    $('.maxSpeedCity', reportTmp).textContent = `${report.maxSpeed.city} Km/h`;

    // Payment section
    if (report.showPayData) {
        const paymentContainer = $('#paymentContainer', reportTmp);
        let payTable;

        if (report.stolen) {
            payTable = document.getElementById('illegalPaymentTable').cloneNode(true);
            $('.freightFee', payTable).textContent = MONEY.format(report.illegalPrice);
        } else {
            payTable = document.getElementById('legalPaymentTable').cloneNode(true);
            $('.cautionMoney', payTable).textContent = MONEY.format(report.cautionMoney);
            $('.cautionDeduction', payTable).textContent = MONEY.format(report.payData.cautionDeduction);
            $('.cautionPayment', payTable).textContent = MONEY.format(report.payData.cautionPayment);
            $('.freightFee', payTable).textContent = MONEY.format(report.payData.freightFee);
        }

        $('.trailerDamage', payTable).textContent = `(trailer) ${Math.round(report.trailerHealth * 0.1)} %`;
        $('.goodsDamage', payTable).textContent = `(rakomany) ${Math.round(report.quality)} %`;
        $('.priceDeduction', payTable).textContent = MONEY.format(report.payData.priceDeduction);
        $('.pricePayment', payTable).textContent = MONEY.format(report.payData.pricePayment);
        $('.payable', payTable).textContent = MONEY.format(report.payData.payable);

        if (!isNaN(report.payData.defenderSocietyPayable) && report.payData.defenderSocietyPayable > 0) {
            const societyRow = $('.societyPayableTr', payTable);
            if (societyRow) societyRow.style.display = 'table-row';
            $('.defenderSocietyPayable', payTable).textContent = MONEY.format(report.payData.defenderSocietyPayable);
        }

        payTable.classList.remove('template');
        paymentContainer.appendChild(payTable);
    }

    page.appendChild(reportTmp);
    pageWrapper.style.display = 'block';
    page.style.display = 'block';
}

// ============================================================
// MAINTENANCE PAGE
// ============================================================

function openMaintenance(data) {
    if (isEmpty(data)) return;

    const pageWrapper = document.querySelector('.pageWrapper');
    const titleContainer = $('.titleContainer', pageWrapper);
    titleContainer.style.display = 'none';

    const page = document.getElementById('page');
    page.innerHTML = '';

    const mntTmp = document.querySelector('.mnt').cloneNode(true);
    mntTmp.classList.remove('template');

    $('.countProducts', mntTmp).textContent = data.countProducts;
    $('.countProductsMarker', mntTmp).classList.add(data.countProducts > 0 ? 'good' : 'fault');

    if (!isEmpty(data.orphanProduct)) {
        $('.orphanProduct', mntTmp).innerHTML = '<ul>' + data.orphanProduct.map(p => `<li>${p.id}. ${p.transName}</li>`).join('') + '</ul>';
    }
    $('.orphanProductMarker', mntTmp).classList.add(isEmpty(data.orphanProduct) ? 'good' : 'fault');

    $('.countRoutes', mntTmp).textContent = data.countRoutes;
    $('.countRoutesMarker', mntTmp).classList.add(data.countRoutes > 0 ? 'good' : 'fault');
    $('.countUniqueRoutes', mntTmp).textContent = data.countUniqueRoutes;
    $('.countUniqueRoutesMarker', mntTmp).classList.add(data.countUniqueRoutes > 0 ? 'good' : 'fault');
    $('.wrongDistanceRecord', mntTmp).textContent = data.wrongDistanceRecord;
    $('.wrongDistanceRecordMarker', mntTmp).classList.add(data.wrongDistanceRecord === 0 ? 'good' : 'fault');

    if (!isEmpty(data.orphanDistanceRecord)) {
        $('.orphanDistanceRecord', mntTmp).innerHTML = '<ul>' + data.orphanDistanceRecord.map(id => `<li>${id}</li>`).join('') + '</ul>';
    }
    $('.orphanDistanceRecordMarker', mntTmp).classList.add(isEmpty(data.orphanDistanceRecord) ? 'good' : 'fault');

    $('.missingDistanceRecord', mntTmp).textContent = data.missingDistanceRecord;
    $('.missingDistanceRecordMarker', mntTmp).classList.add(data.missingDistanceRecord === 0 ? 'good' : 'fault');
    $('.countActionPoints', mntTmp).textContent = data.countActionPoints;
    $('.countActionPointsMarker', mntTmp).classList.add(data.countActionPoints > 0 ? 'good' : 'fault');

    if (!isEmpty(data.missingActionPoints)) {
        const items = Object.values(data.missingActionPoints).map(v => `<li>Zone: ${v.zoneId}, Product: ${v.productId}. ${v.productLabel}</li>`);
        $('.missingActionPoints', mntTmp).innerHTML = '<ul>' + items.join('') + '</ul>';
    }
    $('.missingActionPointsMarker', mntTmp).classList.add(isEmpty(data.missingActionPoints) ? 'good' : 'fault');

    if (!isEmpty(data.orphanActionPoints)) {
        const items = data.orphanActionPoints.map(v => `<li>${v.id}. ${v.name}</li>`);
        $('.orphanActionPoints', mntTmp).innerHTML = '<ul>' + items.join('') + '</ul>';
    }
    $('.orphanActionPointsMarker', mntTmp).classList.add(isEmpty(data.orphanActionPoints) ? 'good' : 'fault');

    $('.missingLocales', mntTmp).textContent = JSON.stringify(data.missingLocales);

    // Distance calc button
    $('.distanceBtn', mntTmp).addEventListener('click', () => {
        nuiPost('distanceCalc', {});
        closePage();
    });

    // Show zones button
    $('.showAllActionPointBtn', mntTmp).addEventListener('click', () => {
        nuiPost('showAllActionPoints', {});
        closePage();
    });

    page.appendChild(mntTmp);
    pageWrapper.style.display = 'block';
    page.style.display = 'block';
}

// ============================================================
// STATISTICS PAGE
// ============================================================

function openStatistics(data, statType = 'myStatistics') {
    const pageWrapper = document.querySelector('.pageWrapper');
    const titleContainer = $('.titleContainer', pageWrapper);
    titleContainer.style.display = 'none';

    const page = document.getElementById('page');
    page.innerHTML = '';

    const statisticsContainer = document.querySelector('.statisticsContainer').cloneNode(true);
    statisticsContainer.classList.remove('template');
    const statisticsContent = $('.statisticsContent', statisticsContainer);

    // Tab buttons
    if (statType !== 'myStatistics') {
        $('#myStatisticsBtn', statisticsContainer).addEventListener('click', () => {
            if (floodCheck()) nuiPost('myStatistics', {});
        });
    }
    if (statType !== 'allStatistics') {
        $('#summaryStatisticsBtn', statisticsContainer).addEventListener('click', async () => {
            if (floodCheck()) {
                const resp = await nuiPost('getAllStatistics', { orderBy: missionOrderBy });
                if (resp) openStatistics(resp, 'allStatistics');
            }
        });
    }
    if (statType !== 'ranks') {
        $('#ranksBtn', statisticsContainer).addEventListener('click', async () => {
            if (floodCheck()) {
                const resp = await nuiPost('getRanks', {});
                if (resp) openStatistics(resp, 'ranks');
            }
        });
    }

    // Content rendering
    if (statType === 'allStatistics' && !isEmpty(data)) {
        const summaryStats = document.querySelector('.summaryStatistics').cloneNode(true);
        summaryStats.classList.remove('template');
        const container = $('.summaryStatisticsItemContainer', summaryStats);
        const itemTmp = $('.summaryStatisticsItem', container);
        container.classList.remove('template');

        // Set selected orderBy
        const select = $('select', container);
        if (select) {
            select.value = missionOrderBy;
            setTimeout(() => select.disabled = false, floodProtectionTime * 1000);
        }

        data.forEach((cData, i) => {
            const item = itemTmp.cloneNode(true);
            item.classList.remove('template');
            item.style.display = '';

            prepareStatData(cData);
            const failedCargo = cData.all_started - cData.all_done;

            item.classList.add('itemStyle' + cData.rank);
            $('.summaryStatValueName', item).textContent = `${i + 1}. ${cData.character_name}`;
            const titleLabel = $('.summaryStatValueTitleLabel', item);
            titleLabel.textContent = cData.titleLabel;
            titleLabel.classList.add('labelStyle' + cData.rank);
            const rankLabel = $('.summaryStatValueRankLabel', item);
            rankLabel.textContent = cData.rankLabel;
            rankLabel.classList.add('labelStyle' + cData.rank);
            $('.summaryStatValueDistance', item).textContent = `${cData.distance} km`;
            $('.summaryStatValueAllStarted', item).textContent = `${cData.all_started} fuvar`;

            const failedEl = $('.summaryStatValueFailed', item);
            if (failedCargo > 0) {
                failedEl.textContent = `${failedCargo} sikertelen`;
            } else if (failedEl) {
                failedEl.remove();
            }

            $('.summaryStatValueVulnerable', item).textContent = `${cData.vulnerable} serulekeny`;
            $('.summaryStatValueWorkingTime', item).textContent = `${cData.working_time} ${cData.working_time_unit}`;
            $('.summaryStatValueQualityRate', item).textContent = `${cData.quality_rate}% elegedettseg`;
            $('.summaryStatValueSuccessRate', item).textContent = `${cData.success_rate}% sikeresseg`;
            $('.summaryStatValueDates', item).textContent = `${cData.registered} - ${cData.last_activity}`;

            // Dropdown toggle
            item.addEventListener('click', () => {
                const dropdown = $('.statisticsItemDropDown', item);
                const content = $('.statisticsItemDropDownContent', item);
                if (dropdown.offsetHeight > 0) {
                    dropdown.style.height = '0';
                } else {
                    dropdown.style.height = content.offsetHeight + 'px';
                }
            });

            container.appendChild(item);
        });

        statisticsContent.appendChild(summaryStats);

    } else if (statType === 'myStatistics' && !isEmpty(data)) {
        prepareStatData(data);

        const myStats = document.querySelector('.myStatistics').cloneNode(true);
        myStats.classList.remove('template');
        myStats.style.display = '';

        $('.qualityRate', myStats).textContent = `${data.quality_rate}%`;
        $('.successRate', myStats).textContent = `${data.success_rate}%`;
        $('.distance', myStats).textContent = data.distance;
        $('.workingTime', myStats).textContent = data.working_time;
        $('.timeUnit', myStats).textContent = data.working_time_unit;
        $('.registeredTime', myStats).textContent = data.registered;
        $('.allStarted', myStats).textContent = data.all_started;
        $('.startedMission', myStats).textContent = data.started_mission;
        $('.startedDelivery', myStats).textContent = data.started_delivery;
        $('.allDone', myStats).textContent = data.all_done;
        $('.doneMission', myStats).textContent = data.done_mission;
        $('.doneDelivery', myStats).textContent = data.done_delivery;
        $('.vulnerable', myStats).textContent = data.vulnerable;
        $('.defender', myStats).textContent = data.defender;
        $('.allStolen', myStats).textContent = data.all_stolen;
        $('.stolenMission', myStats).textContent = data.stolen_mission;
        $('.stolenDelivery', myStats).textContent = data.stolen_delivery;
        $('.destroyedTrailer', myStats).textContent = data.destroyed_trailer;

        statisticsContent.appendChild(myStats);

    } else if (statType === 'ranks' && data) {
        const rankList = document.querySelector('.rankList').cloneNode(true);
        rankList.classList.remove('template');
        rankList.style.display = '';

        const tableContainer = $('.tableContainer', rankList);
        const { titles, ranks, rankLabels, titleLabels } = data;

        // Title table
        let titleHtml = '<table class="statisticsTitles tblTheme3"><tr><th>Cim</th><th>Kilometer</th><th>Rang</th></tr>';
        titles.forEach((t, i) => {
            titleHtml += `<tr><td>${titleLabels[i]}</td><td>${t.distance}</td><td>${rankLabels[t.rank - 1]}</td></tr>`;
        });
        titleHtml += '</table>';

        // Rank table
        let rankHtml = '<table class="statisticsRanks tblTheme3"><tr><th>Rang</th><th>Serulekeny</th><th>Fuvarok</th><th>Elegedettseg</th><th>Sikeresseg</th></tr>';
        ranks.forEach((r, i) => {
            rankHtml += `<tr><td>${rankLabels[i]}</td><td>${r.vulnerable}</td><td>${r.all_done}</td><td>${r.quality_rate}%</td><td>${r.success_rate}%</td></tr>`;
        });
        rankHtml += '</table>';

        tableContainer.innerHTML = titleHtml + rankHtml;
        statisticsContent.appendChild(rankList);
    }

    page.appendChild(statisticsContainer);
    pageWrapper.style.display = 'block';
    page.style.display = 'block';
}

// ============================================================
// ORDER BY (statistics)
// ============================================================

async function orderBy(selectMenu) {
    if (!floodCheck()) return;

    missionOrderBy = selectMenu.value;
    const resp = await nuiPost('getAllStatistics', { orderBy: missionOrderBy });
    if (resp) openStatistics(resp, 'allStatistics');
}

// ============================================================
// NUI MESSAGE ROUTER
// ============================================================

window.addEventListener('message', (event) => {
    const item = event.data;

    switch (item.subject) {
        // HUD
        case 'UPDATE':
            updateHud(item.paramName, item.value);
            break;

        case 'CLOSE_INFO':
            closeHud('.dInfo');
            closeHud('.aInfo');
            break;

        case 'DELIVERY_INFO':
            if (item.operation === 'close') {
                closeHud('.dInfo');
            } else {
                deliveryInfo(item.deliveryData);
            }
            break;

        case 'ACTION_INFO':
            if (item.operation === 'close') {
                closeHud('.aInfo');
            } else if (document.getElementById('page').style.display !== 'block') {
                actionInfo(item.actionData);
            }
            break;

        case 'NOTIFICATION':
            ShowNotification(item);
            break;

        case 'ACHIEVEMENT':
            showAchievementPopup(item.achievement);
            break;

        // PAGES
        case 'CARGO_SELECT':
            closePage();
            closeHud('.aInfo');
            disableMissionStartForDefenders = item.disableMissionStartForDefenders;
            openCargoSelect(item.data, item.currentZone, item.player, item.mission);
            break;

        case 'CARGO_REPORT':
            closePage();
            openCargoPage(item.data);
            break;

        case 'MISSION_LIST':
            closePage();
            openMissionList(item.mission, item.player);
            break;

        case 'MAINTENANCE':
            closePage();
            openMaintenance(item.data);
            break;

        case 'STATISTICS':
            closePage();
            openStatistics(item.data);
            break;

        case 'CLOSE_PAGE':
            closePage();
            break;
    }
});

// ============================================================
// GLOBAL EVENT HANDLERS
// ============================================================

// Close button
document.querySelector('.btnClose').addEventListener('click', () => {
    closePage();
    nuiPost('exit', {});
});

// Escape / Backspace key
document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape' || e.key === 'Backspace') {
        closePage();
        nuiPost('exit', {});
    }
});



// ============================================================
// ACHIEVEMENT POPUP
// ============================================================

function showAchievementPopup(achievement) {
    const popup = document.createElement('div');
    popup.className = 'achievement-popup';
    popup.innerHTML = `
        <div class="achievement-icon">
            <span class="material-icons">${achievement.icon || 'emoji_events'}</span>
        </div>
        <div class="achievement-content">
            <div class="achievement-title">Achievement Unlocked!</div>
            <div class="achievement-name">${achievement.name || 'Unknown'}</div>
            <div class="achievement-desc">${achievement.description || ''}</div>
        </div>
    `;

    document.body.appendChild(popup);

    // Animate in
    requestAnimationFrame(() => {
        popup.classList.add('show');
    });

    // Remove after 6 seconds
    setTimeout(() => {
        popup.classList.remove('show');
        popup.classList.add('hide');
        setTimeout(() => popup.remove(), 500);
    }, 6000);
}
