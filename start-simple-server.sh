#!/bin/bash

# GUIDAL Simple Server Launcher
# Uses Python's built-in HTTP server

echo "🌱 GUIDAL Simple Server"
echo "📍 Starting on port 8080..."
echo "🌐 Open: http://localhost:8080"
echo ""
echo "🛑 Press Ctrl+C to stop"
echo ""

# Start simple HTTP server
python3 -m http.server 8080