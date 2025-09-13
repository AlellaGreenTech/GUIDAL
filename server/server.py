#!/usr/bin/env python3

import http.server
import socketserver
import webbrowser
import os
import sys
from urllib.parse import urlparse

PORT = 8080
HOST = "localhost"

class GUIDALHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def do_GET(self):
        # Parse the URL
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Default to index.html if root is requested
        if path == '/':
            path = '/index.html'
        
        # Set the path for the file system
        self.path = path
        
        # Call the parent handler
        return super().do_GET()

def main():
    # Change to the project root directory (one level up from server/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    os.chdir(project_root)
    
    print(f"🌱 GUIDAL GREENs System Development Server")
    print(f"🔧 Starting server on http://{HOST}:{PORT}")
    print(f"📁 Serving files from: {project_root}")
    print("")
    print("📄 Available pages:")
    print(f"   • Home: http://{HOST}:{PORT}/index.html")
    print(f"   • Register: http://{HOST}:{PORT}/register.html")
    print(f"   • Login: http://{HOST}:{PORT}/login-greens.html")
    print(f"   • Dashboard: http://{HOST}:{PORT}/dashboard.html")
    print(f"   • Test: http://{HOST}:{PORT}/test-greens.html")
    print("")
    print("🔥 Server ready! Press Ctrl+C to stop")
    print("🌐 Opening browser...")
    
    try:
        # Create server
        with socketserver.TCPServer((HOST, PORT), GUIDALHandler) as httpd:
            # Open browser automatically
            webbrowser.open(f"http://{HOST}:{PORT}/index.html")
            
            # Start serving
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n👋 Shutting down GUIDAL server...")
        print("✅ Server stopped")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {PORT} is already in use!")
            print("💡 Try stopping other servers or use a different port")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()