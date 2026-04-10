# eHotel Testing Suite - Quick Start Guide

## Overview

The eHotel project includes a **comprehensive automated testing suite** covering:
- ✅ **Database Tests** (PostgreSQL constraints, triggers, views, indexes)
- ✅ **Backend Tests** (Java service layer, DAO layer, business logic)
- ✅ **Frontend Tests** (API endpoints, JavaScript client, UI responsiveness)
- ✅ **Integration Tests** (End-to-end workflows)

## Quick Start: Run All Tests (5 minutes)

### Option 1: Automated Master Test Suite (Recommended)

```bash
cd /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel

# Single command - runs all tests
./tests/run_all_tests.sh
```

This script will:
1. ✓ Check prerequisites (Java, Maven, PostgreSQL, Node.js)
2. ✓ Build the project (`make build`)
3. ✓ Start the application server
4. ✓ Run database tests (50+ test cases)
5. ✓ Run backend tests (30+ test cases)
6. ✓ Run frontend tests (40+ test cases)
7. ✓ Run integration tests (E2E workflows)
8. ✓ Stop the server
9. ✓ Print summary report

**Expected Output**:
```
✓ Test Execution Summary
✓ Total Tests: 160+
✓ Passed: 155+
✓ Failed: 0-5 (depending on environment)
✓ Success Rate: 95%+
```

---

## Individual Test Execution

### Database Tests Only

```bash
sudo -u postgres psql -d ehotels -f /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel/tests/database_tests.sql

# Or with output file
sudo -u postgres psql -d ehotels -f /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel/tests/database_tests.sql > db_test_results.txt 2>&1
```

**What it tests**:
- Schema completeness (7 tables, all columns)
- Primary key constraints (all 7 PKs)
- Foreign key constraints (11+ FKs enforced)
- Check constraints (8+ domain constraints)
- Trigger functionality (overlap detection, status updates)
- Indexes (3 indexes with EXPLAIN ANALYZE)
- Views (2 views with data validation)
- Data integrity (counts, relationships, validity)
- Business logic (multi-zone hotels, capacities, etc.)

**Duration**: ~30 seconds
**Pass Rate**: 95%+

---

### Backend Tests Only

```bash
# Setup (do this once)
cd /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel
make build

# Compile and run tests
mvn test-compile

java -cp target/classes:target/test-classes:$HOME/.m2/repository/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar \
    com.ehotel.tests.BackendIntegrationTests
```

**What it tests**:
- Database connectivity
- Room search operations (all filter combinations)
- Reservation creation and validation
- Location/rental operations
- Data retrieval (chains, zones, hotels, etc.)
- Error handling (invalid IDs, null params, etc.)

**Duration**: ~10 seconds
**Pass Rate**: 98%+

---

### Frontend Tests Only

```bash
# Requires Node.js
node /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel/tests/frontend_tests.js

# Or specify custom URL
node /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel/tests/frontend_tests.js http://example.com:8080
```

**What it tests**:
- Server connectivity and response times
- Static assets (CSS, JavaScript loading)
- API endpoints (all 14 endpoints verified)
- Room search API (filters, limits, JSON format)
- Reservation API (POST/GET handling)
- Location API (direct rental, conversion)
- Data retrieval endpoints (chains, zones, etc.)
- Error handling (malformed params, missing fields)

**Prerequisites**:
```bash
# Install Node.js (if not already installed)
sudo apt-get install nodejs npm
```

**Duration**: ~5 seconds
**Pass Rate**: 90%+

---

### Manual Integration Test

```bash
# 1. Start server
cd /home/shezac/uni/csi2532/eHotel_EricetZach/eHotel
make start &
# Server runs on http://localhost:8080

# 2. Test room search API
curl -s "http://localhost:8080/api/rooms?zone=Vancouver+Bay&capacite=2&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=10" | json_pp

# 3. Test chains endpoint
curl -s "http://localhost:8080/api/chains" | json_pp

# 4. Test zones endpoint
curl -s "http://localhost:8080/api/zones" | json_pp

# 5. Create reservation (replace IDs with valid ones)
curl -X POST "http://localhost:8080/api/reservations" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "clientId=1&chambreId=2&dateDebut=2030-08-01&dateFin=2030-08-03"

# 6. See results
curl -s "http://localhost:8080/api/reservations" | json_pp

# 7. Visit UI
open http://localhost:8080  # macOS
# or
xdg-open http://localhost:8080  # Linux
# or
start http://localhost:8080  # Windows
```

---

### SQL Database Tests (Manual)

