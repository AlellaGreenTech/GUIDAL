#!/bin/bash

# GUIDAL GREENs System - Python Development Server
echo "🌱 Starting GUIDAL GREENs System on PORT 8000"
echo "🐍 Using Python HTTP Server"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    echo "✅ Using Python 3"
    python3 server.py
elif command -v python &> /dev/null; then
    echo "✅ Using Python"
    python server.py
else
    echo "❌ Python is not installed!"
    echo "Please install Python 3 to run the development server."
    exit 1
fi