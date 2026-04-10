const searchForm = document.getElementById('searchForm');
const reservationForm = document.getElementById('reservationForm');
const locationForm = document.getElementById('locationForm');
const convertForm = document.getElementById('convertForm');
const results = document.getElementById('results');
const message = document.getElementById('message');

function showMessage(text) {
  message.style.display = 'block';
  message.textContent = text;
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
  const dataDiv = document.getElementById('data');
  dataDiv.innerHTML = '';

  const endpoints = [
    { name: 'Clients', url: '/api/clients' },
    { name: 'Employés', url: '/api/employees' },
    { name: 'Hôtels', url: '/api/hotels' },
    { name: 'Chambres', url: '/api/allrooms' },
    { name: 'Réservations', url: '/api/reservations' }
  ];

  for (const ep of endpoints) {
    try {
      const response = await fetch(ep.url);
      const items = await response.json();
      const div = document.createElement('div');
      div.innerHTML = `<h3>${ep.name}</h3><ul>${items.map(item => `<li>${item}</li>`).join('')}</ul>`;
      dataDiv.appendChild(div);
    } catch (e) {
      console.error(e);
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