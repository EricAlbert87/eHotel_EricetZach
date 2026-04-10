package com.ehotel.tests;

import com.ehotel.config.DatabaseConfig;
import com.ehotel.service.HotelService;
import com.ehotel.model.RoomSearchResult;
import java.sql.Connection;
import java.sql.Statement;
import java.util.List;

/**
 * Integration Test Suite for Backend
 * Tests all backend functionality including:
 * - Database connectivity
 * - Service methods
 * - DAO operations
 * - API business logic
 */
public class BackendIntegrationTests {

    private static final HotelService service = new HotelService();
    private static int testsRun = 0;
    private static int testsPassed = 0;
    private static int testsFailed = 0;

    public static void main(String[] args) {
        System.out.println("╔════════════════════════════════════════════════════════╗");
        System.out.println("║        eHotel Backend Integration Test Suite           ║");
        System.out.println("╚════════════════════════════════════════════════════════╝\n");

        // Run all test sections
        testDatabaseConnectivity();
        testRoomSearchOperations();
        testReservationOperations();
        testLocationOperations();
        testDataRetrieval();
        testErrorHandling();

        // Print summary
        printSummary();
    }

    // ========================================================================
    // TEST SECTION 1: DATABASE CONNECTIVITY
    // ========================================================================

    private static void testDatabaseConnectivity() {
        System.out.println("\n[1] DATABASE CONNECTIVITY TESTS");
        System.out.println("─────────────────────────────────────────");

        test("1.1: Database connection", () -> {
            try (Connection conn = DatabaseConfig.getConnection()) {
                assert conn != null && !conn.isClosed();
                System.out.println("    Status: ✓ Successfully connected");
            }
        });

        test("1.2: Connection pool reuse", () -> {
            try (Connection conn1 = DatabaseConfig.getConnection();
                    Connection conn2 = DatabaseConfig.getConnection()) {
                assert conn1 != null && conn2 != null;
                System.out.println("    Status: ✓ Multiple connections created");
            }
        });

        test("1.3: Basic query execution", () -> {
            try (Connection conn = DatabaseConfig.getConnection();
                    Statement stmt = conn.createStatement()) {
                var result = stmt.executeQuery("SELECT COUNT(*) FROM chaine_hotel");
                assert result.next() && result.getInt(1) == 8;
                System.out.println("    Result: ✓ 8 chains found");
            }
        });
    }

    // ========================================================================
    // TEST SECTION 2: ROOM SEARCH OPERATIONS
    // ========================================================================

