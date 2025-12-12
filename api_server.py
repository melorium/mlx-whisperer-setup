#!/usr/bin/env python3
"""
MLX Whisperer API Server
FastAPI server for speech-to-text using MLX Whisper on Mac M3
"""

import os
import tempfile
from pathlib import Path
from typing import Optional, Dict, Any
import yaml

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import mlx_whisper

# Load configuration
CONFIG_PATH = Path(__file__).parent / "config.yaml"
with open(CONFIG_PATH, "r") as f:
    config = yaml.safe_load(f)

# Initialize FastAPI app
app = FastAPI(
    title="MLX Whisperer API",
    description="Speech-to-text API using MLX Whisper for Mac M3",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global model cache
_model_cache: Dict[str, Any] = {}


def get_model(model_name: str = "base"):
    """Load or retrieve cached Whisper model"""
    if model_name not in _model_cache:
        print(f"Loading Whisper model: {model_name}")
        # Model will be loaded by mlx_whisper.transcribe
        _model_cache[model_name] = True
    return model_name


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "service": "MLX Whisperer API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "/transcribe": "POST - Transcribe audio file to text",
            "/health": "GET - Health check",
            "/models": "GET - List available models"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": config["whisper"]["model"],
        "port": config["server"]["port"]
    }


@app.get("/models")
async def list_models():
    """List available Whisper models"""
    models = ["tiny", "base", "small", "medium", "large"]
    return {
        "available_models": models,
        "current_model": config["whisper"]["model"]
    }


@app.post("/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...),
    model: Optional[str] = Form(None),
    language: Optional[str] = Form(None),
    task: Optional[str] = Form("transcribe"),
    temperature: Optional[float] = Form(0.0)
):
    """
    Transcribe an audio file to text
    
    Args:
        file: Audio file (wav, mp3, m4a, flac, ogg)
        model: Whisper model size (tiny, base, small, medium, large)
        language: Language code (optional, auto-detect if not specified)
        task: 'transcribe' or 'translate' (translate to English)
        temperature: Sampling temperature (0.0 for deterministic)
    
    Returns:
        JSON with transcription text and metadata
    """
    # Validate file type
    file_ext = Path(file.filename).suffix.lower().lstrip(".")
    allowed_formats = config["audio"]["formats"]
    
    if file_ext not in allowed_formats:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file format. Allowed: {', '.join(allowed_formats)}"
        )
    
    # Check file size
    content = await file.read()
    file_size_mb = len(content) / (1024 * 1024)
    max_size_mb = config["audio"]["max_size_mb"]
    
    if file_size_mb > max_size_mb:
        raise HTTPException(
            status_code=400,
            detail=f"File too large ({file_size_mb:.1f}MB). Max size: {max_size_mb}MB"
        )
    
    # Use provided values or defaults from config
    model_name = model or config["whisper"]["model"]
    lang = language or config["whisper"]["language"]
    task_name = task or config["whisper"]["task"]
    temp = temperature if temperature is not None else config["whisper"]["temperature"]
    
    try:
        # Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=f".{file_ext}") as tmp_file:
            tmp_file.write(content)
            tmp_path = tmp_file.name
        
        # Transcribe using MLX Whisper
        print(f"Transcribing with model={model_name}, language={lang}, task={task_name}")
        
        # Prepare kwargs for transcription
        transcribe_kwargs = {
            "path_or_hf_repo": model_name,
            "verbose": False
        }
        
        if lang:
            transcribe_kwargs["language"] = lang
        if task_name:
            transcribe_kwargs["task"] = task_name
        if temp != 0.0:
            transcribe_kwargs["temperature"] = temp
        
        result = mlx_whisper.transcribe(
            tmp_path,
            **transcribe_kwargs
        )
        
        # Clean up temp file
        os.unlink(tmp_path)
        
        # Extract transcription text
        text = result.get("text", "").strip()
        
        return JSONResponse(content={
            "success": True,
            "text": text,
            "language": result.get("language"),
            "model": model_name,
            "task": task_name,
            "segments": result.get("segments", []),
            "metadata": {
                "filename": file.filename,
                "file_size_mb": round(file_size_mb, 2)
            }
        })
        
    except Exception as e:
        # Clean up temp file if it exists
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    
    host = config["server"]["host"]
    port = config["server"]["port"]
    reload = config["server"]["reload"]
    
    print(f"Starting MLX Whisperer API server on {host}:{port}")
    print(f"Model: {config['whisper']['model']}")
    print(f"Visit http://localhost:{port}/docs for API documentation")
    
    uvicorn.run(
        "api_server:app",
        host=host,
        port=port,
        reload=reload
    )
