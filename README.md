# MLX Whisperer Setup for Mac M3

Complete speech-to-text API server using MLX Whisper optimized for Apple Silicon (M1/M2/M3). This setup provides a FastAPI-based REST API server running on port 9180 for transcribing audio files using Apple's MLX framework.

## Features

- 🚀 **Fast transcription** using MLX optimized for Apple Silicon
- 🎯 **REST API** with FastAPI on port 9180
- 🎤 **Multiple audio formats** supported (WAV, MP3, M4A, FLAC, OGG)
- 🌍 **Multi-language support** with automatic language detection
- 📝 **Configurable** via YAML configuration file
- 🔄 **Multiple model sizes** (tiny, base, small, medium, large)
- 📚 **Interactive API documentation** via Swagger UI

## Prerequisites

- **macOS** (optimized for Apple Silicon M1/M2/M3)
- **Python 3.9** or later
- **8GB RAM minimum** (16GB+ recommended for larger models)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/melorium/mlx-whisperer-setup.git
cd mlx-whisperer-setup
```

### 2. Run installation

```bash
./install.sh
```

This will:
- Create a Python virtual environment
- Install all required dependencies
- Set up MLX Whisper

### 3. Start the API server

```bash
./start_server.sh
```

The API server will start on `http://localhost:9180`

### 4. Access the API

- **API Documentation**: http://localhost:9180/docs
- **Health Check**: http://localhost:9180/health
- **Root Endpoint**: http://localhost:9180/

## API Usage

### Transcribe Audio File

**Endpoint**: `POST /transcribe`

**Parameters**:
- `file`: Audio file (multipart/form-data) - Required
- `model`: Whisper model size (tiny/base/small/medium/large) - Optional
- `language`: Language code (e.g., "en", "es", "fr") - Optional (auto-detect if not specified)
- `task`: "transcribe" or "translate" - Optional (default: "transcribe")
- `temperature`: Sampling temperature (0.0-1.0) - Optional (default: 0.0)

**Example using cURL**:

```bash
curl -X POST "http://localhost:9180/transcribe" \
  -F "file=@/path/to/audio.mp3" \
  -F "model=base" \
  -F "language=en"
```

**Example using Python**:

```python
import requests

url = "http://localhost:9180/transcribe"
files = {"file": open("audio.mp3", "rb")}
data = {"model": "base", "language": "en"}

response = requests.post(url, files=files, data=data)
result = response.json()
print(result["text"])
```

**Example Response**:

```json
{
  "success": true,
  "text": "This is the transcribed text from the audio file.",
  "language": "en",
  "model": "base",
  "task": "transcribe",
  "segments": [
    {
      "start": 0.0,
      "end": 3.5,
      "text": "This is the transcribed text from the audio file."
    }
  ],
  "metadata": {
    "filename": "audio.mp3",
    "file_size_mb": 1.2
  }
}
```

### Health Check

**Endpoint**: `GET /health`

```bash
curl http://localhost:9180/health
```

### List Available Models

**Endpoint**: `GET /models`

```bash
curl http://localhost:9180/models
```

## Configuration

Edit `config.yaml` to customize settings:

```yaml
server:
  host: "0.0.0.0"
  port: 9180
  reload: false

whisper:
  model: "base"          # Model size: tiny, base, small, medium, large
  language: null         # Language code or null for auto-detect
  task: "transcribe"     # Task: transcribe or translate
  temperature: 0.0       # Temperature for sampling
  condition_on_previous_text: true

audio:
  formats:               # Supported audio formats
    - "wav"
    - "mp3"
    - "m4a"
    - "flac"
    - "ogg"
  max_size_mb: 25       # Maximum file size in MB
```

## Model Sizes

| Model  | Parameters | VRAM Required | Speed     | Accuracy |
|--------|-----------|---------------|-----------|----------|
| tiny   | 39M       | ~1 GB         | ~32x      | Good     |
| base   | 74M       | ~1 GB         | ~16x      | Better   |
| small  | 244M      | ~2 GB         | ~6x       | Great    |
| medium | 769M      | ~5 GB         | ~2x       | Excellent|
| large  | 1550M     | ~10 GB        | ~1x       | Best     |

**Note**: On first run with a model, it will be downloaded automatically.

## Supported Audio Formats

- WAV (`.wav`)
- MP3 (`.mp3`)
- M4A (`.m4a`)
- FLAC (`.flac`)
- OGG (`.ogg`)

## Advanced Usage

### Running in Production

For production deployment, consider:

1. **Use a reverse proxy** (nginx/Apache) in front of the API
2. **Enable HTTPS** for secure communication
3. **Set up authentication** for API endpoints
4. **Use a process manager** like systemd or supervisord
5. **Configure logging** for monitoring

### Custom Port

To use a different port, edit `config.yaml`:

```yaml
server:
  port: 8080  # Your custom port
```

### Using Different Models

Change the model in `config.yaml` or specify it per request:

```bash
curl -X POST "http://localhost:9180/transcribe" \
  -F "file=@audio.mp3" \
  -F "model=small"
```

## Troubleshooting

### Installation Issues

**Problem**: `mlx` or `mlx-whisper` installation fails

**Solution**: Ensure you're on macOS with Apple Silicon and Python 3.9+. MLX is specifically designed for Apple Silicon Macs.

### Server Won't Start

**Problem**: Port 9180 is already in use

**Solution**: Either stop the process using that port or change the port in `config.yaml`.

```bash
# Find process using port 9180
lsof -i :9180

# Kill the process
kill -9 <PID>
```

### Transcription Fails

**Problem**: "Out of memory" or slow transcription

**Solution**: Use a smaller model (e.g., "tiny" or "base") in `config.yaml`.

### Audio Format Not Supported

**Problem**: "Unsupported file format" error

**Solution**: Convert your audio file to a supported format (WAV, MP3, M4A, FLAC, or OGG).

## Development

### Project Structure

```
mlx-whisperer-setup/
├── api_server.py       # FastAPI server implementation
├── config.yaml         # Configuration file
├── requirements.txt    # Python dependencies
├── install.sh         # Installation script
├── start_server.sh    # Server startup script
└── README.md          # This file
```

### Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Test the health endpoint
curl http://localhost:9180/health

# Test transcription with a sample audio file
curl -X POST "http://localhost:9180/transcribe" \
  -F "file=@test_audio.mp3"
```

## License

This project is provided as-is for setting up MLX Whisper on Mac M3.

## Acknowledgments

- [MLX Whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) - Apple's MLX implementation of Whisper
- [OpenAI Whisper](https://github.com/openai/whisper) - Original Whisper model
- [FastAPI](https://fastapi.tiangolo.com/) - Modern Python web framework

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Open an issue on GitHub
3. Consult the MLX Whisper documentation

---

**Note**: This setup is optimized for Apple Silicon Macs (M1/M2/M3). Performance on Intel Macs may vary.
