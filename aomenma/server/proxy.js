/**
 * 本地 CORS 代理服务器（支持重定向跟随）
 * 用法: node server/proxy.js
 */
const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 3001;
const MAX_REDIRECTS = 5;

/** 包装回调确保只调用一次 */
function once(fn) {
  let called = false;
  return (...args) => {
    if (called) return;
    called = true;
    fn(...args);
  };
}

function fetch(targetUrl, redirectCount, callback) {
  callback = once(callback);
  if (redirectCount > MAX_REDIRECTS) {
    callback(new Error('Too many redirects'));
    return;
  }

  const targetParsed = url.parse(targetUrl);
  const client = targetParsed.protocol === 'https:' ? https : http;

  const options = {
    hostname: targetParsed.hostname,
    port: targetParsed.port || (targetParsed.protocol === 'https:' ? 443 : 80),
    path: targetParsed.path,
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'text/html,application/json,*/*',
    },
    timeout: 15000,
  };

  const req = client.request(options, (res) => {
    if (res.statusCode >= 301 && res.statusCode <= 308) {
      const location = res.headers.location;
      if (!location) {
        callback(new Error('Redirect without Location'));
        return;
      }
      const redirectUrl = url.resolve(targetUrl, location);
      fetch(redirectUrl, redirectCount + 1, callback);
      return;
    }

    let body = '';
    res.on('data', (chunk) => { body += chunk; });
    res.on('end', () => {
      callback(null, { statusCode: res.statusCode, headers: res.headers, body });
    });
  });

  req.on('error', callback);
  req.on('timeout', () => {
    req.destroy();
    callback(new Error('Timeout'));
  });
  req.end();
}

const server = http.createServer((req, res) => {
  const done = once(() => {});
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsed = url.parse(req.url, true);
  const targetUrl = parsed.query.url;
  if (!targetUrl) {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Missing ?url=');
    return;
  }

  fetch(targetUrl, 0, (err, result) => {
    if (err) {
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end(`Proxy error: ${err.message}`);
      done();
      return;
    }
    res.writeHead(result.statusCode, {
      'Content-Type': result.headers['content-type'] || 'text/plain',
    });
    res.end(result.body);
    done();
  });
});

server.listen(PORT, () => {
  console.log(`[proxy.js] CORS proxy running at http://localhost:${PORT}`);
});
