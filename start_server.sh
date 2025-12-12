#!/bin/bash
# Startup script for MLX Whisperer API server

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Starting MLX Whisperer API Server${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${RED}Error: Virtual environment not found.${NC}"
    echo "Please run ./install.sh first."
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Check if required packages are installed
if ! python3 -c "import mlx_whisper" 2>/dev/null; then
    echo -e "${RED}Error: mlx_whisper is not installed.${NC}"
    echo "Please run ./install.sh first."
    exit 1
fi

# Check if config file exists
if [ ! -f "config.yaml" ]; then
    echo -e "${RED}Error: config.yaml not found.${NC}"
    exit 1
fi

# Start the server
echo ""
echo -e "${GREEN}Starting API server on port 9180...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""
echo "API Documentation: http://localhost:9180/docs"
echo "Health Check: http://localhost:9180/health"
echo ""

python3 api_server.py
