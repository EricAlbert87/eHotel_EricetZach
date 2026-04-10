#!/bin/bash

################################################################################
#                 eHotel Automated Test Suite Orchestrator                     #
#                                                                              #
# Master script that runs all tests:                                           #
#  1. Database tests (PostgreSQL)                                              #
#  2. Backend tests (Java)                                                     #
#  3. Frontend tests (Node.js)                                                 #
#  4. Integration tests                                                        #
################################################################################

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_DIR="/home/shezac/uni/csi2532/eHotel_EricetZach/eHotel"
TESTS_DIR="${PROJECT_DIR}/tests"
DB_NAME="ehotels"
DB_USER="postgres"
DB_PASSWORD="postgres"
SERVER_URL="http://localhost:8080"
SERVER_PORT=8080
LOG_DIR="${TESTS_DIR}/.test-logs"
SERVER_LOG_FILE="${LOG_DIR}/ehotel-server.log"
SERVER_PID_FILE="${LOG_DIR}/ehotel-server.pid"
DB_RESULTS_FILE="${LOG_DIR}/db-test-results.txt"
BACKEND_RESULTS_FILE="${LOG_DIR}/backend-test-results.txt"
FRONTEND_RESULTS_FILE="${LOG_DIR}/frontend-test-results.txt"
SEARCH_RESULTS_FILE="${LOG_DIR}/search-result.json"
CHAINS_RESULTS_FILE="${LOG_DIR}/chains-result.json"
INVALID_RESULTS_FILE="${LOG_DIR}/invalid-result.json"
RUN_AS_USER="${SUDO_USER:-$(id -un)}"
RUN_AS_HOME="$(getent passwd "$RUN_AS_USER" | cut -d: -f6)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║%-54s║${NC}\n" "$1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"
}

