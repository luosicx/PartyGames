#!/bin/bash
# =============================================================================
# SonarQube Community Edition — Analysis Runner
#
# Prerequisites:
#   brew install sonar-scanner swiftlint
#   docker run -d --name sonarqube -p 9000:9000 sonarqube:community
#
# Usage:
#   export SONAR_HOST_URL=http://localhost:9000
#   export SONAR_LOGIN=<your-token>
#   ./scripts/sonar.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

SCHEME="PartyGames"
PROJECT="PartyGames.xcodeproj"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData/PartyGames-$(uuidgen | cut -c1-8)"
SIMULATOR="platform=iOS Simulator,name=iPhone 17 Pro"
COVERAGE_DIR="$PROJECT_DIR/coverage"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[sonar]${NC} $1"; }
warn() { echo -e "${YELLOW}[sonar]${NC} $1"; }
err()  { echo -e "${RED}[sonar]${NC} $1"; exit 1; }

# ---- Prerequisite Check ----
check_prereqs() {
    log "Checking prerequisites..."

    if ! command -v sonar-scanner &>/dev/null; then
        err "sonar-scanner not found. Install: brew install sonar-scanner"
    fi

    if ! command -v swiftlint &>/dev/null; then
        warn "swiftlint not installed, skipping lint report"
    fi

    if ! command -v xcodebuild &>/dev/null; then
        err "xcodebuild not found"
    fi

    log "All prerequisites satisfied"
}

# ---- Step 1: Clean DerivedData ----
clean() {
    log "Cleaning derived data..."
    rm -rf "$DERIVED_DATA"
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
}

# ---- Step 2: Build + Run Tests with Coverage ----
run_tests() {
    log "Building and running tests with coverage..."

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$SIMULATOR" \
        -derivedDataPath "$DERIVED_DATA" \
        -enableCodeCoverage YES \
        -quiet \
        2>&1 | tail -20

    # Locate xcresult
    XCRESULT=$(find "$DERIVED_DATA/Logs/Test" -name "*.xcresult" -type d 2>/dev/null | head -1)
    if [ -z "$XCRESULT" ]; then
        warn "No .xcresult found — skipping coverage"
        return 0
    fi

    echo "$XCRESULT" > "$COVERAGE_DIR/xcresult-path.txt"
    log "Test results: $XCRESULT"
}

# ---- Step 3: Convert Coverage ----
convert_coverage() {
    XCRESULT=$(cat "$COVERAGE_DIR/xcresult-path.txt" 2>/dev/null || echo "")
    if [ -z "$XCRESULT" ] || [ ! -d "$XCRESULT" ]; then
        warn "No xcresult available, skipping coverage conversion"
        return 0
    fi

    log "Converting coverage to SonarQube format..."
    python3 "$SCRIPT_DIR/xcresult-to-sonarqube.py" "$XCRESULT" "$PROJECT_DIR"
}

# ---- Step 4: SwiftLint Report ----
run_swiftlint() {
    if ! command -v swiftlint &>/dev/null; then
        return 0
    fi

    log "Running SwiftLint with SonarQube reporter..."
    swiftlint lint --reporter sonarqube > "$PROJECT_DIR/swiftlint-report.json" 2>/dev/null || true
    log "SwiftLint report: $PROJECT_DIR/swiftlint-report.json"
}

# ---- Step 5: Sonar Scanner ----
run_scanner() {
    log "Running sonar-scanner..."

    local host="${SONAR_HOST_URL:-http://localhost:9000}"
    local login="${SONAR_LOGIN:-}"

    echo "  Host:  $host"
    echo "  Login: ${login:0:6}..."

    if [ -z "$login" ]; then
        warn "SONAR_LOGIN not set. Provide a token via: export SONAR_LOGIN=sqp_..."
        warn "Skipping sonar-scanner. Set the token and re-run."
        return 1
    fi

    sonar-scanner \
        -Dsonar.host.url="$host" \
        -Dsonar.login="$login" \
        -Dproject.settings="$PROJECT_DIR/sonar-project.properties"

    log "SonarQube analysis complete → $host/dashboard?id=com.partygames.app"
}

# ---- Main ----
main() {
    echo ""
    echo "=============================================="
    echo "  SonarQube Analysis — PartyGames"
    echo "=============================================="
    echo ""

    check_prereqs
    clean
    run_tests
    convert_coverage
    run_swiftlint
    run_scanner

    echo ""
    log "Done. View results at: ${SONAR_HOST_URL:-http://localhost:9000}/dashboard?id=com.partygames.app"
}

main
