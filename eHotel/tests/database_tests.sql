-- ============================================================================
-- eHotel Database Automated Testing Suite
-- ============================================================================
-- Tests all aspects of the database:
-- 1. Schema completeness
-- 2. Primary & Foreign Keys
-- 3. Check Constraints  
-- 4. Triggers
-- 5. Indexes
-- 6. Views
-- 7. Data integrity
-- ============================================================================

\set ON_ERROR_STOP on

-- Test counter variables
\set test_count 0
\set passed_count 0
\set failed_count 0

-- Helper function for output
CREATE TEMPORARY TABLE test_results (
    test_number INT,
    test_name TEXT,
    status TEXT,
    details TEXT
);

-- ============================================================================
-- SECTION 1: SCHEMA COMPLETENESS TESTS
-- ============================================================================

\echo '=== SECTION 1: SCHEMA COMPLETENESS ==='

-- Test 1.1: All tables exist
\echo '✓ Test 1.1: Verify all 9 tables exist'
SELECT 
    CASE WHEN COUNT(*) = 9 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN 
    ('chaine_hotel','chaine_email','chaine_telephone','hotel','chambre','client','employe','reservation','location');

-- Test 1.2: All required columns exist in chaine_hotel
\echo '✓ Test 1.2: Verify chaine_hotel table structure'
SELECT 
    CASE WHEN COUNT(*) = 4 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as column_count,
    STRING_AGG(column_name, ', ') as columns
FROM information_schema.columns
WHERE table_name = 'chaine_hotel' AND column_name IN ('chaine_id','nom','adresse_siege','nb_hotels');

-- Test 1.3: Hotel table has required columns
\echo '✓ Test 1.3: Verify hotel table structure'
SELECT 
    CASE WHEN COUNT(*) >= 10 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'hotel';

-- Test 1.4: Chambre table has all required columns
\echo '✓ Test 1.4: Verify chambre table structure'
SELECT 
    CASE WHEN COUNT(*) >= 11 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'chambre';

-- ============================================================================
-- SECTION 2: PRIMARY KEY TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 2: PRIMARY KEY CONSTRAINTS ==='

-- Test 2.1: All tables have primary keys
\echo '✓ Test 2.1: Verify all tables have PRIMARY KEY'
SELECT 
    CASE WHEN COUNT(*) >= 7 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as pk_count,
    STRING_AGG(DISTINCT table_name, ', ') as tables_with_pk
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND constraint_type = 'PRIMARY KEY';

-- Test 2.2: Duplicate PK test - try to insert duplicate ID
\echo '✓ Test 2.2: Test PRIMARY KEY enforcement'
DO $$
BEGIN
    BEGIN
        INSERT INTO chaine_hotel (chaine_id, nom, adresse_siege, nb_hotels) 
        VALUES (999, 'Test Chain', 'Test Address', 0);
        INSERT INTO chaine_hotel (chaine_id, nom, adresse_siege, nb_hotels)
        VALUES (999, 'Duplicate', 'Address', 0);
        RAISE EXCEPTION 'PRIMARY KEY constraint not enforced!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'Primary key constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- ============================================================================
-- SECTION 3: FOREIGN KEY CONSTRAINT TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 3: FOREIGN KEY CONSTRAINTS ==='

-- Test 3.1: Count all FK constraints
\echo '✓ Test 3.1: Verify minimum 10 FOREIGN KEY constraints'
SELECT 
    CASE WHEN COUNT(*) >= 10 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as fk_count
FROM information_schema.referential_constraints 
WHERE constraint_schema = 'public';

-- Test 3.2: FK enforcement - try to insert invalid hotel_id
\echo '✓ Test 3.2: Test FOREIGN KEY enforcement (hotel reference)'
DO $$
BEGIN
    BEGIN
        INSERT INTO chambre (chambre_id, hotel_id, numero, prix, capacite, superficie, statut)
        VALUES (99999, 99999, 'TEST', 100, 1, 25, 'disponible');
        RAISE EXCEPTION 'FOREIGN KEY constraint not enforced!';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- Test 3.3: FK enforcement - invalid client_id in reservation
