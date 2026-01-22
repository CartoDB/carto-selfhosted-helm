#!/bin/bash
# CARTO Selfhosted Helm Diagram Generator
#
# Generates architecture diagrams in multiple formats:
#   1. D2 - Modern diagram language with ELK layout
#   2. Mingrammer - Python diagrams library
#   3. KubeDiagrams - Automatic Helm chart parsing (optional)
#
# Usage:
#   ./generate.sh --install     # Install dependencies
#   ./generate.sh               # Generate all diagrams
#   ./generate.sh d2            # D2 only
#   ./generate.sh python        # Python/Mingrammer only
#   ./generate.sh kubediagrams  # KubeDiagrams only

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

echo -e "${GREEN}=== CARTO Selfhosted Diagram Generator ===${NC}"
echo ""

show_help() {
    echo "Usage: ./generate.sh [command]"
    echo ""
    echo "Commands:"
    echo "  --install       Install all dependencies (D2, Graphviz, Python packages)"
    echo "  all             Generate all diagrams (default)"
    echo "  d2              Generate D2 diagram only"
    echo "  python          Generate Python/Mingrammer diagram only"
    echo "  kubediagrams    Generate using KubeDiagrams (parses Helm chart)"
    echo "  help            Show this help"
    echo ""
    echo "Output:"
    echo "  output/carto_selfhosted_d2.png       - D2 rendered diagram"
    echo "  output/carto_selfhosted_diagrams.png - Mingrammer rendered diagram"
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
        fi
    else
        echo "Graphviz already installed: $(dot -V 2>&1 | head -1)"
    fi

    # Check for D2
    if ! command -v d2 &> /dev/null; then
        echo -e "${YELLOW}Installing D2...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install d2
        else
            curl -fsSL https://d2lang.com/install.sh | sh -s --
        fi
    else
        echo "D2 already installed: $(d2 --version)"
    fi

    # Install Python dependencies
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip3 install -r requirements.txt

    echo -e "${GREEN}Dependencies installed!${NC}"
}

check_deps() {
    local missing=0

    if ! command -v dot &> /dev/null; then
        echo -e "${RED}Missing: Graphviz (dot command)${NC}"
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

    echo -e "${GREEN}Core dependencies OK${NC}"

    # D2 is optional
    if ! command -v d2 &> /dev/null; then
        echo -e "${YELLOW}Note: D2 not installed (optional for D2 diagrams)${NC}"
    fi
}

generate_d2() {
    echo -e "${BLUE}=== Generating D2 Diagram ===${NC}"

    if ! command -v d2 &> /dev/null; then
        echo -e "${YELLOW}D2 not installed. Run: ./generate.sh --install${NC}"
        return 1
    fi

    mkdir -p output

    echo "Rendering D2 diagram with ELK layout..."
    d2 --layout=elk --pad=60 d2/carto_selfhosted.d2 output/carto_selfhosted_d2.png

    echo -e "${GREEN}Generated: output/carto_selfhosted_d2.png${NC}"
}

generate_python() {
    echo -e "${BLUE}=== Generating Python/Mingrammer Diagram ===${NC}"

    mkdir -p output

    echo "Rendering Mingrammer diagram..."
    python3 carto_selfhosted.py

    echo -e "${GREEN}Generated: output/carto_selfhosted_diagrams.png${NC}"
}

generate_kubediagrams() {
    echo -e "${BLUE}=== KubeDiagrams ===${NC}"
    echo "Parsing Helm chart at: $CHART_DIR"

    if ! python3 -c "import kubediagrams" 2>/dev/null; then
        echo -e "${RED}KubeDiagrams not installed. Installing...${NC}"
        pip3 install kubediagrams
    fi

    mkdir -p output

    if command -v helm-diagrams &> /dev/null; then
        echo "Running helm-diagrams..."
        helm-diagrams --helm "$CHART_DIR" --output output/carto_selfhosted_kubediagrams.png
    else
        echo "Running via Python module..."
        python3 -m kubediagrams.helm_diagrams --helm "$CHART_DIR" --output output/carto_selfhosted_kubediagrams.png
    fi

    echo -e "${GREEN}Generated: output/carto_selfhosted_kubediagrams.png${NC}"
}

show_results() {
    echo ""
    echo -e "${GREEN}Generated diagrams:${NC}"
    ls -la output/*.png 2>/dev/null || echo "No PNG files found in output/"

    # Open on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && ls output/*.png &>/dev/null; then
        echo ""
        read -p "Open diagrams? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open output/*.png
        fi
    fi
}

# Main
case "${1:-all}" in
    --install)
        install_deps
        ;;
    d2)
        check_deps
        generate_d2
        show_results
        ;;
    python|mingrammer)
        check_deps
        generate_python
        show_results
        ;;
    kubediagrams)
        check_deps
        generate_kubediagrams
        show_results
        ;;
    all)
        check_deps
        generate_python
        if command -v d2 &> /dev/null; then
            generate_d2
        else
            echo -e "${YELLOW}Skipping D2 (not installed)${NC}"
        fi
        show_results
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
echo -e "${GREEN}Done!${NC}"
