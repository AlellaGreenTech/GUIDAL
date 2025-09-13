#!/usr/bin/env node

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = 8000;
const HOST = 'localhost';

// MIME types for different file extensions
const mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
    let filePath = '.' + req.url;
    if (filePath === './') {
        filePath = './index.html';
    }

    const extname = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                // File not found, try to serve index.html for SPA routing
                fs.readFile('./index.html', (err, indexContent) => {
                    if (err) {
                        res.writeHead(404, { 'Content-Type': 'text/html' });
                        res.end('<h1>404 - File Not Found</h1>', 'utf-8');
                    } else {
                        res.writeHead(200, { 'Content-Type': 'text/html' });
                        res.end(indexContent, 'utf-8');
                    }
                });
            } else {
                res.writeHead(500);
                res.end('Sorry, there was an error: ' + error.code + ' ..\n');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, HOST, () => {
    console.log(`🌱 GUIDAL GREENs System running at http://${HOST}:${PORT}/`);
    console.log('📄 Main pages:');
    console.log(`   • Home: http://${HOST}:${PORT}/index.html`);
    console.log(`   • Register: http://${HOST}:${PORT}/register.html`);
    console.log(`   • Login: http://${HOST}:${PORT}/login-greens.html`);
    console.log(`   • Dashboard: http://${HOST}:${PORT}/dashboard.html`);
    console.log(`   • Test: http://${HOST}:${PORT}/test-greens.html`);
    console.log('\n🔥 Server ready! Press Ctrl+C to stop');
    
    // Try to open browser automatically
    const start = process.platform === 'darwin' ? 'open' : 
                  process.platform === 'win32' ? 'start' : 'xdg-open';
    exec(`${start} http://${HOST}:${PORT}/index.html`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n👋 Shutting down GUIDAL server...');
    server.close(() => {
        console.log('✅ Server stopped');
        process.exit(0);
    });
});