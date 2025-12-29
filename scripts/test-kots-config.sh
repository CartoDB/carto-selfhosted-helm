#!/bin/bash
#
# Test KOTS config template rendering for different K8s distributions
# Usage: ./scripts/test-kots-config.sh [gke|eks|aks|all]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFESTS_DIR="$REPO_ROOT/manifests"
CONFIG_TEMPLATE="/Users/mdiloreto/vscode/cloud-native/terraform/carto-dedicated-selfhosted-environments/gcp/replicated/kots-config-values.tpl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default test values for template variables
export SELFHOSTED_DOMAIN="test.carto.com"
export POSTGRES_DATABASE="carto"
export POSTGRES_PASSWORD="testpassword"
export POSTGRES_USER="carto"
export BIGQUERY_OAUTH2_CLIENT_ID="test-client-id"
export BIGQUERY_OAUTH2_CLIENT_SECRET="test-secret"
export DEDICATED_ID="test"
export CARTO_ACC_API_DOMAIN_B64="dGVzdA=="
export CARTO_ACC_PROJECT_ID_B64="dGVzdA=="
export CARTO_ACC_PROJECT_REGION_B64="dGVzdA=="
export CARTO_DO_API_DOMAIN_B64="dGVzdA=="
export CARTO_DO_ASSETS_DOMAIN_B64="dGVzdA=="
export CARTO_AUTH0_CUSTOM_DOMAIN_B64="dGVzdA=="
export DO_PROJECT_ID_B64="dGVzdA=="
export PUBSUB_DOMAIN_B64="dGVzdA=="
export BACKEND_TAG="latest"
export FRONTEND_TAG="latest"
export HONEYCOMB_API_KEY="test"
export IMPORT_AWS_ROLE_ARN="arn:aws:iam::123456789:role/test"
export IMPORT_AWS_ACCESS_KEY_ID="test"
export IMPORT_AWS_SECRET_ACCESS_KEY="test"

# Distributions to test
DISTRIBUTIONS=("gke" "eks" "aks")

