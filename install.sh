#!/bin/bash
# MLX Whisperer Installation Script
# Installs dependencies and downloads the Whisper model

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_warning "This script is designed for macOS. It may not work correctly on other systems."
fi

print_header "MLX Whisperer Installation"

# Check for Python 3.8+
print_info "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info[0])')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info[1])')

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    print_error "Python 3.8+ is required. Found: Python $PYTHON_VERSION"
    exit 1
fi

print_success "Python $PYTHON_VERSION found"

# Create virtual environment
print_info "Creating virtual environment..."
if [ -d "venv" ]; then
    print_warning "Virtual environment already exists. Skipping creation."
else
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1
print_success "pip upgraded"

# Install requirements
print_info "Installing Python packages..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    print_success "Python packages installed"
else
    print_error "requirements.txt not found"
    exit 1
fi

# Download model (this happens automatically on first use, but we can trigger it)
print_info "Preparing Whisper model..."
print_warning "Model 'mlx-community/whisper-large-v3-turbo' (~1.55GB) will be downloaded on first use"
print_info "Testing model availability..."

# Test if mlx_whisper can be imported
python3 << 'EOF'
try:
    import mlx_whisper
    print("✓ mlx-whisper package is ready")
except ImportError as e:
    print(f"✗ Failed to import mlx_whisper: {e}")
    exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "MLX Whisper is ready"
else
    print_error "Failed to verify MLX Whisper installation"
    exit 1
fi

# Make control scripts executable
print_info "Making scripts executable..."
chmod +x whisperer.sh 2>/dev/null || true
chmod +x test_api.sh 2>/dev/null || true
print_success "Scripts are executable"

# Installation complete
print_header "Installation Complete!"

echo ""
print_success "MLX Whisperer is ready to use"
echo ""
print_info "Quick Start:"
echo "  1. Start the server:  ${GREEN}./whisperer.sh start${NC}"
echo "  2. Check status:      ${GREEN}./whisperer.sh status${NC}"
echo "  3. Test API:          ${GREEN}./whisperer.sh test${NC}"
echo "  4. View logs:         ${GREEN}./whisperer.sh logs${NC}"
echo "  5. Stop server:       ${GREEN}./whisperer.sh stop${NC}"
echo ""
print_info "Server will run on: ${GREEN}http://localhost:9180${NC}"
echo ""
print_warning "Note: Model will be downloaded (~1.55GB) on first transcription request"
echo ""