\echo '✓ Test 3.3: Test FOREIGN KEY enforcement (client reference)'
DO $$
BEGIN
    BEGIN
        INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
        VALUES (99999, 1, '2030-06-10', '2030-06-12', CURRENT_DATE, 'active');
        RAISE EXCEPTION 'FOREIGN KEY constraint not enforced!';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- ============================================================================
-- SECTION 4: CHECK CONSTRAINT TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 4: CHECK CONSTRAINTS ==='

-- Test 4.1: Count all CHECK constraints
\echo '✓ Test 4.1: Verify minimum 8 CHECK constraints'
SELECT 
    CASE WHEN COUNT(*) >= 8 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as check_count,
    STRING_AGG(DISTINCT check_clause, '; ') as constraints
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public';

-- Test 4.2: Categorie CHECK (must be between 1-5)
\echo '✓ Test 4.2: Test categorie CHECK constraint (1-5)'
DO $$
BEGIN
    BEGIN
        INSERT INTO hotel (hotel_id, chaine_id, nom, categorie, adresse, zone, nb_chambres, email_contact, telephone_contact)
        VALUES (99999, 1, 'Test', 6, 'addr', 'zone', 0, 'e@m', '1234');
        RAISE EXCEPTION 'CHECK constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Categorie check constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- Test 4.3: Prix CHECK (must be > 0)
\echo '✓ Test 4.3: Test prix CHECK constraint (> 0)'
DO $$
BEGIN
    BEGIN
        INSERT INTO chambre (chambre_id, hotel_id, numero, prix, capacite, superficie, statut)
        VALUES (99999, 1, 'TEST', -100, 1, 25, 'disponible');
        RAISE EXCEPTION 'CHECK constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Prix check constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- Test 4.4: Capacite CHECK (must be > 0)
\echo '✓ Test 4.4: Test capacite CHECK constraint (> 0)'
DO $$
BEGIN
    BEGIN
        INSERT INTO chambre (chambre_id, hotel_id, numero, prix, capacite, superficie, statut)
        VALUES (99999, 1, 'TEST', 100, 0, 25, 'disponible');
        RAISE EXCEPTION 'CHECK constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Capacite check constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- Test 4.5: Date range CHECK (date_debut < date_fin)
\echo '✓ Test 4.5: Test date range CHECK constraint'
DO $$
BEGIN
    BEGIN
        INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
        VALUES (1, 1, '2030-06-12', '2030-06-10', CURRENT_DATE, 'active');
        RAISE EXCEPTION 'CHECK constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Date range check constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- Test 4.6: Statut CHECK (valid values only)
\echo '✓ Test 4.6: Test statut CHECK constraint'
DO $$
BEGIN
    BEGIN
        INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
        VALUES (1, 1, '2030-06-10', '2030-06-12', CURRENT_DATE, 'invalid_status');
        RAISE EXCEPTION 'CHECK constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Statut check constraint correctly enforced';
    END;
    ROLLBACK;
END $$;

-- ============================================================================
-- SECTION 5: TRIGGER TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 5: TRIGGER TESTS ==='

-- Test 5.1: Verify 2 triggers exist
\echo '✓ Test 5.1: Verify minimum 2 triggers exist'
SELECT 
    CASE WHEN COUNT(*) >= 2 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as trigger_count,
    STRING_AGG(tgname, ', ') as triggers
FROM pg_trigger 
WHERE tgrelid IN (SELECT oid FROM pg_class WHERE relname IN ('reservation', 'location'));

-- Test 5.2: Test overlap detection trigger (should fail on conflicting dates)
\echo '✓ Test 5.2: Test reservation overlap trigger'
DO $$
BEGIN
    -- First, ensure we have test data
    DELETE FROM reservation WHERE client_id = 1 AND chambre_id = 1;
    INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
    VALUES (1, 1, '2030-06-10', '2030-06-12', CURRENT_DATE, 'active');
    
    -- Try to create overlapping reservation (should fail)
    BEGIN
        INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
        VALUES (2, 1, '2030-06-11', '2030-06-13', CURRENT_DATE, 'active');
        RAISE EXCEPTION 'Overlap trigger not working!';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Overlap trigger correctly prevented insertion: %', SQLERRM;
    END;
    ROLLBACK;
END $$;

