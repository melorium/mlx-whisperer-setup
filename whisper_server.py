#!/usr/bin/env python3
"""
MLX Whisperer Server - OpenAI-compatible Whisper API using MLX
Port: 9180
Model: mlx-community/whisper-large-v3-turbo
"""

import os
import tempfile
import logging
from typing import Optional
from pathlib import Path

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('whisperer.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global model variable - lazy loading
whisper_model = None
MODEL_NAME = "mlx-community/whisper-large-v3-turbo"

app = FastAPI(
    title="MLX Whisperer API",
    description="OpenAI-compatible Whisper API using MLX for Apple Silicon",
    version="1.0.0"
)


def load_model():
    """Lazy load the Whisper model on first request"""
    global whisper_model
    if whisper_model is None:
        try:
            logger.info(f"Loading model: {MODEL_NAME}")
            import mlx_whisper
            whisper_model = MODEL_NAME
            logger.info("Model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")
    return whisper_model


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "service": "MLX Whisperer API",
        "version": "1.0.0",
        "model": MODEL_NAME,
        "port": 9180,
        "endpoints": {
            "transcribe": "POST /v1/audio/transcriptions",
            "health": "GET /health"
        },
        "status": "ready"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    model_loaded = whisper_model is not None
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "model_loaded": model_loaded,
        "port": 9180
    }


@app.post("/v1/audio/transcriptions")
async def transcribe_audio(
    file: UploadFile = File(...),
    language: Optional[str] = Form("en"),
    task: Optional[str] = Form("transcribe")
):
    """
    OpenAI-compatible audio transcription endpoint
    
    Args:
        file: Audio file to transcribe
        language: Language code (default: "en")
        task: Either "transcribe" or "translate" (default: "transcribe")
    
    Returns:
        JSON with transcription text, language, task, and segments
    """
    temp_file = None
    
    try:
        # Load model if not already loaded
        load_model()
        
        # Validate task
        if task not in ["transcribe", "translate"]:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid task '{task}'. Must be 'transcribe' or 'translate'"
            )
        
        # Log request
        logger.info(f"Transcription request: file={file.filename}, language={language}, task={task}")
        
        # Save uploaded file to temporary location
        suffix = Path(file.filename).suffix if file.filename else ".tmp"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_file = tmp.name
            content = await file.read()
            tmp.write(content)
            tmp.flush()
        
        logger.info(f"Processing audio file: {temp_file} ({len(content)} bytes)")
        
        # Transcribe using mlx-whisper
        import mlx_whisper
        
        # Prepare transcription options
        transcribe_options = {
            "language": language if language else None,
            "task": task
        }
        
        # Perform transcription
        result = mlx_whisper.transcribe(
            temp_file,
            path_or_hf_repo=MODEL_NAME,
            **transcribe_options
        )
        
        # Extract segments with detailed information
        segments = []
        if "segments" in result:
            for seg in result["segments"]:
                segments.append({
                    "id": seg.get("id", 0),
                    "start": seg.get("start", 0.0),
                    "end": seg.get("end", 0.0),
                    "text": seg.get("text", ""),
                })
        
        # Build response
        response = {
            "text": result.get("text", ""),
            "language": result.get("language", language),
            "task": task,
            "segments": segments
        }
        
        logger.info(f"Transcription completed: {len(response['text'])} characters")
        
        return JSONResponse(content=response)
        
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")
        
    finally:
        # Clean up temporary file
        if temp_file and os.path.exists(temp_file):
            try:
                os.unlink(temp_file)
                logger.debug(f"Cleaned up temporary file: {temp_file}")
            except Exception as e:
                logger.warning(f"Failed to delete temporary file {temp_file}: {e}")


if __name__ == "__main__":
    logger.info("Starting MLX Whisperer Server on port 9180")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=9180,
        log_level="info"
    )