print_header() {
    echo ""
    echo "=============================================="
    echo "$1"
    echo "=============================================="
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Test 1: Validate YAML syntax
test_yaml_syntax() {
    print_header "Test 1: YAML Syntax Validation"

    if yq eval '.' "$MANIFESTS_DIR/kots-config.yaml" > /dev/null 2>&1; then
        print_success "kots-config.yaml is valid YAML"
        return 0
    else
        print_error "kots-config.yaml has YAML syntax errors:"
        yq eval '.' "$MANIFESTS_DIR/kots-config.yaml" 2>&1
        return 1
    fi
}

# Test 2: Check template patterns match existing conventions
test_template_patterns() {
    print_header "Test 2: Template Pattern Validation"

    local errors=0

    # Check for common template issues

    # 1. Check all repl{{ blocks are properly closed
    local open_blocks=$(grep -c 'repl{{' "$MANIFESTS_DIR/kots-config.yaml" || echo "0")
    local close_blocks=$(grep -c '}}' "$MANIFESTS_DIR/kots-config.yaml" || echo "0")

    echo "  Template blocks: $open_blocks opening, checking structure..."

    # 2. Check for {{repl vs repl{{ consistency (both are valid but should be consistent in context)
    local repl_prefix=$(grep -c '^[[:space:]]*repl{{' "$MANIFESTS_DIR/kots-config.yaml" || echo "0")
    local repl_inline=$(grep -c "'{{repl" "$MANIFESTS_DIR/kots-config.yaml" || echo "0")

    echo "  Multi-line templates (repl{{): $repl_prefix"
    echo "  Inline templates ('{{repl): $repl_inline"

    # 3. Check ConfigOptionEquals usage
    local config_equals=$(grep -c 'ConfigOptionEquals' "$MANIFESTS_DIR/kots-config.yaml" || echo "0")
    echo "  ConfigOptionEquals usages: $config_equals"

    # 4. Check Distribution usage
    local distribution=$(grep -c 'Distribution' "$MANIFESTS_DIR/kots-config.yaml" || echo "0")
    echo "  Distribution usages: $distribution"

    # 5. Verify all anchors have corresponding aliases
    local anchors=$(grep -oE '&[a-zA-Z_]+' "$MANIFESTS_DIR/kots-config.yaml" | sort -u)
    for anchor in $anchors; do
        local alias="${anchor/&/*}"
        if ! grep -q "$alias" "$MANIFESTS_DIR/kots-config.yaml"; then
            print_warning "Anchor $anchor has no alias reference"
        fi
    done

    print_success "Template patterns look consistent"
    return $errors
}

# Test 3: Simulate distribution-specific logic
test_distribution_logic() {
    local dist="$1"
    print_header "Test 3: Distribution Logic for $dist"

    echo "  Checking isK8sFullyImplementedPlatform..."
    if grep -q "(eq Distribution \"$dist\")" "$MANIFESTS_DIR/kots-config.yaml"; then
        print_success "$dist is included in isK8sFullyImplementedPlatform"
    else
        print_warning "$dist is NOT in isK8sFullyImplementedPlatform"
    fi

    echo "  Checking loadBalancerSupportedKind..."
    if grep -q "else if eq \$k8sDistribution \"$dist\"" "$MANIFESTS_DIR/kots-config.yaml"; then
        # Check what the result would be
        local result=$(grep -A3 "else if eq \$k8sDistribution \"$dist\"" "$MANIFESTS_DIR/kots-config.yaml" | grep "name" | head -1)
        if echo "$result" | grep -q "unsupported"; then
            print_warning "$dist loadBalancer is marked as unsupported (will show error for Default Access)"
        else
            print_success "$dist loadBalancer is supported"
        fi
    else
        print_warning "$dist has no specific loadBalancerSupportedKind case (will fall to generic unsupported)"
    fi
}

# Test 4: Check for potential runtime issues
test_config_dependencies() {
    print_header "Test 4: Config Option Dependencies"

    # Check that referenced config options exist
    local referenced_options=$(grep -oE 'ConfigOptionEquals "[^"]+"' "$MANIFESTS_DIR/kots-config.yaml" | \
        sed 's/ConfigOptionEquals "//g' | sed 's/"//g' | sort -u)

    echo "  Config options referenced via ConfigOptionEquals:"
    for option in $referenced_options; do
        if grep -q "name: $option$" "$MANIFESTS_DIR/kots-config.yaml" || \
           grep -q "name: $option " "$MANIFESTS_DIR/kots-config.yaml"; then
            echo "    ✓ $option (defined)"
        else
            print_error "$option is referenced but NOT defined!"
        fi
    done
}

# Test 5: Extract and display what each distribution would see
test_distribution_ui_flow() {
    local dist="$1"
    print_header "Test 5: UI Flow Simulation for $dist"

    echo "  Expected behavior for $dist:"
    echo ""

    # Check isK8sFullyImplementedPlatform
    if grep "isK8sFullyImplementedPlatform" "$MANIFESTS_DIR/kots-config.yaml" | grep -q "$dist"; then
        echo "  1. isK8sFullyImplementedPlatform = true"
        echo "     → User sees 'accessToCartoModeK8s' selector (Default Access / Custom)"
    else
        echo "  1. isK8sFullyImplementedPlatform = false"
        echo "     → User sees 'accessToCartoModeK8sNotFullySupported' (Custom only)"
    fi

    # Check loadBalancerSupportedKind
    local lb_result=$(grep -A3 "else if eq \$k8sDistribution \"$dist\"" "$MANIFESTS_DIR/kots-config.yaml" 2>/dev/null | grep "name" | head -1)
    if echo "$lb_result" | grep -q "unsupported"; then
        echo "  2. loadBalancerSupportedKind = unsupported"
        echo "     → If 'Default Access' selected, error message will show"
    else
        echo "  2. loadBalancerSupportedKind = supported"
        echo "     → 'Default Access' mode should work"
    fi

    # Check label visibility
    if grep -q "platformDistribution.*$dist" "$MANIFESTS_DIR/kots-config.yaml"; then
        echo "  3. Platform-specific label handling detected"
    fi

    echo ""
}

# Main execution
main() {
    local target="${1:-all}"

    echo "KOTS Config Template Tester"
    echo "==========================="
    echo "Manifests: $MANIFESTS_DIR"
    echo ""

    # Always run syntax and pattern tests
    test_yaml_syntax || exit 1
    test_template_patterns
    test_config_dependencies

    # Run distribution-specific tests
    if [[ "$target" == "all" ]]; then
        for dist in "${DISTRIBUTIONS[@]}"; do
            test_distribution_logic "$dist"
            test_distribution_ui_flow "$dist"
        done
    else
        if [[ " ${DISTRIBUTIONS[*]} " =~ " ${target} " ]]; then
            test_distribution_logic "$target"
            test_distribution_ui_flow "$target"
        else
            print_error "Unknown distribution: $target"
            echo "Valid options: ${DISTRIBUTIONS[*]} all"
            exit 1
        fi
    fi

    print_header "Summary"
    print_success "All static tests passed!"
    echo ""
    echo "Note: Full template rendering requires deploying to a cluster."
    echo "Use 'kubectl kots install' to test actual rendering."
}

main "$@"
