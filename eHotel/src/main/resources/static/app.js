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
  dataDiv.innerHTML = '<p>Chargement...</p>';

  const endpoints = [
    { name: 'Clients', url: '/api/clients', headers: ['ID', 'Nom complet'] },
    { name: 'Employés', url: '/api/employees', headers: ['ID', 'Nom complet'] },
    { name: 'Hôtels', url: '/api/hotels', headers: ['ID', 'Nom'] },
    { name: 'Chambres', url: '/api/allrooms', headers: ['ID', 'Numéro'] },
    { name: 'Réservations', url: '/api/reservations', headers: ['Détails'] }
  ];

  dataDiv.innerHTML = '';

  for (const ep of endpoints) {
    try {
      const response = await fetch(ep.url);
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
      items.forEach(item => {
        const row = document.createElement('tr');
        if (ep.name === 'Réservations') {
          const td = document.createElement('td');
          td.textContent = item;
          row.appendChild(td);
        } else {
          const [id, name] = item.split(': ', 2);
          const td1 = document.createElement('td');
          td1.textContent = id;
          const td2 = document.createElement('td');
          td2.textContent = name || item;
          row.appendChild(td1);
          row.appendChild(td2);
        }
        tbody.appendChild(row);
      });
      table.appendChild(tbody);
      section.appendChild(table);
      dataDiv.appendChild(section);
    } catch (e) {
      console.error(e);
      dataDiv.innerHTML += `<p>Erreur lors du chargement de ${ep.name}</p>`;
    }
  }
});

searchForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const params = new URLSearchParams(new FormData(searchForm));
  const response = await fetch('/api/rooms?' + params.toString());
  const rooms = await response.json();

  results.innerHTML = '';

  if (!rooms.length) {
    results.innerHTML = '<p>Aucune chambre trouvée.</p>';
    return;
  }

  rooms.forEach(room => {
    const div = document.createElement('div');
    div.className = 'room';
    div.innerHTML = `
      <strong>${room.hotel}</strong><br>
      Zone: ${room.zone}<br>
      Chambre ID: ${room.chambreId}<br>
      Numéro: ${room.numero}<br>
      Prix: ${room.prix}$<br>
      Capacité: ${room.capacite}<br>
      Superficie: ${room.superficie} m²
    `;
    results.appendChild(div);
  });
});

reservationForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const body = new URLSearchParams(new FormData(reservationForm));
  const response = await fetch('/api/reservations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });

  showMessage(await response.text());
});

locationForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const type = locationForm.querySelector('[name=type]:checked').value;
  const body = new URLSearchParams(new FormData(locationForm));
  let url = '/api/locations';
  if (type === 'conversion') {
    url = '/api/convert';
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });

  showMessage(await response.text());
});

convertForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const body = new URLSearchParams(new FormData(convertForm));
  const response = await fetch('/api/convert', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });

  showMessage(await response.text());
  // Reload data
  loadData();
});

document.getElementById('archiveReservationBtn').addEventListener('click', async () => {
  const id = document.getElementById('archiveReservationSelect').value;
  if (!id) return;
  const response = await fetch(`/api/archive/reservation/${id}`, { method: 'POST' });
  showMessage(await response.text());
  loadData();
});

document.getElementById('archiveLocationBtn').addEventListener('click', async () => {
  const id = document.getElementById('archiveLocationSelect').value;
  if (!id) return;
  const response = await fetch(`/api/archive/location/${id}`, { method: 'POST' });
  showMessage(await response.text());
  loadData();
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