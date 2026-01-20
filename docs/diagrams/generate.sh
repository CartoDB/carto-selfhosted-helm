#!/bin/bash
# Local diagram generation script for CARTO Selfhosted Helm
#
# Supports two methods:
#   1. KubeDiagrams - Automatic parsing of Helm chart (recommended)
#   2. Mingrammer - Manual Python diagram script
#
# Usage:
#   ./generate.sh --install        # Install dependencies
#   ./generate.sh kubediagrams     # Generate using KubeDiagrams
#   ./generate.sh mingrammer       # Generate using Mingrammer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$SCRIPT_DIR/../../chart"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== CARTO Selfhosted Helm Diagram Generator ===${NC}"
echo ""

show_help() {
    echo "Usage: ./generate.sh [command]"
    echo ""
    echo "Commands:"
    echo "  --install       Install all dependencies"
    echo "  kubediagrams    Generate diagram using KubeDiagrams (parses Helm chart)"
    echo "  mingrammer      Generate diagram using Mingrammer (manual Python script)"
    echo "  all             Generate using both methods"
    echo "  help            Show this help"
    echo ""
}

install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"

    # Check for Graphviz
    if ! command -v dot &> /dev/null; then
        echo -e "${YELLOW}Installing Graphviz...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install graphviz
        elif [[ -f /etc/debian_version ]]; then
            sudo apt-get update && sudo apt-get install -y graphviz
        else
            echo -e "${RED}Please install Graphviz manually${NC}"
            exit 1
        fi
    else
        echo "Graphviz already installed"
    fi

    # Install Python dependencies
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip3 install -r requirements.txt

    echo -e "${GREEN}Dependencies installed!${NC}"
}

check_deps() {
    local missing=0

    if ! command -v dot &> /dev/null; then
        echo -e "${RED}Missing: Graphviz${NC}"
        missing=1
    fi

    if ! python3 -c "import diagrams" 2>/dev/null; then
        echo -e "${RED}Missing: diagrams library${NC}"
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        echo -e "${YELLOW}Run: ./generate.sh --install${NC}"
        exit 1
    fi

    echo -e "${GREEN}Dependencies OK${NC}"
}

generate_kubediagrams() {
    echo -e "${BLUE}=== KubeDiagrams ===${NC}"
    echo "Parsing Helm chart at: $CHART_DIR"

    if ! python3 -c "import kubediagrams" 2>/dev/null; then
        echo -e "${RED}KubeDiagrams not installed. Installing...${NC}"
        pip3 install kubediagrams
    fi

    # Generate using helm-diagrams CLI
    if command -v helm-diagrams &> /dev/null; then
        echo "Running helm-diagrams..."
        helm-diagrams --helm "$CHART_DIR" --output carto_selfhosted_kubediagrams.png
    else
        echo "Running via Python module..."
        python3 -m kubediagrams.helm_diagrams --helm "$CHART_DIR" --output carto_selfhosted_kubediagrams.png
    fi

    echo -e "${GREEN}Created: carto_selfhosted_kubediagrams.png${NC}"
}

generate_mingrammer() {
    echo -e "${BLUE}=== Mingrammer ===${NC}"
    echo "Running Python script..."

    python3 generate_architecture.py

    echo -e "${GREEN}Created: carto_selfhosted.png${NC}"
}

# Main
case "${1:-help}" in
    --install)
        install_deps
        ;;
    kubediagrams)
        check_deps
        generate_kubediagrams
        ;;
    mingrammer)
        check_deps
        generate_mingrammer
        ;;
    all)
        check_deps
        generate_kubediagrams
        echo ""
        generate_mingrammer
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Generated files:${NC}"
ls -la *.png 2>/dev/null || echo "No PNG files found"

# Open on macOS
if [[ "$OSTYPE" == "darwin"* ]] && ls *.png &>/dev/null; then
    echo ""
    read -p "Open diagrams? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open *.png
    fi
fi