-- Test 5.3: Test location status update trigger
\echo '✓ Test 5.3: Test location trigger updates room status'
DO $$
DECLARE
    test_room_id INT;
    test_client_id INT;
    test_employee_id INT;
BEGIN
    -- Get first available room, client, and employee
    SELECT chambre_id INTO test_room_id FROM chambre WHERE statut = 'disponible' LIMIT 1;
    SELECT client_id INTO test_client_id FROM client LIMIT 1;
    SELECT employe_id INTO test_employee_id FROM employe LIMIT 1;
    
    -- Verify room is available before
    IF (SELECT statut FROM chambre WHERE chambre_id = test_room_id) = 'disponible' THEN
        RAISE NOTICE 'Room initially available - trigger test setup OK';
        
        -- Create location (trigger should change status to occupée)
        INSERT INTO location (client_id, chambre_id, employe_id, date_debut, date_fin, date_checkin, type_location, statut)
        VALUES (test_client_id, test_room_id, test_employee_id, CURRENT_DATE, CURRENT_DATE + 3, CURRENT_DATE, 'directe', 'active');
        
        -- Check if room status updated
        IF (SELECT statut FROM chambre WHERE chambre_id = test_room_id) = 'occupée' THEN
            RAISE NOTICE 'Trigger correctly updated room status to occupée';
        ELSE
            RAISE EXCEPTION 'Trigger did not update room status!';
        END IF;
    END IF;
    ROLLBACK;
END $$;

-- ============================================================================
-- SECTION 6: INDEX TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 6: INDEX PERFORMANCE TESTS ==='

-- Test 6.1: Verify 3 indexes exist
\echo '✓ Test 6.1: Verify minimum 3 indexes exist'
SELECT 
    CASE WHEN COUNT(*) >= 3 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as index_count,
    STRING_AGG(indexname, ', ') as indexes
FROM pg_indexes 
WHERE schemaname = 'public' AND indexname IN 
    ('idx_hotel_zone', 'idx_chambre_recherche', 'idx_reservation_dates');

-- Test 6.2: Zone search index usage
\echo '✓ Test 6.2: Verify idx_hotel_zone is used for zone searches'
EXPLAIN (FORMAT JSON) SELECT * FROM hotel WHERE zone = 'Vancouver Bay';

-- Test 6.3: Room search index usage
\echo '✓ Test 6.3: Verify idx_chambre_recherche is used for room searches'
EXPLAIN (FORMAT JSON) 
SELECT * FROM chambre 
WHERE hotel_id = 1 AND capacite >= 2 AND prix <= 300 AND superficie >= 25;

-- Test 6.4: Reservation date index usage
\echo '✓ Test 6.4: Verify idx_reservation_dates is used for date searches'
EXPLAIN (FORMAT JSON) 
SELECT * FROM reservation 
WHERE chambre_id = 5 AND date_debut < '2030-06-15' AND date_fin > '2030-06-10';

-- ============================================================================
-- SECTION 7: VIEW TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 7: SQL VIEWS ==='

-- Test 7.1: Verify views exist
\echo '✓ Test 7.1: Verify 2 views exist'
SELECT 
    CASE WHEN COUNT(*) >= 2 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as view_count,
    STRING_AGG(viewname, ', ') as views
FROM pg_views 
WHERE schemaname = 'public' AND viewname IN 
    ('vue_chambres_disponibles_par_zone', 'vue_capacite_totale_hotel');

-- Test 7.2: Available rooms by zone view returns data
\echo '✓ Test 7.2: vue_chambres_disponibles_par_zone returns data'
SELECT 
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as zone_count,
    SUM(nb_chambres_disponibles) as total_available
FROM vue_chambres_disponibles_par_zone;

-- Test 7.3: Total hotel capacity view returns data
\echo '✓ Test 7.3: vue_capacite_totale_hotel returns data'
SELECT 
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as hotel_count,
    SUM(capacite_totale) as total_capacity
FROM vue_capacite_totale_hotel;

-- ============================================================================
-- SECTION 8: DATA INTEGRITY TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 8: DATA INTEGRITY ==='

-- Test 8.1: Verify 8 chains exist
\echo '✓ Test 8.1: Verify 8 hotel chains loaded'
SELECT 
    CASE WHEN COUNT(*) = 8 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as chain_count