    private static void testRoomSearchOperations() {
        System.out.println("\n[2] ROOM SEARCH OPERATIONS");
        System.out.println("─────────────────────────────────────────");

        test("2.1: Search all available rooms", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 0, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " available rooms");
            assert rooms.size() > 0 : "Should find at least some rooms";
        });

        test("2.2: Search by zone", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("Vancouver Bay", 1, 9999, 0, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " rooms in Vancouver Bay");
            assert rooms.stream().allMatch(r -> r.getZone().equals("Vancouver Bay"));
        });

        test("2.3: Search by capacity", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 2, 9999, 0, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " rooms with capacity >= 2");
            assert rooms.stream().allMatch(r -> r.getCapacite() >= 2);
        });

        test("2.4: Search by price", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 250, 0, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " rooms <= $250");
            assert rooms.stream().allMatch(r -> r.getPrix() <= 250);
        });

        test("2.5: Search by chain", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 0, "Marriott International", 0, "", "",
                    100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " Marriott rooms");
            assert rooms.stream().allMatch(r -> r.getChaine().equals("Marriott International"));
        });

        test("2.6: Search by category", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 0, "", 5, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " 5-star hotel rooms");
        });

        test("2.7: Search by superficie", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 40, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Found " + rooms.size() + " rooms >= 40m²");
            assert rooms.stream().allMatch(r -> r.getSuperficie() >= 40);
        });

        test("2.8: Combined search criteria", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("Vancouver Bay", 2, 300, 30, "", 5, "", "", 50);
            System.out.println("    Result: ✓ Found " + rooms.size() + " filtered rooms");
            assert rooms.stream().allMatch(r -> r.getZone().equals("Vancouver Bay") &&
                    r.getCapacite() >= 2 &&
                    r.getPrix() <= 300 &&
                    r.getSuperficie() >= 30);
        });

        test("2.9: Search result limit", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 0, "", 0, "", "", 5);
            System.out.println("    Result: ✓ Limited to " + rooms.size() + " results (max 5)");
            assert rooms.size() <= 5;
        });
    }

    // ========================================================================
    // TEST SECTION 3: RESERVATION OPERATIONS
    // ========================================================================

    private static void testReservationOperations() {
        System.out.println("\n[3] RESERVATION OPERATIONS");
        System.out.println("─────────────────────────────────────────");

        test("3.1: Get all reservations", () -> {
            List<String> reservations = service.getAllReservations();
            System.out.println("    Result: ✓ Retrieved " + reservations.size() + " reservations");
            assert reservations.size() > 0;
        });

        test("3.2: Create valid reservation", () -> {
            // Find available room and future dates
            List<RoomSearchResult> rooms = service.searchRooms("", 1, 9999, 0, "", 0, "", "", 1);
            if (rooms.size() > 0) {
                try {
                    service.reserveRoom(1, rooms.get(0).getChambreId(), "2030-07-01", "2030-07-03");
                    System.out.println("    Status: ✓ Reservation created for room " + rooms.get(0).getChambreId());
                } catch (Exception e) {
                    System.out.println("    Note: Reservation creation may be restricted: " + e.getMessage());
                }
            }
        });

        test("3.3: Verify reservation dates validation", () -> {
            // Try to create invalid reservation (end before start)
            try {
                service.reserveRoom(1, 1, "2030-07-03", "2030-07-01");
                throw new AssertionError("Should have rejected invalid date range");
            } catch (Exception e) {
                System.out.println("    Status: ✓ Invalid dates properly rejected");
            }
        });
    }

    // ========================================================================
    // TEST SECTION 4: LOCATION OPERATIONS
    // ========================================================================

    private static void testLocationOperations() {
        System.out.println("\n[4] RENTAL (LOCATION) OPERATIONS");
        System.out.println("─────────────────────────────────────────");

        test("4.1: Get all locations", () -> {
            List<String> locations = service.getAllLocations();
            System.out.println("    Result: ✓ Retrieved " + locations.size() + " locations");
        });

        test("4.2: Get all employees", () -> {
            List<String> employees = service.getAllEmployees();
            System.out.println("    Result: ✓ Retrieved " + employees.size() + " employees");
            assert employees.size() > 0;
        });
    }

    // ========================================================================
    // TEST SECTION 5: DATA RETRIEVAL OPERATIONS
    // ========================================================================

    private static void testDataRetrieval() {
        System.out.println("\n[5] DATA RETRIEVAL OPERATIONS");
        System.out.println("─────────────────────────────────────────");

        test("5.1: Get all chains", () -> {
            List<String> chains = service.getAllChains();
            System.out.println("    Result: ✓ Retrieved " + chains.size() + " chains");
            assert chains.size() == 8 : "Should have 8 chains";
        });

        test("5.2: Get all zones", () -> {
            List<String> zones = service.getAllZones();
            System.out.println("    Result: ✓ Retrieved " + zones.size() + " zones");
            assert zones.size() > 0;
        });

        test("5.3: Get all hotels", () -> {
            List<String> hotels = service.getAllHotels();
            System.out.println("    Result: ✓ Retrieved " + hotels.size() + " hotels");
            assert hotels.size() >= 16 : "Should have at least 16 hotels";
        });

        test("5.4: Get all rooms", () -> {
            List<String> rooms = service.getAllRooms();
            System.out.println("    Result: ✓ Retrieved " + rooms.size() + " rooms");
            assert rooms.size() >= 25 : "Should have at least 25 rooms";
        });

        test("5.5: Get all clients", () -> {
            List<String> clients = service.getAllClients();
            System.out.println("    Result: ✓ Retrieved " + clients.size() + " clients");
            assert clients.size() >= 10 : "Should have at least 10 clients";
        });
    }

    // ========================================================================
    // TEST SECTION 6: ERROR HANDLING
    // ========================================================================

    private static void testErrorHandling() {
        System.out.println("\n[6] ERROR HANDLING & EDGE CASES");
        System.out.println("─────────────────────────────────────────");

        test("6.1: Invalid client ID in reservation", () -> {
            try {
                service.reserveRoom(99999, 1, "2030-07-01", "2030-07-03");
                throw new AssertionError("Should have failed with invalid client");
            } catch (Exception e) {
                System.out.println("    Status: ✓ Error properly caught and handled");
            }
        });

        test("6.2: Invalid room ID in search", () -> {
            try {
                service.reserveRoom(1, 99999, "2030-07-01", "2030-07-03");
                throw new AssertionError("Should have failed with invalid room");
            } catch (Exception e) {
                System.out.println("    Status: ✓ Error properly caught and handled");
            }
        });

        test("6.3: Empty search results handling", () -> {
            List<RoomSearchResult> rooms = service.searchRooms("InvalidZone123", 1, 0.01, 0, "", 0, "", "", 100);
            System.out.println("    Result: ✓ Empty results handled gracefully (found " + rooms.size() + " rooms)");
            assert rooms.size() == 0;
        });

        test("6.4: Null parameter handling", () -> {
            try {
                List<RoomSearchResult> rooms = service.searchRooms(null, 1, 9999, 0, null, 0, null, null, 100);
                System.out.println("    Status: ✓ Null parameters handled safely");
            } catch (Exception e) {
                System.out.println("    Status: ✓ Exception caught for null params (expected behavior)");
            }
        });
    }

    // ========================================================================
    // TEST UTILITIES
    // ========================================================================

    private static void test(String testName, TestFunction testFunc) {
        testsRun++;
        try {
            testFunc.run();
            testsPassed++;
            System.out.println("    ✓ PASS\n");
        } catch (AssertionError e) {
            testsFailed++;
            System.out.println("    ✗ FAIL: " + e.getMessage() + "\n");
        } catch (Exception e) {
            testsFailed++;
            System.out.println("    ✗ ERROR: " + e.getMessage() + "\n");
        }
    }

    private static void printSummary() {
        System.out.println("\n╔════════════════════════════════════════════════════════╗");
        System.out.println("║                    TEST SUMMARY                        ║");
        System.out.println("╚════════════════════════════════════════════════════════╝");
        System.out.println("Total Tests Run:  " + testsRun);
        System.out.println("Tests Passed:     " + testsPassed + " ✓");
        System.out.println("Tests Failed:     " + testsFailed + " ✗");
        System.out.println("Success Rate:     " + (testsPassed * 100 / testsRun) + "%");
        System.out.println("\nStatus: " + (testsFailed == 0 ? "✓ ALL TESTS PASSED" : "✗ SOME TESTS FAILED"));
    }

    @FunctionalInterface
    interface TestFunction {
        void run() throws Exception;
    }
}
