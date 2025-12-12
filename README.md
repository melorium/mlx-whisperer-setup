# 🎙️ MLX Whisperer

Complete OpenAI-compatible Whisper API server for Apple Silicon Macs, powered by MLX for blazing-fast GPU-accelerated transcription.

## ✨ Features

- 🚀 **OpenAI-Compatible API** - Drop-in replacement for OpenAI's Whisper API
- ⚡ **GPU Acceleration** - Automatic hardware acceleration via MLX on Apple Silicon
- 🎯 **Fast & Efficient** - Optimized for M1/M2/M3 chips
- 🌍 **Multi-language** - Supports 99+ languages with auto-detection
- 🔄 **Translation** - Transcribe or translate to English
- 📝 **Detailed Segments** - Get timestamped transcription segments
- 🛠️ **Easy Management** - Simple control scripts for server lifecycle
- 📊 **Comprehensive Logging** - Detailed logs for debugging
- 🔒 **Local Processing** - All transcription happens on your machine

## 📋 Requirements

- **Operating System**: macOS with Apple Silicon (M1, M2, M3, M3 Ultra)
- **Python**: 3.8 or higher
- **Storage**: ~2GB for model storage
- **Memory**: 8GB+ RAM recommended

## 🚀 Quick Start

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/melorium/mlx-whisperer-setup.git
cd mlx-whisperer-setup
```

2. **Run the installation script**
```bash
chmod +x install.sh
./install.sh
```

The installer will:
- ✓ Check Python version
- ✓ Create virtual environment
- ✓ Install all dependencies
- ✓ Make scripts executable
- ✓ Prepare the Whisper model (downloads on first use)

### Starting the Server

```bash
./whisperer.sh start
```

The server will start on `http://localhost:9180`

### Testing

```bash
# Check server status
./whisperer.sh status

# Run API tests
./whisperer.sh test

# See example usage
./test_api.sh
```

## 🎮 Control Commands

The `whisperer.sh` script provides complete server lifecycle management:

| Command | Description |
|---------|-------------|
| `./whisperer.sh start` | Start the server in background |
| `./whisperer.sh stop` | Stop the server gracefully |
| `./whisperer.sh restart` | Restart the server |
| `./whisperer.sh status` | Show server status and health |
| `./whisperer.sh logs` | Display recent logs (last 50 lines) |
| `./whisperer.sh test` | Test API health endpoint |

## 📡 API Usage

### Endpoints

- **POST** `/v1/audio/transcriptions` - Transcribe or translate audio
- **GET** `/health` - Health check endpoint
- **GET** `/` - API information

### Using cURL

**Basic transcription:**
```bash
curl -X POST "http://localhost:9180/v1/audio/transcriptions" \
  -F "file=@audio.mp3" \
  -F "language=en"
```

**Translate to English:**
```bash
curl -X POST "http://localhost:9180/v1/audio/transcriptions" \
  -F "file=@audio.wav" \
  -F "language=es" \
  -F "task=translate"
```

**Auto-detect language:**
```bash
curl -X POST "http://localhost:9180/v1/audio/transcriptions" \
  -F "file=@audio.m4a"
```

### Using Python

**Simple example:**
```python
import requests

url = "http://localhost:9180/v1/audio/transcriptions"

with open("audio.mp3", "rb") as f:
    files = {"file": f}
    data = {"language": "en", "task": "transcribe"}
    response = requests.post(url, files=files, data=data)

result = response.json()
print(result["text"])
```

**Complete example with error handling:**
```python
import requests

def transcribe_audio(audio_path, language="en", task="transcribe"):
    """
    Transcribe audio file using MLX Whisperer API
    
    Args:
        audio_path: Path to audio file
        language: Language code (e.g., "en", "es", "fr") or None for auto-detect
        task: "transcribe" or "translate"
    
    Returns:
        Dictionary with transcription results or None on error
    """
    url = "http://localhost:9180/v1/audio/transcriptions"
    
    try:
        with open(audio_path, "rb") as f:
            files = {"file": ("audio.mp3", f, "audio/mpeg")}
            data = {"language": language, "task": task}
            response = requests.post(url, files=files, data=data)
            response.raise_for_status()
            
        return response.json()
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None
    except FileNotFoundError:
        print(f"File not found: {audio_path}")
        return None

# Usage
result = transcribe_audio("meeting.mp3", language="en")
if result:
    print(f"Full Text: {result['text']}")
    print(f"\nLanguage: {result['language']}")
    print(f"\nSegments:")
    for seg in result['segments']:
        start = seg['start']
        end = seg['end']
        text = seg['text']
        print(f"[{start:.2f}s - {end:.2f}s]: {text}")
```

