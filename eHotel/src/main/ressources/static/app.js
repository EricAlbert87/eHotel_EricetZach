const searchForm = document.getElementById('searchForm');
const reservationForm = document.getElementById('reservationForm');
const locationForm = document.getElementById('locationForm');
const results = document.getElementById('results');
const message = document.getElementById('message');

function showMessage(text) {
  message.style.display = 'block';
  message.textContent = text;
}

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

  const body = new URLSearchParams(new FormData(locationForm));
  const response = await fetch('/api/locations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });

  showMessage(await response.text());
});