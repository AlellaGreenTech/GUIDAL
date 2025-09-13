# 🚀 GUIDAL Server Files

This directory contains all server-related files and configurations for the GUIDAL platform.

## 📁 Directory Structure

```
server/
├── README.md                    # This file
├── server.py                   # Python HTTP server (recommended)
├── server.js                   # Node.js HTTP server
├── package.json                # NPM configuration
├── start-server.sh             # Node.js server launcher
├── start-server-python.sh      # Python server launcher
├── config.template.js          # Configuration template
├── supabase-setup.md           # Supabase integration guide
└── SIMPLE-SERVER-INSTRUCTIONS.md  # Quick server setup guide
```

## 🎯 Quick Start Options

### Option 1: Python Server (Recommended)
```bash
# From project root
python3 server/server.py
```

### Option 2: Node.js Server
```bash
# From project root (requires Node.js)
node server/server.js
```

### Option 3: Simple Python HTTP Server
```bash
# From project root
python3 -m http.server 8080
```

## 🌐 Server URLs

All servers will serve the GUIDAL site at:
- **Main Site**: `http://localhost:8080/index.html`
- **GREENs Registration**: `http://localhost:8080/register.html`
- **GREENs Login**: `http://localhost:8080/login-greens.html`
- **Dashboard**: `http://localhost:8080/dashboard.html`
- **System Test**: `http://localhost:8080/test-greens.html`

## ⚙️ Server Features

### Python Server (`server.py`)
- ✅ **CORS Headers** - Enables API calls
- ✅ **Auto Browser Opening** - Launches your default browser
- ✅ **Proper MIME Types** - Serves all file types correctly
- ✅ **Error Handling** - Graceful error messages
- ✅ **Port 8080** - Consistent port usage

### Node.js Server (`server.js`)
- ✅ **SPA Support** - Single Page App routing
- ✅ **File Watching** - Live reload capability
- ✅ **Auto Browser Opening** - Launches your default browser
- ✅ **Graceful Shutdown** - Clean exit handling

## 🔧 Configuration

### Supabase Setup
1. Follow instructions in `supabase-setup.md`
2. Update `js/supabase-client.js` with your credentials

### Custom Configuration
1. Copy `config.template.js` to `config.js`
2. Update with your specific settings

## 📋 NPM Scripts

From the server directory:
```bash
npm start       # Start Node.js server
npm run dev     # Start with development settings
npm run test    # Start server and open test page
```

## 🚫 What NOT to Use

- **VS Code Live Server Extension** - Has port conflicts
- **Port 5500** - Avoid this port
- **Any server without CORS** - Will break API calls

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
lsof -i :8080

# Kill the process
kill [PID]
```

### Python Not Found
```bash
# Try different Python commands
python3 server/server.py
python server/server.py
py server/server.py
```

### Node.js Issues
```bash
# Install Node.js from nodejs.org
# Then try:
node server/server.js
```

## 🎯 Best Practices

1. **Use Python server** for simplicity
2. **Always run from project root** directory
3. **Use port 8080** for consistency
4. **Stop server with Ctrl+C** for clean shutdown
5. **Check browser console** for any errors

---

**For questions about server setup, see `SIMPLE-SERVER-INSTRUCTIONS.md` or the main project README.**