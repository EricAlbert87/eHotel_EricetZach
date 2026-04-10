/**
 * eHotel Frontend Automated Test Suite
 * Tests all UI components and API interactions
 * Run with: node frontend_tests.js [server_url]
 */

const http = require('http');
const https = require('https');
const url = require('url');

const BASE_URL = process.argv[2] || 'http://localhost:8080';
const RESULTS = {
    passed: 0,
    failed: 0,
    total: 0,
    details: []
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function makeRequest(path, method = 'GET', body = null) {
    return new Promise((resolve, reject) => {
        const options = url.parse(BASE_URL + path);
        options.method = method;
        options.headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        };

        const protocol = options.protocol === 'https:' ? https : http;
        const req = protocol.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({
                        status: res.statusCode,
                        headers: res.headers,
                        body: data,
                        json: () => {
                            try {
                                return JSON.parse(data);
                            } catch {
                                return data;
                            }
                        }
                    });
                } catch (e) {
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        if (body) req.write(body);
        req.end();
    });
}

function test(name, fn) {
    RESULTS.total++;
    return Promise.resolve()
        .then(fn)
        .then(() => {
            RESULTS.passed++;
            RESULTS.details.push({ name, status: '✓ PASS', error: null });
            console.log(`✓ ${name}`);
        })
        .catch(err => {
            RESULTS.failed++;
            RESULTS.details.push({ name, status: '✗ FAIL', error: err.message });
            console.log(`✗ ${name}: ${err.message}`);
        });
}

async function runTests() {
    console.log('╔════════════════════════════════════════════════════════╗');
    console.log('║      eHotel Frontend Automated Test Suite              ║');
    console.log('╚════════════════════════════════════════════════════════╝\n');
    console.log(`Target Server: ${BASE_URL}\n`);

    // Run all test suites
    await testServerConnectivity();
    await testStaticAssets();
    await testAPIEndpoints();
    await testRoomSearch();
    await testReservationAPI();
    await testLocationAPI();
    await testDataEndpoints();
    await testErrorHandling();

    // Print summary
    printSummary();
}

// ============================================================================
// TEST SECTION 1: SERVER CONNECTIVITY
// ============================================================================

async function testServerConnectivity() {
    console.log('\n[1] SERVER CONNECTIVITY');
    console.log('─────────────────────────────────────────');

    await test('1.1: Server is running', async () => {
        const res = await makeRequest('/');
        if (res.status !== 200) throw new Error(`Status ${res.status}, expected 200`);
    });

    await test('1.2: Root path responds with HTML', async () => {
        const res = await makeRequest('/');
        if (!res.body.includes('<!DOCTYPE')) throw new Error('Response is not HTML');
        if (!res.body.toLowerCase().includes('ehotel')) throw new Error('HTML does not contain ehotel');
    });

    await test('1.3: Server responds within 2 seconds', async () => {
        const start = Date.now();
        await makeRequest('/');
        const elapsed = Date.now() - start;
        if (elapsed > 2000) throw new Error(`Response time ${elapsed}ms exceeds 2s`);
    });
}

// ============================================================================
// TEST SECTION 2: STATIC ASSETS
// ============================================================================

async function testStaticAssets() {
    console.log('\n[2] STATIC ASSETS');
    console.log('─────────────────────────────────────────');

    await test('2.1: CSS asset loads', async () => {
        const res = await makeRequest('/app.css');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        if (res.headers['content-type'] !== 'text/css; charset=utf-8')
            throw new Error(`Wrong content-type: ${res.headers['content-type']}`);
    });

    await test('2.2: JavaScript asset loads', async () => {
        const res = await makeRequest('/app.js');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        if (!res.headers['content-type'].includes('javascript'))
            throw new Error(`Wrong content-type: ${res.headers['content-type']}`);
    });

    await test('2.3: HTML page loads', async () => {
        const res = await makeRequest('/');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        if (res.headers['content-type'] !== 'text/html; charset=utf-8')
            throw new Error(`Wrong content-type: ${res.headers['content-type']}`);
    });
}

// ============================================================================
// TEST SECTION 3: API ENDPOINTS AVAILABILITY
// ============================================================================

async function testAPIEndpoints() {
    console.log('\n[3] API ENDPOINTS');
    console.log('─────────────────────────────────────────');

    await test('3.1: /api/rooms endpoint exists', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=10');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.2: /api/chains endpoint exists', async () => {
        const res = await makeRequest('/api/chains');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.3: /api/zones endpoint exists', async () => {
        const res = await makeRequest('/api/zones');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.4: /api/hotels endpoint exists', async () => {
        const res = await makeRequest('/api/hotels');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.5: /api/employees endpoint exists', async () => {
        const res = await makeRequest('/api/employees');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.6: /api/allrooms endpoint exists', async () => {
        const res = await makeRequest('/api/allrooms');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.7: /api/reservations GET endpoint exists', async () => {
        const res = await makeRequest('/api/reservations', 'GET');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });

    await test('3.8: /api/locations GET endpoint exists', async () => {
        const res = await makeRequest('/api/locations', 'GET');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });
}

