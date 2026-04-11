const searchForm = document.getElementById('searchForm');
const reservationForm = document.getElementById('reservationForm');
const locationForm = document.getElementById('locationForm');
const convertForm = document.getElementById('convertForm');
const results = document.getElementById('results');

const defaultChains = [
  'Marriott International',
  'Hilton Worldwide',
  'Hyatt Hotels Corporation',
  'IHG Hotels & Resorts',
  'Accor',
  'Wyndham Hotels & Resorts',
  'Choice Hotels',
  'Best Western'
];

const defaultZones = [
  'Ottawa Centre',
  'Toronto Waterfront',
  'Montreal Centre',
  'Vancouver Bay',
  'Halifax Centre',
  'St Johns Port',
  'Times Square',
  'London Centre',
  'Paris Centre',
  'Shibuya',
  'Bangkok Centre'
];

let dataLoadRunId = 0;

function showMessage(text) {
  const activeTab = document.querySelector('.tab-content.active');
  if (activeTab) {
    const message = activeTab.querySelector('.message');
    if (message) {
      message.style.display = 'block';
      message.textContent = text;
    }
  }
}

async function loadSelect(url, selectElement) {
  try {
    const response = await fetch(url);
    let data = await response.json();
    const firstOption = selectElement.querySelector('option');
    selectElement.innerHTML = firstOption ? firstOption.outerHTML : '<option value="">Sélectionner</option>';

    if (!Array.isArray(data) || data.length === 0) {
      if (selectElement.name === 'chaine') {
        data = defaultChains;
      } else if (selectElement.name === 'zone') {
        data = defaultZones;
      } else {
        data = [];
      }
    }

    data.forEach(item => {
      const option = document.createElement('option');
      if (typeof item === 'string' && item.includes(':')) {
        const [id, name] = item.split(': ', 2);
        option.value = id;
        option.textContent = item;
      } else {
        option.value = item;
        option.textContent = item;
      }
      selectElement.appendChild(option);
    });
  } catch (e) {
    console.error('Erreur lors du chargement:', e);
    if (selectElement.name === 'chaine') {
      defaultChains.forEach(chain => {
        const option = document.createElement('option');
        option.value = chain;
        option.textContent = chain;
        selectElement.appendChild(option);
      });
    } else if (selectElement.name === 'zone') {
      defaultZones.forEach(zone => {
        const option = document.createElement('option');
        option.value = zone;
        option.textContent = zone;
        selectElement.appendChild(option);
      });
    }
  }
}

async function loadData() {
  await loadSelect('/api/clients', reservationForm.querySelector('[name=clientId]'));
  await loadSelect('/api/clients', locationForm.querySelector('[name=clientId]'));
  await loadSelect('/api/allrooms', reservationForm.querySelector('[name=chambreId]'));
  await loadSelect('/api/allrooms', locationForm.querySelector('[name=chambreId]'));
  await loadSelect('/api/employees', locationForm.querySelector('[name=employeId]'));
  await loadSelect('/api/employees', convertForm.querySelector('[name=employeId]'));
  await loadSelect('/api/reservations', convertForm.querySelector('[name=reservationId]'));
  await loadSelect('/api/reservations', locationForm.querySelector('[name=reservationId]'));
  await loadSelect('/api/chains', searchForm.querySelector('[name=chaine]'));
  await loadSelect('/api/zones', searchForm.querySelector('[name=zone]'));
  await loadSelect('/api/reservations', document.getElementById('archiveReservationSelect'));
  await loadSelect('/api/locations', document.getElementById('archiveLocationSelect'));
  await loadReservationsList();
  await loadCurrentReservations();
}

// Handle radio button change for location type
locationForm.querySelectorAll('[name=type]').forEach(radio => {
  radio.addEventListener('change', (e) => {
    const directFields = document.getElementById('directFields');
    const conversionFields = document.getElementById('conversionFields');
    if (e.target.value === 'direct') {
      directFields.style.display = 'grid';
      conversionFields.style.display = 'none';
      locationForm.querySelector('[name=reservationId]').required = false;
      locationForm.querySelector('[name=clientId]').required = true;
      locationForm.querySelector('[name=chambreId]').required = true;
      locationForm.querySelector('[name=dateDebut]').required = true;
      locationForm.querySelector('[name=dateFin]').required = true;
    } else {
      directFields.style.display = 'none';
      conversionFields.style.display = 'grid';
      locationForm.querySelector('[name=reservationId]').required = true;
      locationForm.querySelector('[name=clientId]').required = false;
      locationForm.querySelector('[name=chambreId]').required = false;
      locationForm.querySelector('[name=dateDebut]').required = false;
      locationForm.querySelector('[name=dateFin]').required = false;
    }
  });
});