### Response Format

```json
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
```

## 🌍 Supported Languages

MLX Whisperer supports 99+ languages including:

| Language | Code | Language | Code | Language | Code |
|----------|------|----------|------|----------|------|
| English | en | Spanish | es | French | fr |
| German | de | Italian | it | Portuguese | pt |
| Russian | ru | Japanese | ja | Korean | ko |
| Chinese | zh | Arabic | ar | Hindi | hi |
| Dutch | nl | Polish | pl | Turkish | tr |
| Swedish | sv | Norwegian | no | Danish | da |

**Auto-detection**: Leave the `language` parameter empty for automatic language detection.

For the complete list, see [Whisper's language support](https://github.com/openai/whisper#available-models-and-languages).

## 🎵 Supported Audio Formats

- MP3 (`.mp3`)
- WAV (`.wav`)
- M4A (`.m4a`)
- FLAC (`.flac`)
- OGG (`.ogg`)
- OPUS (`.opus`)
- AAC (`.aac`)

Most common audio formats are supported. The model works best with:
- Sample rate: 16kHz (recommended, but any rate works)
- Channels: Mono (stereo is automatically converted)

## ⚙️ Configuration

### Default Settings

- **Port**: 9180
- **Model**: mlx-community/whisper-large-v3-turbo
- **Host**: 0.0.0.0 (listens on all interfaces)
- **Log File**: whisperer.log
- **PID File**: .whisperer.pid

### Environment Variables

You can customize the server by editing `whisper_server.py`:

```python
SERVER_PORT = 9180  # Change port
MODEL_NAME = "mlx-community/whisper-large-v3-turbo"  # Change model
```

## 🔧 Troubleshooting

### Server won't start

**Port already in use:**
```bash
# Check what's using port 9180
lsof -i :9180

# Kill the process if needed
kill -9 <PID>
```

**Virtual environment issues:**
```bash
# Remove and recreate
rm -rf venv
./install.sh
```

### Transcription errors

**Model not found:**
The model downloads automatically on first use (~1.55GB). Ensure you have:
- Stable internet connection
- Sufficient disk space (~2GB free)

**Poor transcription quality:**
- Use clear audio with minimal background noise
- Ensure audio is not corrupted
- Try specifying the language explicitly
- Use higher quality audio files (WAV/FLAC over MP3)

### Performance issues

**Slow transcription:**
- Ensure you're running on Apple Silicon (M1/M2/M3)
- Close other GPU-intensive applications
- First request is slower due to model loading

**Check logs:**
```bash
./whisperer.sh logs
```

## 📊 Performance Benchmarks

Typical performance on Apple Silicon:

| Device | First Request | Subsequent (per min audio) |
|--------|---------------|---------------------------|
| M1 | ~3-5s | ~1-2s |
| M2 | ~2-4s | ~0.7-1.5s |
| M3 Ultra | ~2-3s | ~0.5-1s |

**Note**: First request includes model loading time. Subsequent requests are much faster.

## 📁 Project Structure

```
mlx-whisperer-setup/
├── install.sh              # Installation script
├── whisperer.sh            # Server control script
├── test_api.sh             # API testing script
├── whisper_server.py       # FastAPI server
├── requirements.txt        # Python dependencies
├── .gitignore             # Git ignore rules
├── README.md              # This file
├── venv/                  # Virtual environment (created by install.sh)
├── .whisperer.pid         # Server PID file (runtime)
└── whisperer.log          # Server log file (runtime)
```

## 🔐 Security Notes

- The server listens on all interfaces (0.0.0.0) by default
- For production use, consider:
  - Running behind a reverse proxy (nginx, Apache)
  - Adding authentication
  - Restricting to localhost only (`host="127.0.0.1"`)
  - Using HTTPS with SSL certificates

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

MIT License

Copyright (c) 2024 MLX Whisperer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 🙏 Acknowledgments

- [MLX](https://github.com/ml-explore/mlx) - Apple's machine learning framework
- [mlx-whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) - MLX implementation of Whisper
- [OpenAI Whisper](https://github.com/openai/whisper) - Original Whisper model
- [FastAPI](https://fastapi.tiangolo.com/) - Modern web framework for APIs

## 📮 Support

- **Issues**: [GitHub Issues](https://github.com/melorium/mlx-whisperer-setup/issues)
- **Documentation**: This README
- **Examples**: See `test_api.sh` for more examples

---

Made with ❤️ for Apple Silicon • Powered by MLX 🚀