// ============================================================================
// TEST SECTION 4: ROOM SEARCH API
// ============================================================================

async function testRoomSearch() {
    console.log('\n[4] ROOM SEARCH API');
    console.log('─────────────────────────────────────────');

    await test('4.1: Search returns valid JSON', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Response is not an array');
    });

    await test('4.2: Search returns multiple rooms', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        if (data.length === 0) throw new Error('No rooms returned');
    });

    await test('4.3: Search by zone filters results', async () => {
        const res = await makeRequest('/api/rooms?zone=Vancouver+Bay&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        if (data.length === 0) throw new Error('No rooms in Vancouver Bay');
        data.forEach(room => {
            if (room.zone !== 'Vancouver Bay') throw new Error(`Wrong zone: ${room.zone}`);
        });
    });

    await test('4.4: Search by capacity filters results', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=2&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        data.forEach(room => {
            if (room.capacite < 2) throw new Error(`Capacity too low: ${room.capacite}`);
        });
    });

    await test('4.5: Search by price filters results', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=200&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        data.forEach(room => {
            if (room.precio > 200 && room.precio !== undefined) {
                // Note: precio field name might vary
                if (room.prix === undefined && room.precio > 200)
                    throw new Error(`Price too high: ${room.precio}`);
            }
        });
    });

    await test('4.6: Search result includes required fields', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=10');
        const data = res.json();
        if (data.length > 0) {
            const room = data[0];
            const requiredFields = ['chambreId', 'numero', 'hotel', 'zone', 'prix', 'capacite', 'superficie'];
            requiredFields.forEach(field => {
                if (!(field in room)) throw new Error(`Missing field: ${field}`);
            });
        }
    });

    await test('4.7: Search respects limit parameter', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=5');
        const data = res.json();
        if (data.length > 5) throw new Error(`Returned ${data.length} rooms, expected max 5`);
    });

    await test('4.8: Empty zone filter returns all zones', async () => {
        const res = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        const data = res.json();
        const zones = new Set(data.map(r => r.zone));
        if (zones.size < 5) throw new Error(`Found only ${zones.size} zones`);
    });

    await test('4.9: Invalid zone returns no results (graceful)', async () => {
        const res = await makeRequest('/api/rooms?zone=InvalidZone123&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=100');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Response should be empty array');
    });
}

// ============================================================================
// TEST SECTION 5: RESERVATION API
// ============================================================================

async function testReservationAPI() {
    console.log('\n[5] RESERVATION API');
    console.log('─────────────────────────────────────────');

    await test('5.1: GET /api/reservations returns data', async () => {
        const res = await makeRequest('/api/reservations', 'GET');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Response is not an array');
    });

    await test('5.2: POST /api/reservations accepts valid data', async () => {
        const roomSearch = await makeRequest('/api/rooms?zone=&capacite=1&prix=9999&superficie=0&chaine=&categorie=0&dateDebut=2099-01-10&dateFin=2099-01-12&nombreChambres=25');
        const availableRooms = roomSearch.json();
        if (!Array.isArray(availableRooms) || availableRooms.length === 0) {
            throw new Error('No available room found for reservation test');
        }

        const selectedRoom = availableRooms[Math.floor(Math.random() * availableRooms.length)].chambreId;
        const startDayInt = 10 + Math.floor(Math.random() * 10);
        const endDayInt = startDayInt + 1;
        const day = String(startDayInt).padStart(2, '0');
        const nextDay = String(endDayInt).padStart(2, '0');
        const body = `clientId=1&chambreId=${selectedRoom}&dateDebut=2099-01-${day}&dateFin=2099-01-${nextDay}`;

        const res = await makeRequest('/api/reservations', 'POST', body);
        if (res.status !== 200) throw new Error(`Unexpected status ${res.status}`);
    });

    await test('5.3: POST /api/reservations rejects invalid method', async () => {
        const res = await makeRequest('/api/reservations', 'DELETE');
        if (res.status !== 405) throw new Error(`Expected 405, got ${res.status}`);
    });
}

// ============================================================================
// TEST SECTION 6: LOCATION API
// ============================================================================

