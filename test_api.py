#!/usr/bin/env python3
"""
Test script for MLX Whisperer API
Validates API endpoints and functionality
"""

import requests
import json
import sys


def test_health():
    """Test the health check endpoint"""
    print("Testing /health endpoint...")
    try:
        response = requests.get("http://localhost:9180/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Health check passed: {data}")
            return True
        else:
            print(f"✗ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Health check error: {e}")
        return False


def test_root():
    """Test the root endpoint"""
    print("\nTesting / endpoint...")
    try:
        response = requests.get("http://localhost:9180/", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Root endpoint passed")
            print(f"  Service: {data.get('service')}")
            print(f"  Version: {data.get('version')}")
            return True
        else:
            print(f"✗ Root endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Root endpoint error: {e}")
        return False


def test_models():
    """Test the models endpoint"""
    print("\nTesting /models endpoint...")
    try:
        response = requests.get("http://localhost:9180/models", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Models endpoint passed")
            print(f"  Available models: {', '.join(data.get('available_models', []))}")
            print(f"  Current model: {data.get('current_model')}")
            return True
        else:
            print(f"✗ Models endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Models endpoint error: {e}")
        return False


def test_api_docs():
    """Test that API documentation is accessible"""
    print("\nTesting /docs endpoint...")
    try:
        response = requests.get("http://localhost:9180/docs", timeout=5)
        if response.status_code == 200:
            print("✓ API documentation is accessible")
            return True
        else:
            print(f"✗ API documentation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ API documentation error: {e}")
        return False


def main():
    """Run all tests"""
    print("="*60)
    print("MLX Whisperer API Test Suite")
    print("="*60)
    print()
    
    # Check if server is running
    try:
        requests.get("http://localhost:9180/", timeout=2)
    except Exception:
        print("✗ ERROR: API server is not running!")
        print("\nPlease start the server first:")
        print("  ./start_server.sh")
        sys.exit(1)
    
    # Run tests
    results = []
    results.append(("Health Check", test_health()))
    results.append(("Root Endpoint", test_root()))
    results.append(("Models Endpoint", test_models()))
    results.append(("API Documentation", test_api_docs()))
    
    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n✓ All tests passed!")
        sys.exit(0)
    else:
        print(f"\n✗ {total - passed} test(s) failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
