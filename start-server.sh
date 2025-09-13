#!/bin/bash

# GUIDAL Development Server Launcher
# Quick launcher for the Python server

echo "🌱 GUIDAL Development Server"
echo "📍 Starting Python server on port 8080..."
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    echo "✅ Using Python 3"
    python3 server/server.py
elif command -v python &> /dev/null; then
    echo "✅ Using Python"
    python server/server.py
else
    echo "❌ Python is not installed!"
    echo "📥 Please install Python 3 from https://python.org"
    echo "🔄 Or try the simple server:"
    echo "   python3 -m http.server 8080"
    exit 1
fi