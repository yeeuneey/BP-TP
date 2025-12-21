import { createServer } from 'node:http'

const PORT = process.env.PORT || 3001
const CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET

async function parseJson(req) {
  return new Promise((resolve, reject) => {
    let body = ''
    req.on('data', (chunk) => {
      body += chunk.toString()
    })
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {})
      } catch (err) {
        reject(err)
      }
    })
  })
}

async function exchangeToken({ code, redirectUri, clientId }) {
  const res = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: CLIENT_SECRET,
      code,
      redirect_uri: redirectUri,
    }),
  })

  if (!res.ok) {
    const message = await res.text()
    throw new Error(message || `GitHub token exchange failed: ${res.status}`)
  }

  const data = await res.json()
  if (!data.access_token) {
    throw new Error('No access_token in GitHub response')
  }
  return data.access_token
}

const server = createServer(async (req, res) => {
  if (req.method === 'POST' && req.url === '/auth/github/token') {
    try {
      if (!CLIENT_SECRET) {
        res.writeHead(500, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({ error: 'Missing GITHUB_CLIENT_SECRET' }))
        return
      }

      const body = await parseJson(req)
      const { code, redirectUri, clientId } = body || {}
      if (!code || !redirectUri || !clientId) {
        res.writeHead(400, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({ error: 'Missing code, redirectUri, or clientId' }))
        return
      }

      const accessToken = await exchangeToken({ code, redirectUri, clientId })
      res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ accessToken }))
    } catch (err) {
      console.error(err)
      res.writeHead(500, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }))
    }
    return
  }

  res.writeHead(404, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify({ error: 'Not found' }))
})

server.listen(PORT, () => {
  console.log(`GitHub token server running on http://localhost:${PORT}/auth/github/token`)
})
