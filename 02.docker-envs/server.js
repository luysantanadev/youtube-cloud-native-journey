'use strict'

const http = require('node:http')
const fs   = require('node:fs/promises')
const path = require('node:path')
const os   = require('node:os')

// ---------------------------------------------------------------------------
// Read environment variables.
// Default values make the container work out-of-the-box without any -e flag,
// and also serve as live documentation of what each variable controls.
// ---------------------------------------------------------------------------
const PORT        = process.env.PORT        || '3000'
const APP_NAME    = process.env.APP_NAME    || 'workshop-app'
const APP_ENV     = process.env.APP_ENV     || 'development'
const APP_MESSAGE = process.env.APP_MESSAGE || 'Olá do container!'
const DB_HOST     = process.env.DB_HOST     || '(não definido)'
const DB_USER     = process.env.DB_USER     || '(não definido)'

// Mask DB_PASS so the value is never echoed in responses, demonstrating that
// secrets should be injected at runtime but never returned to the browser.
const DB_PASS = process.env.DB_PASS ? '***' : '(não definido)'

// ---------------------------------------------------------------------------
// Static file map — maps URL paths to local files and their content types.
// ---------------------------------------------------------------------------
const STATIC_FILES = {
  '/':          { file: 'index.html', type: 'text/html; charset=utf-8' },
  '/style.css': { file: 'style.css',  type: 'text/css; charset=utf-8' },
  '/client.js': { file: 'client.js',  type: 'application/javascript; charset=utf-8' },
}

// Builds the JSON payload for /api/env on each request so uptime is always fresh.
function buildEnvPayload() {
  return {
    vars: [
      { label: 'APP_NAME',    value: APP_NAME,                    source: 'ENV / -e' },
      { label: 'APP_ENV',     value: APP_ENV,                     source: 'ENV / -e' },
      { label: 'APP_MESSAGE', value: APP_MESSAGE,                 source: 'ENV / -e' },
      { label: 'PORT',        value: PORT,                        source: 'ENV / -e' },
      { label: 'DB_HOST',     value: DB_HOST,                     source: 'ConfigMap (futuro)' },
      { label: 'DB_USER',     value: DB_USER,                     source: 'ConfigMap (futuro)' },
      { label: 'DB_PASS',     value: DB_PASS,                     source: 'Secret (futuro)' },
      { label: 'HOSTNAME',    value: os.hostname(),               source: 'automático (kernel)' },
      { label: 'Uptime (s)',  value: process.uptime().toFixed(1), source: 'automático (processo)' },
    ],
    nodeVersion: process.version,
  }
}

// ---------------------------------------------------------------------------
// HTTP server — serves static files and the /api/env JSON endpoint.
// ---------------------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  const url = req.url.split('?')[0]

  if (url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'text/plain' })
    res.end('ok')
    return
  }

  if (url === '/api/env') {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(buildEnvPayload()))
    return
  }

  const route = STATIC_FILES[url]
  if (!route) {
    res.writeHead(404, { 'Content-Type': 'text/plain' })
    res.end('Not found')
    return
  }

  try {
    const content = await fs.readFile(path.join(__dirname, route.file))
    res.writeHead(200, { 'Content-Type': route.type })
    res.end(content)
  } catch {
    res.writeHead(500, { 'Content-Type': 'text/plain' })
    res.end('Internal error')
  }
})

server.listen(Number(PORT), () => {
  console.log(`[workshop-envs] ouvindo em http://0.0.0.0:${PORT}`)
  console.log(`[workshop-envs] APP_NAME="${APP_NAME}" APP_ENV="${APP_ENV}"`)
})
