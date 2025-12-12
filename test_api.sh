#!/bin/bash
# MLX Whisperer API Testing Script
# Provides examples and tests for the API

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SERVER_URL="http://localhost:9180"

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}$(printf '─%.0s' {1..50})${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_code() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if server is running
check_server() {
    if ! curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
        print_error "Server is not running at $SERVER_URL"
        echo ""
        print_info "Start the server with: ${GREEN}./whisperer.sh start${NC}"
        exit 1
    fi
}

print_header "MLX Whisperer API Testing & Examples"

check_server

# Test Health Endpoint
print_section "1. Health Check"
print_info "Testing: GET $SERVER_URL/health"
echo ""
HEALTH_RESPONSE=$(curl -s "$SERVER_URL/health")
echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
print_success "Health check passed"

# Test Root Endpoint
print_section "2. API Information"
print_info "Testing: GET $SERVER_URL/"
echo ""
ROOT_RESPONSE=$(curl -s "$SERVER_URL/")
echo "$ROOT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ROOT_RESPONSE"
print_success "API info retrieved"

# Curl Examples
print_section "3. Transcription Examples - cURL"

echo ""
echo -e "${MAGENTA}Example 1: Basic Transcription${NC}"
echo ""
print_code "curl -X POST \"$SERVER_URL/v1/audio/transcriptions\" \\"
print_code "  -F \"file=@/path/to/audio.mp3\" \\"
print_code "  -F \"language=en\""
echo ""

echo -e "${MAGENTA}Example 2: Transcribe and Translate to English${NC}"
echo ""
print_code "curl -X POST \"$SERVER_URL/v1/audio/transcriptions\" \\"
print_code "  -F \"file=@/path/to/audio.wav\" \\"
print_code "  -F \"language=es\" \\"
print_code "  -F \"task=translate\""
echo ""

echo -e "${MAGENTA}Example 3: Auto-detect Language${NC}"
echo ""
print_code "curl -X POST \"$SERVER_URL/v1/audio/transcriptions\" \\"
print_code "  -F \"file=@/path/to/audio.m4a\""
echo ""

# Python Examples
print_section "4. Transcription Examples - Python"

echo ""
echo -e "${MAGENTA}Example 1: Basic Usage${NC}"
echo ""
cat << 'EOF'
import requests

url = "http://localhost:9180/v1/audio/transcriptions"

with open("audio.mp3", "rb") as f:
    files = {"file": f}
    data = {"language": "en", "task": "transcribe"}
    response = requests.post(url, files=files, data=data)

result = response.json()
print(result["text"])
EOF

echo ""
echo -e "${MAGENTA}Example 2: With Error Handling${NC}"
echo ""
cat << 'EOF'
import requests

def transcribe_audio(audio_path, language="en", task="transcribe"):
    url = "http://localhost:9180/v1/audio/transcriptions"
    
    try:
        with open(audio_path, "rb") as f:
            files = {"file": ("audio.mp3", f, "audio/mpeg")}
            data = {"language": language, "task": task}
            response = requests.post(url, files=files, data=data)
            response.raise_for_status()
            
        result = response.json()
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Usage
result = transcribe_audio("audio.mp3", language="en")
if result:
    print(f"Text: {result['text']}")
    print(f"Language: {result['language']}")
    for seg in result['segments']:
        print(f"[{seg['start']:.2f}s - {seg['end']:.2f}s]: {seg['text']}")
EOF

# Supported Formats
print_section "5. Supported Audio Formats"
echo ""
echo "  • MP3  (.mp3)"
echo "  • WAV  (.wav)"
echo "  • M4A  (.m4a)"
echo "  • FLAC (.flac)"
echo "  • OGG  (.ogg)"
echo "  • OPUS (.opus)"
echo ""
print_info "Most common audio formats are supported"

# Supported Languages
print_section "6. Supported Languages (partial list)"
echo ""
echo "  • en - English          • es - Spanish         • fr - French"
echo "  • de - German           • it - Italian         • pt - Portuguese"
echo "  • ru - Russian          • ja - Japanese        • ko - Korean"
echo "  • zh - Chinese          • ar - Arabic          • hi - Hindi"
echo "  • nl - Dutch            • pl - Polish          • tr - Turkish"
echo "  • sv - Swedish          • no - Norwegian       • da - Danish"
echo ""
print_info "Leave empty for automatic language detection"
print_info "For full list: https://github.com/openai/whisper#available-models-and-languages"

# API Response Format
print_section "7. API Response Format"
echo ""
cat << 'EOF'
{
  "text": "Full transcription text here",
  "language": "en",
  "task": "transcribe",
  "segments": [
    {
      "id": 0,
      "start": 0.0,
      "end": 5.5,
      "text": "First segment text"
    },
    {
      "id": 1,
      "start": 5.5,
      "end": 10.2,
      "text": "Second segment text"
    }
  ]
}
EOF

# Tips
print_section "8. Tips & Best Practices"
echo ""
echo "  ${GREEN}✓${NC} Use clear audio with minimal background noise"
echo "  ${GREEN}✓${NC} Supported sample rates: 16kHz recommended, but any rate works"
echo "  ${GREEN}✓${NC} For best results, use mono audio"
echo "  ${GREEN}✓${NC} Specify language when known for faster processing"
echo "  ${GREEN}✓${NC} Use 'translate' task to translate any language to English"
echo "  ${GREEN}✓${NC} Model runs on Apple Silicon GPU automatically via MLX"
echo ""

# Performance Info
print_section "9. Performance Notes"
echo ""
echo "  Model: mlx-community/whisper-large-v3-turbo"
echo "  Size:  ~1.55GB"
echo ""
print_info "On Apple Silicon (M1/M2/M3):"
echo "  • First request: ~2-5s (model loading)"
echo "  • Subsequent: ~0.5-2s per minute of audio"
echo "  • GPU acceleration automatic via MLX"
echo ""

print_header "Testing Complete!"
echo ""
print_success "API is ready to use at: ${GREEN}$SERVER_URL${NC}"
echo ""
print_info "For more commands: ${GREEN}./whisperer.sh --help${NC}"
echo ""
