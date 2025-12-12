#!/usr/bin/env python3
"""
Example client for MLX Whisperer API
Demonstrates how to use the transcription API
"""

import requests
import json
import sys
from pathlib import Path


def transcribe_file(audio_path: str, 
                    model: str = "base",
                    language: str = None,
                    api_url: str = "http://localhost:9180"):
    """
    Transcribe an audio file using the MLX Whisperer API
    
    Args:
        audio_path: Path to the audio file
        model: Whisper model size (tiny, base, small, medium, large)
        language: Language code (e.g., 'en', 'es') or None for auto-detect
        api_url: Base URL of the API server
    
    Returns:
        Dictionary with transcription results
    """
    # Check if file exists
    audio_file = Path(audio_path)
    if not audio_file.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")
    
    # Prepare the request
    url = f"{api_url}/transcribe"
    data = {"model": model}
    
    if language:
        data["language"] = language
    
    # Send request
    print(f"Transcribing {audio_file.name} with model '{model}'...")
    with open(audio_path, "rb") as f:
        files = {"file": f}
        response = requests.post(url, files=files, data=data)
    
    # Check response
    if response.status_code == 200:
        result = response.json()
        return result
    else:
        raise Exception(f"API request failed: {response.status_code} - {response.text}")


def main():
    """Main function demonstrating API usage"""
    
    # Check if audio file is provided
    if len(sys.argv) < 2:
        print("Usage: python example_client.py <audio_file> [model] [language]")
        print("\nExample:")
        print("  python example_client.py audio.mp3")
        print("  python example_client.py audio.mp3 small en")
        sys.exit(1)
    
    audio_path = sys.argv[1]
    model = sys.argv[2] if len(sys.argv) > 2 else "base"
    language = sys.argv[3] if len(sys.argv) > 3 else None
    
    try:
        # First, check if the API is running
        health_response = requests.get("http://localhost:9180/health")
        if health_response.status_code != 200:
            print("Error: API server is not responding")
            print("Please start the server with: ./start_server.sh")
            sys.exit(1)
        
        # Transcribe the file
        result = transcribe_file(audio_path, model=model, language=language)
        
        # Display results
        print("\n" + "="*60)
        print("TRANSCRIPTION RESULT")
        print("="*60)
        print(f"\nText: {result['text']}")
        print(f"\nLanguage: {result.get('language', 'N/A')}")
        print(f"Model: {result['model']}")
        print(f"File: {result['metadata']['filename']}")
        print(f"Size: {result['metadata']['file_size_mb']} MB")
        
        # Display segments if available
        if result.get('segments'):
            print(f"\nSegments: {len(result['segments'])}")
            print("\nDetailed Segments:")
            for i, segment in enumerate(result['segments'], 1):
                start = segment.get('start', 0)
                end = segment.get('end', 0)
                text = segment.get('text', '').strip()
                print(f"  [{i}] {start:.1f}s - {end:.1f}s: {text}")
        
        print("\n" + "="*60)
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except requests.exceptions.ConnectionError:
        print("Error: Cannot connect to API server")
        print("Please start the server with: ./start_server.sh")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