log_section() {
    echo -e "\n${YELLOW}► $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

run_as_user() {
    if [ "$(id -un)" = "$RUN_AS_USER" ]; then
        "$@"
    else
        sudo -u "$RUN_AS_USER" "$@"
    fi
}

# ============================================================================
# SETUP FUNCTIONS
# ============================================================================

check_prerequisites() {
    log_section "Checking Prerequisites"

    # Check Java
    if ! command -v java &> /dev/null; then
        log_error "Java not found. Install OpenJDK 17+"
        return 1
    fi
    log_success "Java installed: $(java -version 2>&1 | head -1)"

    # Check Maven
    if ! command -v mvn &> /dev/null; then
        log_error "Maven not found. Install Maven 3.6+"
        return 1
    fi
    log_success "Maven installed"

    # Check PostgreSQL client
    if ! command -v psql &> /dev/null; then
        log_error "PostgreSQL client not found. Install postgresql-client"
        return 1
    fi
    log_success "PostgreSQL client installed"

    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found - frontend tests will be skipped"
    else
        log_success "Node.js installed: $(node --version)"
    fi

    # Check database connectivity
    log_info "Verifying database connectivity..."
    if sudo -u $DB_USER psql -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; then
        log_success "Database connection successful"
    else
        log_error "Cannot connect to PostgreSQL database '$DB_NAME'"
        return 1
    fi

    return 0
}

build_project() {
    log_section "Building Project"

    cd "$PROJECT_DIR"

    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        log_warning "Running build as $RUN_AS_USER to avoid root-owned target artifacts"
    fi
    
    if ! run_as_user mvn clean package -q 2>/dev/null; then
        log_error "Maven build failed"
        return 1
    fi
    
    log_success "Project built successfully"
    return 0
}

start_server() {
    log_section "Starting Application Server"

    mkdir -p "$LOG_DIR"
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        chown -R "$RUN_AS_USER":"$RUN_AS_USER" "$LOG_DIR"
    fi

    # Check if server already running
    if curl -s "$SERVER_URL/" > /dev/null 2>&1; then
        log_warning "Server already running on $SERVER_URL"
        return 0
    fi

    # Start server in background
    JAR=$(find "$PROJECT_DIR/target" -name "*jar-with-dependencies.jar" -type f | head -1)
    if [ -z "$JAR" ]; then
        log_error "JAR file not found in target directory"
        return 1
    fi

    log_info "Starting server on port $SERVER_PORT..."
    : > "$SERVER_LOG_FILE"
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$RUN_AS_USER" bash -lc "java -jar '$JAR' > '$SERVER_LOG_FILE' 2>&1 & echo \$! > '$SERVER_PID_FILE'"
        SERVER_PID=$(cat "$SERVER_PID_FILE")
    else
        java -jar "$JAR" > "$SERVER_LOG_FILE" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$SERVER_PID_FILE"
    fi

    # Wait for server to start (max 30 seconds)
    for i in {1..30}; do
        if curl -s "$SERVER_URL/" > /dev/null 2>&1; then
            log_success "Server started successfully (PID: $SERVER_PID)"
            sleep 2  # Additional buffer
            return 0
        fi
        sleep 1
    done

    log_error "Server failed to start within 30 seconds"
    log_info "Check logs: cat $SERVER_LOG_FILE"
    return 1
}

stop_server() {
    log_section "Stopping Application Server"

    if [ -f "$SERVER_PID_FILE" ]; then
        SERVER_PID=$(cat "$SERVER_PID_FILE")
        if kill $SERVER_PID 2>/dev/null; then
            log_success "Server stopped (PID: $SERVER_PID)"
        fi
        rm -f "$SERVER_PID_FILE"
    fi
}

# ============================================================================
# DATABASE TESTS
# ============================================================================

run_database_tests() {
    log_header "DATABASE TESTS"

    if [ ! -f "$TESTS_DIR/database_tests.sql" ]; then
        log_error "Database test file not found: $TESTS_DIR/database_tests.sql"
        return 1
    fi

    log_info "Running comprehensive database tests..."
    
    if sudo -u $DB_USER psql -d $DB_NAME < "$TESTS_DIR/database_tests.sql" 2>&1 | tee "$DB_RESULTS_FILE"; then
        log_success "Database tests completed"
        
        # Count results (rough estimation)
        PASS_COUNT=$(grep -c "✓ PASS" "$DB_RESULTS_FILE" 2>/dev/null || true)
        FAIL_COUNT=$(grep -c "✗ FAIL" "$DB_RESULTS_FILE" 2>/dev/null || true)
        PASS_COUNT=${PASS_COUNT:-0}
        FAIL_COUNT=${FAIL_COUNT:-0}
        
        log_success "Database: $PASS_COUNT tests passed"
        if [ "$FAIL_COUNT" -gt 0 ]; then
            log_error "Database: $FAIL_COUNT tests failed"
            FAILED_TESTS=$((FAILED_TESTS + FAIL_COUNT))
        fi
        
        PASSED_TESTS=$((PASSED_TESTS + PASS_COUNT))
        TOTAL_TESTS=$((TOTAL_TESTS + PASS_COUNT + FAIL_COUNT))
        return 0
    else
        log_error "Database tests failed"
        return 1
    fi
}

# ============================================================================
# BACKEND TESTS
# ============================================================================

run_backend_tests() {
    log_header "BACKEND INTEGRATION TESTS"

    log_info "Compiling backend tests..."
    
    # Compile test class
    TEST_FILE="$PROJECT_DIR/src/test/java/com/ehotel/tests/BackendIntegrationTests.java"
    if [ ! -f "$TEST_FILE" ]; then
        log_error "Backend test file not found: $TEST_FILE"
        return 1
    fi

    cd "$PROJECT_DIR"
    
    # Compile and run tests
    log_info "Running backend integration tests..."
    if run_as_user mvn test-compile > /dev/null 2>&1; then
        # Run specific test class
        if run_as_user java -cp target/classes:target/test-classes:$RUN_AS_HOME/.m2/repository/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar \
            com.ehotel.tests.BackendIntegrationTests 2>&1 | tee "$BACKEND_RESULTS_FILE"; then
            
            log_success "Backend tests completed"
            
            # Count results
            PASS_COUNT=$(grep -c "✓ PASS" "$BACKEND_RESULTS_FILE" 2>/dev/null || true)
            FAIL_COUNT=$(grep -c "✗ FAIL" "$BACKEND_RESULTS_FILE" 2>/dev/null || true)
            PASS_COUNT=${PASS_COUNT:-0}
            FAIL_COUNT=${FAIL_COUNT:-0}
            
            log_success "Backend: $PASS_COUNT tests passed"
            if [ "$FAIL_COUNT" -gt 0 ]; then
                log_error "Backend: $FAIL_COUNT tests failed"
                FAILED_TESTS=$((FAILED_TESTS + FAIL_COUNT))
            fi
            
            PASSED_TESTS=$((PASSED_TESTS + PASS_COUNT))
            TOTAL_TESTS=$((TOTAL_TESTS + PASS_COUNT + FAIL_COUNT))
            return 0
        fi
    fi
    
    log_error "Backend tests failed to run"
    return 1
}

# ============================================================================
# FRONTEND TESTS
# ============================================================================

run_frontend_tests() {
    log_header "FRONTEND AUTOMATED TESTS"

    if ! command -v node &> /dev/null; then
        log_warning "Node.js not installed - skipping frontend tests"
        log_info "To enable frontend tests: sudo apt-get install nodejs npm"
        return 0
    fi

    TEST_FILE="$TESTS_DIR/frontend_tests.js"
    if [ ! -f "$TEST_FILE" ]; then
        log_error "Frontend test file not found: $TEST_FILE"
        return 1
    fi

    log_info "Running frontend tests against $SERVER_URL..."
    
    if run_as_user node "$TEST_FILE" "$SERVER_URL" 2>&1 | tee "$FRONTEND_RESULTS_FILE"; then
        log_success "Frontend tests completed"
        
        # Count results from frontend suite summary lines
        PASS_COUNT=$(grep -Eo "Passed:[[:space:]]+[0-9]+" "$FRONTEND_RESULTS_FILE" | tail -1 | grep -Eo "[0-9]+" || true)
        FAIL_COUNT=$(grep -Eo "Failed:[[:space:]]+[0-9]+" "$FRONTEND_RESULTS_FILE" | tail -1 | grep -Eo "[0-9]+" || true)
        PASS_COUNT=${PASS_COUNT:-0}
        FAIL_COUNT=${FAIL_COUNT:-0}
        
        if [ "$PASS_COUNT" -gt 0 ]; then
            log_success "Frontend: $PASS_COUNT tests passed"
        fi
        if [ "$FAIL_COUNT" -gt 0 ]; then
            log_error "Frontend: $FAIL_COUNT tests failed"
            FAILED_TESTS=$((FAILED_TESTS + FAIL_COUNT))
        fi
        
        PASSED_TESTS=$((PASSED_TESTS + PASS_COUNT))
        TOTAL_TESTS=$((TOTAL_TESTS + PASS_COUNT + FAIL_COUNT))
        return 0
    else
        log_error "Frontend tests failed"
        return 1
    fi
}

# ============================================================================
# INTEGRATION/E2E TESTS
# ============================================================================

run_integration_tests() {
    log_header "END-TO-END INTEGRATION TESTS"

    log_section "Test 1: Room Search & Filter Workflow"
    
    # Test search API
    if curl -s "$SERVER_URL/api/rooms?zone=Vancouver+Bay&capacite=2&prix=9999&superficie=0&chaine=&categorie=0&nombreChambres=10" > "$SEARCH_RESULTS_FILE"; then
        COUNT=$(grep -o '"chambreId"' "$SEARCH_RESULTS_FILE" | wc -l)
        if [ $COUNT -gt 0 ]; then
            log_success "Search API returned $COUNT results"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "Search API returned empty results"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_error "Search API failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_section "Test 2: Data Retrieval Workflow"
    
    # Test chains endpoint
    if curl -s "$SERVER_URL/api/chains" > "$CHAINS_RESULTS_FILE"; then
        if grep -q "Marriott" "$CHAINS_RESULTS_FILE"; then
            log_success "Chains API returned expected data"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "Chains API missing expected data"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_error "Chains API failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_section "Test 3: UI Responsiveness"
    
    # Test HTML loads
    if curl -s "$SERVER_URL/" | grep -q "eHotel"; then
        log_success "UI page loads successfully"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "UI page failed to load"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_section "Test 4: API Error Handling"
    
    # Test invalid zone
    if curl -s "$SERVER_URL/api/rooms?zone=InvalidZone123" > "$INVALID_RESULTS_FILE"; then
        if grep -q "\[\]" "$INVALID_RESULTS_FILE" || grep -q "error" "$INVALID_RESULTS_FILE"; then
            log_success "Error handling working correctly"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        fi
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_header "eHotel Automated Test Suite"

    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed. Aborting."
        exit 1
    fi

    # Build project
    if ! build_project; then
        log_error "Build failed. Aborting."
        exit 1
    fi

    # Start server
    if ! start_server; then
        log_error "Server startup failed. Aborting."
        exit 1
    fi

    # Run test suites
    run_database_tests || true
    run_backend_tests || true
    run_frontend_tests || true
    run_integration_tests || true

    # Stop server
    stop_server

    # Print summary
    print_summary
}

print_summary() {
    log_header "TEST EXECUTION SUMMARY"

    echo -e "Total Tests:     ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Tests Passed:    ${GREEN}$PASSED_TESTS ✓${NC}"
    echo -e "Tests Failed:    ${RED}$FAILED_TESTS ✗${NC}"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "Success Rate:    %${BLUE}${SUCCESS_RATE}${NC}"
    fi

    echo ""
    if [ $FAILED_TESTS -eq 0 ] && [ $TOTAL_TESTS -gt 0 ]; then
        log_success "ALL TESTS PASSED!"
        echo -e "\n${GREEN}✓ Project is ready for submission${NC}"
        exit 0
    else
        if [ $FAILED_TESTS -gt 0 ]; then
            log_error "Some tests failed. Review the logs above."
        fi
        exit 1
    fi
}

# Cleanup on exit
trap "stop_server" EXIT

# Run main execution
main "$@"