async function loadReservationsList() {
  const listDiv = document.getElementById('reservationsList');
  try {
    const response = await fetch('/api/reservations');
    const reservations = await response.json();

    if (!reservations.length) {
      listDiv.innerHTML = '<p style="text-align: center; color: #999;">Aucune réservation disponible</p>';
      return;
    }

    let html = '<table style="width: 100%; border-collapse: collapse;">';
    html += '<thead><tr style="border-bottom: 2px solid #ddd; background: #f9fafb;"><th style="padding: 12px; text-align: left; font-weight: 600;">ID</th><th style="padding: 12px; text-align: left; font-weight: 600;">Client</th><th style="padding: 12px; text-align: left; font-weight: 600;">Montant</th></tr></thead>';
    html += '<tbody>';

    reservations.forEach((res) => {
      html += '<tr style="border-bottom: 1px solid #eee; hover: { background: #f1f9ff; }">';
      html += `<td style="padding: 12px; color: #667eea; font-weight: 600;">${res.split(': ')[0]}</td>`;
      html += `<td style="padding: 12px;">${res.split(': ')[1] || 'N/A'}</td>`;
      html += `<td style="padding: 12px;">En cours</td>`;
      html += '</tr>';
    });

    html += '</tbody></table>';
    listDiv.innerHTML = html;
  } catch (e) {
    listDiv.innerHTML = `<p style="color: #e74c3c;">Erreur: ${e.message}</p>`;
  }
}

// Show reservation details when selected
document.addEventListener('change', (e) => {
  if (e.target.name === 'reservationId' && document.getElementById('conversionFields').style.display !== 'none') {
    const details = document.getElementById('reservationDetails');
    if (e.target.value) {
      details.style.display = 'block';
      document.getElementById('reservationDetailText').textContent = `Réservation #${e.target.value} sélectionnée`;
    } else {
      details.style.display = 'none';
    }
  }
});

document.getElementById('loadDataBtn').addEventListener('click', async () => {
  const dataDiv = document.getElementById('dataContainer');
  const loadDataBtn = document.getElementById('loadDataBtn');
  const runId = ++dataLoadRunId;

  loadDataBtn.disabled = true;
  dataDiv.innerHTML = '<div style="text-align: center; padding: 2rem;"><p style="color: #667eea; font-size: 1.1rem; font-weight: 600;">⏳ Chargement des données...</p></div>';

  const endpoints = [
    { name: '👥 Clients', url: '/api/clients', headers: ['ID', 'Nom complet'], icon: '👤' },
    { name: '👨‍💼 Employés', url: '/api/employees', headers: ['ID', 'Nom complet'], icon: '👨‍💼' },
    { name: '🏨 Hôtels', url: '/api/hotels', headers: ['ID', 'Nom'], icon: '🏨' },
    { name: '🛏️ Chambres', url: '/api/allrooms', headers: ['ID', 'Numéro'], icon: '🛏️' },
    { name: '📅 Réservations', url: '/api/reservations', headers: ['Détails'], icon: '📅' },
    { name: '🔑 Locations', url: '/api/locations', headers: ['Détails'], icon: '🔑' }
  ];

  dataDiv.innerHTML = '';

  try {
    for (const ep of endpoints) {
      if (runId !== dataLoadRunId) {
        return;
      }

      try {
        const response = await fetch(ep.url);
        if (runId !== dataLoadRunId) {
          return;
        }
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const items = await response.json();

        if (runId !== dataLoadRunId) {
          return;
        }

        const section = document.createElement('div');
        section.className = 'data-section';
        section.innerHTML = `<h3>${ep.name}</h3>`;

        const table = document.createElement('table');
        table.className = 'data-table';

        const thead = document.createElement('thead');
        const headerRow = document.createElement('tr');
        ep.headers.forEach(h => {
          const th = document.createElement('th');
          th.textContent = h;
          headerRow.appendChild(th);
        });
        thead.appendChild(headerRow);
        table.appendChild(thead);

        const tbody = document.createElement('tbody');
        if (items.length === 0) {
          const tr = document.createElement('tr');
          const td = document.createElement('td');
          td.colSpan = ep.headers.length;
          td.style.textAlign = 'center';
          td.style.color = '#999';
          td.textContent = 'Aucune donnée disponible';
          tr.appendChild(td);
          tbody.appendChild(tr);
        } else {
          items.forEach((item, idx) => {
            const row = document.createElement('tr');
            if (ep.name.includes('Réservations')) {
              const td = document.createElement('td');
              td.textContent = item;
              row.appendChild(td);
            } else {
              const [id, name] = item.split(': ', 2);
              const td1 = document.createElement('td');
              td1.textContent = id;
              td1.style.fontWeight = '600';
              td1.style.color = '#667eea';
              const td2 = document.createElement('td');
              td2.textContent = name || item;
              row.appendChild(td1);
              row.appendChild(td2);
            }
            tbody.appendChild(row);
          });
        }

        table.appendChild(tbody);
        section.appendChild(table);
        dataDiv.appendChild(section);
      } catch (e) {
        if (runId !== dataLoadRunId) {
          return;
        }
        console.error(e);
        const errorDiv = document.createElement('div');
        errorDiv.className = 'data-section';
        errorDiv.innerHTML = `<h3>${ep.name}</h3><p style="color: #e74c3c; font-weight: 500;">❌ Erreur lors du chargement</p>`;
        dataDiv.appendChild(errorDiv);
      }
    }
  } finally {
    if (runId === dataLoadRunId) {
      loadDataBtn.disabled = false;
    }
  }
});

searchForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const params = new URLSearchParams(new FormData(searchForm));
  const resultsDiv = document.getElementById('results');
  resultsDiv.innerHTML = '<p style="text-align: center; color: #667eea; font-weight: 600;">⏳ Recherche en cours...</p>';

  try {
    const response = await fetch('/api/rooms?' + params.toString());
    const rooms = await response.json();

    resultsDiv.innerHTML = '';

    if (!rooms.length) {
      resultsDiv.innerHTML = '<p style="text-align: center; color: #999; padding: 2rem;">😞 Aucune chambre ne correspond à vos critères.</p>';
      return;
    }

    const title = document.createElement('h3');
    title.textContent = `✅ ${rooms.length} chambre(s) trouvée(s)`;
    resultsDiv.appendChild(title);

    rooms.forEach((room, idx) => {
      const div = document.createElement('div');
      div.className = 'room';
      const stars = '⭐'.repeat(3); // Default placeholder
      div.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.75rem;">
          <div>
            <strong style="font-size: 1.1rem;">🏢 ${room.hotel}</strong><br>
            <small style="color: #4f46e5; font-weight: 700;">🏷️ ${room.chaine}</small><br>
            <small style="color: #666;">📍 ${room.zone}</small>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 1.5rem; color: #667eea; font-weight: 700;">$${room.prix}</div>
            <small style="color: #666;">/nuit</small>
          </div>
        </div>
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; margin-top: 1rem;">
          <div>
            <span style="color: #667eea; font-weight: 600;">🛏️ Numéro:</span> ${room.numero}
          </div>
          <div>
            <span style="color: #667eea; font-weight: 600;">👥 Capacité:</span> ${room.capacite} pers.
          </div>
          <div>
            <span style="color: #667eea; font-weight: 600;">📐 Superficie:</span> ${room.superficie} m²
          </div>
          <div>
            <span style="color: #667eea; font-weight: 600;">🆔 ID:</span> ${room.chambreId}
          </div>
        </div>
      `;
      resultsDiv.appendChild(div);
    });
  } catch (e) {
    console.error(e);
    resultsDiv.innerHTML = '<p style="text-align: center; color: #e74c3c; font-weight: 500;">❌ Erreur lors de la recherche</p>';
  }
});

reservationForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const body = new URLSearchParams(new FormData(reservationForm));
  try {
    const response = await fetch('/api/reservations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body
    });

    const message = await response.text();
    if (response.ok) {
      showMessage('✅ ' + message);
      reservationForm.reset();
    } else {
      showMessage('❌ ' + message);
    }
    loadData();
  } catch (e) {
    showMessage('❌ Erreur: ' + e.message);
  }
});

locationForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const type = locationForm.querySelector('[name=type]:checked').value;
  const body = new URLSearchParams(new FormData(locationForm));
  let url = '/api/locations';
  if (type === 'conversion') {
    url = '/api/convert';
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body
    });

    const message = await response.text();
    if (response.ok) {
      showMessage('✅ ' + message);
      locationForm.reset();
    } else {
      showMessage('❌ ' + message);
    }
    loadData();
  } catch (e) {
    showMessage('❌ Erreur: ' + e.message);
  }
});

convertForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const body = new URLSearchParams(new FormData(convertForm));
  try {
    const response = await fetch('/api/convert', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body
    });

    const message = await response.text();
    if (response.ok) {
      showMessage('✅ ' + message);
      convertForm.reset();
    } else {
      showMessage('❌ ' + message);
    }
    loadData();
  } catch (e) {
    showMessage('❌ Erreur: ' + e.message);
  }
});

document.getElementById('archiveReservationBtn').addEventListener('click', async () => {
  const id = document.getElementById('archiveReservationSelect').value;
  if (!id) {
    showMessage('⚠️ Veuillez choisir une réservation');
    return;
  }
  try {
    const response = await fetch(`/api/archive/reservation/${id}`, { method: 'POST' });
    const message = await response.text();
    if (response.ok) {
      showMessage('✅ ' + message);
    } else {
      showMessage('❌ ' + message);
    }
    loadData();
  } catch (e) {
    showMessage('❌ Erreur: ' + e.message);
  }
});

document.getElementById('archiveLocationBtn').addEventListener('click', async () => {
  const id = document.getElementById('archiveLocationSelect').value;
  if (!id) {
    showMessage('⚠️ Veuillez choisir une location');
    return;
  }
  try {
    const response = await fetch(`/api/archive/location/${id}`, { method: 'POST' });
    const message = await response.text();
    if (response.ok) {
      showMessage('✅ ' + message);
    } else {
      showMessage('❌ ' + message);
    }
    loadData();
  } catch (e) {
    showMessage('❌ Erreur: ' + e.message);
  }
});

async function loadCurrentReservations() {
  const container = document.getElementById('currentReservationsContainer');
  try {
    const response = await fetch('/api/reservations');
    const reservations = await response.json();

    if (!reservations.length) {
      container.innerHTML = '<p style="text-align: center; color: #999; padding: 2rem;">😊 Aucune réservation active pour le moment.</p>';
      return;
    }

    let html = '<table style="width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">';
    html += '<thead>';
    html += '<tr style="background: #f3f4f6; border-bottom: 2px solid #e5e7eb;">';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">🆔 ID</th>';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">👤 Client</th>';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">🛏️ Chambre</th>';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">📅 Arrivée</th>';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">📅 Départ</th>';
    html += '<th style="padding: 1rem; text-align: left; font-weight: 600; color: #374151;">⏱️ Durée</th>';
    html += '</tr>';
    html += '</thead>';
    html += '<tbody>';

    reservations.forEach((res, idx) => {
      // Parse the reservation string: "1: Client 1, Chambre 3, 2030-06-10 to 2030-06-12"
      const match = res.match(/(\d+): Client (\d+), Chambre (\d+), (.+) to (.+)/);
      if (match) {
        const [, resId, clientId, chambreId, dateDebut, dateFin] = match;

        // Calculate duration
        const start = new Date(dateDebut);
        const end = new Date(dateFin);
        const duration = Math.ceil((end - start) / (1000 * 60 * 60 * 24));

        const rowBg = idx % 2 === 0 ? 'white' : '#f9fafb';
        html += `<tr style="background: ${rowBg}; border-bottom: 1px solid #e5e7eb;">`;
        html += `<td style="padding: 1rem; color: #667eea; font-weight: 600;">${resId}</td>`;
        html += `<td style="padding: 1rem; color: #374151;">${clientId}</td>`;
        html += `<td style="padding: 1rem; color: #374151;">${chambreId}</td>`;
        html += `<td style="padding: 1rem; color: #374151;">${dateDebut}</td>`;
        html += `<td style="padding: 1rem; color: #374151;">${dateFin}</td>`;
        html += `<td style="padding: 1rem; color: #667eea; font-weight: 500;">${duration} nuit${duration > 1 ? 's' : ''}</td>`;
        html += '</tr>';
      }
    });

    html += '</tbody>';
    html += '</table>';

    // Add summary
    const summary = document.createElement('div');
    summary.style.marginTop = '1.5rem';
    summary.style.padding = '1rem';
    summary.style.background = '#eff6ff';
    summary.style.border = '1px solid #bfdbfe';
    summary.style.borderRadius = '8px';
    summary.style.color = '#1e40af';
    summary.style.fontSize = '0.9rem';
    summary.innerHTML = `📊 Total: <strong>${reservations.length}</strong> réservation${reservations.length > 1 ? 's' : ''} active${reservations.length > 1 ? 's' : ''}`;

    container.innerHTML = html;
    container.appendChild(summary);
  } catch (e) {
    console.error(e);
    container.innerHTML = `<p style="color: #e74c3c; font-weight: 500;">❌ Erreur lors du chargement: ${e.message}</p>`;
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadData();
  loadCurrentReservations();

  // Tab switching
  document.querySelectorAll('.tab-button').forEach(button => {
    button.addEventListener('click', () => {
      document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
      button.classList.add('active');
      document.getElementById(button.dataset.tab).classList.add('active');

      // Load reservations when switching to that tab
      if (button.dataset.tab === 'reservations') {
        loadCurrentReservations();
      }
    });
  });
});