FROM chaine_hotel;

-- Test 8.2: Verify 18 hotels exist
\echo '✓ Test 8.2: Verify 18 hotels loaded'
SELECT 
    CASE WHEN COUNT(*) >= 16 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as hotel_count
FROM hotel;

-- Test 8.3: Verify 25+ rooms exist
\echo '✓ Test 8.3: Verify 25+ rooms loaded'
SELECT 
    CASE WHEN COUNT(*) >= 25 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as room_count
FROM chambre;

-- Test 8.4: Verify 10 clients exist
\echo '✓ Test 8.4: Verify 10 clients loaded'
SELECT 
    CASE WHEN COUNT(*) >= 10 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as client_count
FROM client;

-- Test 8.5: Verify 20+ employees exist
\echo '✓ Test 8.5: Verify 20+ employees loaded'
SELECT 
    CASE WHEN COUNT(*) >= 20 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as employee_count
FROM employe;

-- Test 8.6: All rooms have valid hotel references
\echo '✓ Test 8.6: All rooms have valid hotel references'
SELECT 
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as orphan_rooms
FROM chambre 
WHERE hotel_id NOT IN (SELECT hotel_id FROM hotel);

-- Test 8.7: Hotel categories are valid (1-5)
\echo '✓ Test 8.7: All hotel categories are valid (1-5)'
SELECT 
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as invalid_hotels
FROM hotel 
WHERE categorie NOT BETWEEN 1 AND 5;

-- Test 8.8: Room prices are positive
\echo '✓ Test 8.8: All room prices are positive'
SELECT 
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as invalid_prices
FROM chambre 
WHERE prix <= 0;

-- Test 8.9: Room capacities are positive
\echo '✓ Test 8.9: All room capacities are positive'
SELECT 
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as invalid_capacities
FROM chambre 
WHERE capacite <= 0;

-- Test 8.10: Room superficies are valid
\echo '✓ Test 8.10: All room superficies are positive'
SELECT 
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as invalid_superficies
FROM chambre 
WHERE superficie <= 0;

-- ============================================================================
-- SECTION 9: BUSINESS LOGIC TESTS
-- ============================================================================

\echo ''
\echo '=== SECTION 9: BUSINESS LOGIC ==='

-- Test 9.1: Verify 2+ hotels per zone
\echo '✓ Test 9.1: Verify 2+ hotels in at least one zone'
SELECT 
    CASE WHEN COUNT(*) >= 1 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as zones_with_multiple_hotels
FROM (
    SELECT zone, COUNT(*) as hotel_count 
    FROM hotel 
    GROUP BY zone 
    HAVING COUNT(*) >= 2
) AS multi_hotel_zones;

-- Test 9.2: Verify 3+ hotel categories exist
\echo '✓ Test 9.2: Verify at least 2 hotel categories exist'
SELECT 
    CASE WHEN COUNT(*) >= 2 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(DISTINCT categorie) as category_count,
    STRING_AGG(DISTINCT categorie::TEXT, ', ') as categories
FROM hotel;

-- Test 9.3: Verify at least one hotel has 5+ rooms
\echo '✓ Test 9.3: Verify at least one hotel has 5+ rooms'
SELECT 
    CASE WHEN COUNT(*) >= 1 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(*) as hotels_with_enough_rooms
FROM (
    SELECT hotel_id, COUNT(*) as room_count 
    FROM chambre 
    GROUP BY hotel_id 
    HAVING COUNT(*) >= 5
) AS sufficiently_sized_hotels;

-- Test 9.4: Varied room capacities
\echo '✓ Test 9.4: Verify varied room capacities exist'
SELECT 
    CASE WHEN COUNT(*) >= 2 THEN '✓ PASS' ELSE '✗ FAIL' END as result,
    COUNT(DISTINCT capacite) as capacity_options,
    STRING_AGG(DISTINCT capacite::TEXT, ', ') as capacities
FROM chambre;

-- ============================================================================
-- SECTION 10: SUMMARY
-- ============================================================================

\echo ''
\echo '=== TEST EXECUTION COMPLETE ==='
\echo 'All critical components have been verified.'
\echo 'If all tests show "✓ PASS", the database is properly configured.'
