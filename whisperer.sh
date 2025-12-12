#!/bin/bash
# MLX Whisperer Control Script
# Manages the FastAPI server lifecycle

set -e

# Configuration
SERVER_PORT=9180
PID_FILE=".whisperer.pid"
LOG_FILE="whisperer.log"
VENV_PATH="venv"
SERVER_SCRIPT="whisper_server.py"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            # PID file exists but process is not running
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Check if port is in use
is_port_in_use() {
    if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Start the server
start_server() {
    print_header "Starting MLX Whisperer Server"
    
    # Check if already running
    if is_running; then
        PID=$(cat "$PID_FILE")
        print_warning "Server is already running (PID: $PID)"
        return 0
    fi
    
    # Check if port is in use
    if is_port_in_use; then
        print_error "Port $SERVER_PORT is already in use"
        print_info "Use 'lsof -i :$SERVER_PORT' to find the process"
        return 1
    fi
    
    # Check for virtual environment
    if [ ! -d "$VENV_PATH" ]; then
        print_error "Virtual environment not found. Run ./install.sh first"
        return 1
    fi
    
    # Check for server script
    if [ ! -f "$SERVER_SCRIPT" ]; then
        print_error "Server script '$SERVER_SCRIPT' not found"
        return 1
    fi
    
    # Start server in background
    print_info "Starting server on port $SERVER_PORT..."
    nohup "$VENV_PATH/bin/python3" "$SERVER_SCRIPT" >> "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    # Wait a moment and check if it started successfully
    sleep 2
    
    if is_running; then
        print_success "Server started successfully (PID: $PID)"
        print_info "Server URL: ${GREEN}http://localhost:$SERVER_PORT${NC}"
        print_info "Log file: $LOG_FILE"
        return 0
    else
        print_error "Server failed to start. Check $LOG_FILE for details"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Stop the server
stop_server() {
    print_header "Stopping MLX Whisperer Server"
    
    if ! is_running; then
        print_warning "Server is not running"
        return 0
    fi
    
    PID=$(cat "$PID_FILE")
    print_info "Stopping server (PID: $PID)..."
    
    # Send TERM signal for graceful shutdown
    kill -TERM "$PID" 2>/dev/null || true
    
    # Wait for process to stop (max 10 seconds)
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        print_warning "Graceful shutdown failed, forcing..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 1
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
    
    if ps -p "$PID" > /dev/null 2>&1; then
        print_error "Failed to stop server"
        return 1
    else
        print_success "Server stopped successfully"
        return 0
    fi
}

# Restart the server
restart_server() {
    print_header "Restarting MLX Whisperer Server"
    stop_server
    sleep 1
    start_server
}

# Show server status
show_status() {
    print_header "MLX Whisperer Server Status"
    
    if is_running; then
        PID=$(cat "$PID_FILE")
        print_success "Server is ${GREEN}RUNNING${NC}"
        echo ""
        echo "  PID:  $PID"
        echo "  Port: $SERVER_PORT"
        echo "  URL:  http://localhost:$SERVER_PORT"
        echo ""
        
        # Try to get health status
        print_info "Checking health endpoint..."
        if command -v curl &> /dev/null; then
            HEALTH=$(curl -s http://localhost:$SERVER_PORT/health 2>/dev/null || echo "")
            if [ -n "$HEALTH" ]; then
                echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
            else
                print_warning "Health check failed - server may be starting up"
            fi
        else
            print_warning "curl not found - cannot check health endpoint"
        fi
    else
        print_warning "Server is ${YELLOW}NOT RUNNING${NC}"
    fi
    
    echo ""
}

# Show recent logs
show_logs() {
    print_header "Recent Logs (last 50 lines)"
    
    if [ -f "$LOG_FILE" ]; then
        tail -n 50 "$LOG_FILE"
    else
        print_warning "Log file not found: $LOG_FILE"
    fi
}

# Test the API
test_api() {
    print_header "Testing MLX Whisperer API"
    
    if ! is_running; then
        print_error "Server is not running. Start it with: ./whisperer.sh start"
        return 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Cannot test API."
        return 1
    fi
    
    print_info "Testing health endpoint..."
    RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:$SERVER_PORT/health)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Health check passed"
        echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    else
        print_error "Health check failed (HTTP $HTTP_CODE)"
        echo "$BODY"
        return 1
    fi
    
    echo ""
    print_info "Testing root endpoint..."
    RESPONSE=$(curl -s http://localhost:$SERVER_PORT/)
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    
    echo ""
    print_success "API is responding correctly"
    print_info "For transcription examples, run: ./test_api.sh"
}

# Show usage
show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|test}"
    echo ""
    echo "Commands:"
    echo "  start    - Start the server in background"
    echo "  stop     - Stop the server gracefully"
    echo "  restart  - Restart the server"
    echo "  status   - Show server status and health"
    echo "  logs     - Display recent log output (last 50 lines)"
    echo "  test     - Test API health endpoint"
    echo ""
}

# Main command dispatcher
case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_api
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

exit 0