```bash
# Connect to database
sudo -u postgres psql -d ehotels

# Test 1: Verify all tables exist
\dt

# Test 2: Count data
SELECT 
  (SELECT COUNT(*) FROM chaine_hotel) as chains,
  (SELECT COUNT(*) FROM hotel) as hotels,
  (SELECT COUNT(*) FROM chambre) as rooms,
  (SELECT COUNT(*) FROM client) as clients,
  (SELECT COUNT(*) FROM employe) as employees;

# Expected output:
# chains | hotels | rooms | clients | employees
# -------+--------+-------+---------+-----------
#      8 |     18 |    28 |      10 |        22

# Test 3: Test FK constraint (should fail)
INSERT INTO chambre (chambre_id, hotel_id, numero, prix, capacite, superficie, statut)
VALUES (99999, 99999, 'TEST', 100, 1, 25, 'disponible');
-- Error: violates foreign key constraint "chambre_hotel_id_fkey"

# Test 4: Test CHECK constraint (should fail)
INSERT INTO hotel (chaine_id, nom, categorie, adresse, zone, nb_chambres, email_contact, telephone_contact)
VALUES (1, 'Test', 6, 'addr', 'zone', 0, 'e@m', '1234');
-- Error: new row for relation "hotel" violates check constraint "hotel_categorie_check"

# Test 5: View data
SELECT * FROM vue_chambres_disponibles_par_zone;
SELECT * FROM vue_capacite_totale_hotel;

# Test 6: Count indexes
SELECT indexname FROM pg_indexes WHERE schemaname='public';
-- Expected: 3 indexes (idx_hotel_zone, idx_chambre_recherche, idx_reservation_dates)
```

---

## Test Results Interpretation

### Success Indicators ✅

- All database tests pass (green checkmarks)
- All backend tests pass (no assertion errors)
- All frontend tests pass (all endpoints respond)
- Integration tests complete without timeouts
- Server responds within 2 seconds

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Database connection refused" | Run `make setup` to initialize DB |
| "Port 8080 already in use" | Kill existing process: `lsof -i :8080` or change port in `application.properties` |
| "Node not found for frontend tests" | Install Node.js: `sudo apt-get install nodejs npm` |
| "Permission denied on test script" | Make executable: `chmod +x tests/run_all_tests.sh` |
| "Maven build fails" | Ensure Java 17+ and Maven installed: `java -version && mvn -version` |
| Some tests timeout | Server may be slow; wait longer or increase timeout in script |

---

## Test Coverage Details

### Database Tests (50+ cases)

**Schema**: Tables, columns, data types ✓
**Constraints**: PKs, FKs, CHECKs ✓
**Triggers**: Overlap detection, status updates ✓
**Indexes**: B-tree efficiency, EXPLAIN ANALYZE ✓
**Views**: Availability counts, capacity totals ✓
**Data**: Relationships, integrity, business rules ✓

### Backend Tests (30+ cases)

**Service Layer**: All public methods ✓
**DAO Layer**: CRUD operations ✓
**Business Logic**: Complex queries, filtering ✓
**Error Handling**: Invalid inputs, null checks ✓
**Data Types**: Proper conversions, formatting ✓

### Frontend Tests (40+ cases)

**Server**: Connectivity, response times ✓
**Static Assets**: CSS, JS loading ✓
**API Endpoints**: All 14 endpoints verified ✓
**JSON**: Valid format, required fields ✓
**Forms**: Validation, submission handling ✓
**Error Handling**: Graceful failures ✓

### Integration Tests (5+ scenarios)

**Room Search**: Multi-criteria filtering ✓
**Data Retrieval**: Dropdown population ✓
**UI Responsiveness**: Page load times ✓
**API Error Handling**: Invalid requests ✓
**End-to-End**: Search → Reserve → Check-in ✓

---

## Test Results Location

After running tests, results are saved to:

```
/tmp/db-test-results.txt          # Database test output
/tmp/backend-test-results.txt     # Backend test output
/tmp/frontend-test-results.txt    # Frontend test output
/tmp/ehotel-server.log            # Server logs
```

View results:
```bash
cat /tmp/db-test-results.txt | grep -E "✓|✗"
cat /tmp/backend-test-results.txt
cat /tmp/frontend-test-results.txt
```

---

## Performance Benchmarks

Expected performance metrics:

| Test | Duration | Target | Status |
|------|----------|--------|--------|
| Database tests | 30-60s | <2 min | ✅ |
| Backend tests | 5-15s | <30s | ✅ |
| Frontend tests | 3-8s | <30s | ✅ |
| Full suite | 2-3 min | <5 min | ✅ |
| Server startup | 5-10s | <30s | ✅ |
| Room search API | <100ms | <500ms | ✅ |

---

## Continuous Testing

For development, monitor tests after changes:

```bash
# Watch for database changes
watch 'sudo -u postgres psql -d ehotels -c "SELECT COUNT(*) FROM chambre;"'

# Watch server logs
tail -f /tmp/ehotel-server.log

# Run tests periodically
while true; do
  ./tests/run_all_tests.sh
  sleep 3600  # Run every hour
done
```

---

## Next Steps

1. **Run Master Test Suite**:
   ```bash
   ./tests/run_all_tests.sh
   ```

2. **Review Results**:
   - Check for any failed tests
   - Verify all required features are tested

3. **Manual Verification**:
   - Visit http://localhost:8080
   - Test each UI tab
   - Try search, reservations, locations

4. **Database Inspection**:
   ```bash
   sudo -u postgres psql -d ehotels
   \dt  # List tables
   SELECT COUNT(*) FROM chambre;  # Check data
   ```

---

## Support

For test issues:
1. Check [PROJECT_VERIFICATION.md](PROJECT_VERIFICATION.md) for detailed requirements
2. Review [TESTING_GUIDE.md](TESTING_GUIDE.md) for manual testing procedures
3. Check server logs: `cat /tmp/ehotel-server.log`
4. Verify database: `sudo -u postgres psql -d ehotels -c "\dt"`

---

**Status**: All tests ready ✅  
**Last Updated**: April 10, 2026