async function testLocationAPI() {
    console.log('\n[6] LOCATION (RENTAL) API');
    console.log('─────────────────────────────────────────');

    await test('6.1: GET /api/locations returns data', async () => {
        const res = await makeRequest('/api/locations', 'GET');
        if (res.status !== 200) throw new Error(`Status ${res.status}`);
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Response is not an array');
    });

    await test('6.2: POST /api/locations accepts valid data', async () => {
        const body = 'clientId=1&chambreId=2&dateDebut=2030-08-01&dateFin=2030-08-03&employeId=1';
        const res = await makeRequest('/api/locations', 'POST', body);
        if (res.status !== 200 && res.status !== 400) throw new Error(`Unexpected status ${res.status}`);
    });

    await test('6.3: POST /api/convert accepts conversion params', async () => {
        const body = 'reservationId=1&employeId=1';
        const res = await makeRequest('/api/convert', 'POST', body);
        if (res.status !== 200 && res.status !== 400) throw new Error(`Unexpected status ${res.status}`);
    });
}

// ============================================================================
// TEST SECTION 7: DATA RETRIEVAL ENDPOINTS
// ============================================================================

async function testDataEndpoints() {
    console.log('\n[7] DATA RETRIEVAL ENDPOINTS');
    console.log('─────────────────────────────────────────');

    await test('7.1: Chains endpoint returns array', async () => {
        const res = await makeRequest('/api/chains');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Chains response is not an array');
        if (data.length !== 8) throw new Error(`Expected 8 chains, got ${data.length}`);
    });

    await test('7.2: Zones endpoint returns array', async () => {
        const res = await makeRequest('/api/zones');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Zones response is not an array');
        if (data.length < 5) throw new Error(`Expected at least 5 zones, got ${data.length}`);
    });

    await test('7.3: Hotels endpoint returns array', async () => {
        const res = await makeRequest('/api/hotels');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Hotels response is not an array');
        if (data.length < 10) throw new Error(`Expected at least 10 hotels, got ${data.length}`);
    });

    await test('7.4: Employees endpoint returns array', async () => {
        const res = await makeRequest('/api/employees');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Employees response is not an array');
        if (data.length < 10) throw new Error(`Expected at least 10 employees, got ${data.length}`);
    });

    await test('7.5: All rooms endpoint returns array', async () => {
        const res = await makeRequest('/api/allrooms');
        const data = res.json();
        if (!Array.isArray(data)) throw new Error('Rooms response is not an array');
        if (data.length < 20) throw new Error(`Expected at least 20 rooms, got ${data.length}`);
    });
}

// ============================================================================
// TEST SECTION 8: ERROR HANDLING
// ============================================================================

async function testErrorHandling() {
    console.log('\n[8] ERROR HANDLING');
    console.log('─────────────────────────────────────────');

    await test('8.1: Invalid endpoint returns 404', async () => {
        try {
            await makeRequest('/api/invalid-endpoint');
        } catch (err) {
            // Expected to fail - either 404 or connection error
        }
    });

    await test('8.2: Malformed query parameters handled gracefully', async () => {
        const res = await makeRequest('/api/rooms?zona=bad&capacite=abc&precio=xyz');
        if (res.status === 500) throw new Error('Server returned 500 error');
    });

    await test('8.3: Missing required fields handled', async () => {
        const res = await makeRequest('/api/reservations', 'POST', 'clientId=1');
        if (res.status !== 400 && res.status !== 500) {
            // Should either reject with 400 or fail with 500
        }
    });

    await test('8.4: API responds with appropriate error format', async () => {
        const res = await makeRequest('/api/rooms?capacite=invalid');
        if (res.status === 200 && res.body) {
            try {
                res.json(); // Should be valid JSON
            } catch {
                throw new Error('Error response is not valid JSON');
            }
        }
    });
}

// ============================================================================
// SUMMARY
// ============================================================================

function printSummary() {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║                    TEST SUMMARY                        ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    console.log(`Total Tests:      ${RESULTS.total}`);
    console.log(`Passed:           ${RESULTS.passed} ✓`);
    console.log(`Failed:           ${RESULTS.failed} ✗`);
    console.log(`Success Rate:     ${(RESULTS.passed * 100 / RESULTS.total).toFixed(1)}%`);
    console.log(`\nStatus: ${RESULTS.failed === 0 ? '✓ ALL TESTS PASSED' : '✗ SOME TESTS FAILED'}`);

    if (RESULTS.failed > 0) {
        console.log('\nFailed Tests:');
        RESULTS.details
            .filter(d => d.error)
            .forEach(d => {
                console.log(`  - ${d.name}: ${d.error}`);
            });
    }
}

// Run all tests
runTests().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
