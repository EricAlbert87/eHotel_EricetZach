const searchForm = document.getElementById('searchForm');
const reservationForm = document.getElementById('reservationForm');
const locationForm = document.getElementById('locationForm');
const convertForm = document.getElementById('convertForm');
const results = document.getElementById('results');

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
    const data = await response.json();
    const firstOption = selectElement.querySelector('option');
    selectElement.innerHTML = firstOption ? firstOption.outerHTML : '<option value="">Sélectionner</option>';
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
}

document.addEventListener('DOMContentLoaded', loadData);

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

document.addEventListener('DOMContentLoaded', loadData);

document.getElementById('loadDataBtn').addEventListener('click', async () => {
  const dataDiv = document.getElementById('dataContainer');
  dataDiv.innerHTML = '<div style="text-align: center; padding: 2rem;"><p style="color: #667eea; font-size: 1.1rem; font-weight: 600;">⏳ Chargement des données...</p></div>';

  const endpoints = [
    { name: '👥 Clients', url: '/api/clients', headers: ['ID', 'Nom complet'], icon: '👤' },
    { name: '👨‍💼 Employés', url: '/api/employees', headers: ['ID', 'Nom complet'], icon: '👨‍💼' },
    { name: '🏨 Hôtels', url: '/api/hotels', headers: ['ID', 'Nom'], icon: '🏨' },
    { name: '🛏️ Chambres', url: '/api/allrooms', headers: ['ID', 'Numéro'], icon: '🛏️' },
    { name: '📅 Réservations', url: '/api/reservations', headers: ['Détails'], icon: '📅' }
  ];

  dataDiv.innerHTML = '';

  for (const ep of endpoints) {
    try {
      const response = await fetch(ep.url);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const items = await response.json();
      
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
      console.error(e);
      const errorDiv = document.createElement('div');
      errorDiv.className = 'data-section';
      errorDiv.innerHTML = `<h3>${ep.name}</h3><p style="color: #e74c3c; font-weight: 500;">❌ Erreur lors du chargement</p>`;
      dataDiv.appendChild(errorDiv);
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

document.addEventListener('DOMContentLoaded', () => {
  loadData();

  // Tab switching
  document.querySelectorAll('.tab-button').forEach(button => {
    button.addEventListener('click', () => {
      document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
      button.classList.add('active');
      document.getElementById(button.dataset.tab).classList.add('active');
    });
  });
});