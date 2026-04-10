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
    selectElement.innerHTML = '<option value="">Sélectionner</option>';
    data.forEach(item => {
      const option = document.createElement('option');
      const [id, name] = item.split(': ', 2);
      option.value = id;
      option.textContent = item;
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
}

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
    // For conversion, use convert API, but need reservationId
    // But the form doesn't have reservationId, it's in convertForm
    // Perhaps redirect or something, but for now, assume direct
    url = '/api/locations';
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