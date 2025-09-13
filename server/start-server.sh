#!/bin/bash

# GUIDAL GREENs System - Development Server Launcher
# This script starts the local development server on port 8000

echo "🌱 Starting GUIDAL GREENs System Development Server..."
echo "🔧 Port: 8000"
echo "🌐 Host: localhost"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    echo "   Download from: https://nodejs.org/"
    read -p "Press any key to exit..."
    exit 1
fi

# Navigate to the script directory
cd "$(dirname "$0")"

echo "📁 Current directory: $(pwd)"
echo ""

# Start the server
echo "🚀 Starting server..."
node server.js

# Keep terminal open on exit
read -p "Press any key to exit..."