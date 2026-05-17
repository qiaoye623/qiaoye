"""
CORS 代理服务器 (Python)
只使用澳门彩真实数据源，不包含大陆彩票数据
用法: python server/proxy.py
"""

import http.server
import json
import re
import random
import time
import urllib.parse
import requests

PORT = 3002
CACHE_DURATION = 30
RETRY_DELAY = 5

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json, text/html, */*',
    'Referer': 'https://yyswz.uhfasuf.com:14949/kj/amkjtop.html',
}

_cache = {'data': None, 'time': 0}
_last_fetch_time = 0


def parse_k_data(k_value):
    """解析澳门彩 k 值
    格式: 期号,6平肖,特码,下期,月,日,星期,时间
    例: 133,38,14,23,01,26,44,07,134,05,14,四,21点32分
    """
    parts = k_value.split(',')
    if len(parts) < 8:
        return None
    numbers = [n.strip().zfill(2) for n in parts[1:7]]
    special = parts[7].strip().zfill(2)
    return {
        'period': f'第{parts[0].strip()}期',
        'numbers': numbers,
        'special': special,
    }


def fetch_direct():
    """从澳门彩实时 API 直接获取"""
    url = 'https://yyswz.uhfasuf.com:14949/kj/caiji/amkj.js'
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        if r.status_code != 200:
            return None
        k = r.json().get('k', '')
        if not k:
            return None
        result = parse_k_data(k)
        if result:
            return result
    except Exception as e:
        pass
    return None


def fetch_via_entry():
    """从 0542.com 获取6个入口链接，随机选一个抓取数据"""
    import ssl
    try:
        r = requests.get('https://0542.com', headers=HEADERS, timeout=15)
        if r.status_code != 200:
            return None
        html = r.text
        if 'contact' in html[:500].lower() or 'inq-form' in html:
            return None

        # 提取所有可能的入口链接 —— 匹配各种常见写法
        links = []

        # <a href="...">线路入口①</a> 或 <a href="...">LY1</a> 等
        pat1 = re.findall(
            r'<a[^>]*href=[\"\'](https?://[^\"\']+)[\"\'][^>]*>.*?(?:线路|入口|LY|ly|ly\d).*?</a>',
            html, re.IGNORECASE
        )
        links.extend(pat1)

        # onclick / data-href 等属性中的 URL
        pat2 = re.findall(
            r'(?:onclick|data-href|data-url)=[\"\'](?:window\.location[.=])?[\"\']?(https?://[^\"\'\s]+)[\"\'\s]',
            html
        )
        links.extend(pat2)

        if links:
            target = random.choice(links)
            return fetch_entry_page(target)
    except Exception:
        pass
    return None


def fetch_entry_page(url):
    """访问入口页面，提取 #tmpinfo 数据"""
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        if r.status_code != 200:
            return None
        html = r.text

        # tmpinfo div
        m = re.search(r'<div[^>]*id=[\"\']tmpinfo[\"\'][^>]*>([^<]+)</div>', html)
        if m:
            result = parse_k_data(m.group(1).strip())
            if result:
                return result

        # 如果入口页有 iframe，从 iframe 数据 API 获取
        im = re.search(r'<iframe[^>]*src=[\"\'](https?://[^\"\']+amkj[^\"\']*)[\"\']', html)
        if im:
            return fetch_from_iframe(im.group(1))
    except Exception:
        pass
    return None


def fetch_from_iframe(iframe_url):
    """从 iframe URL 推导 caiji API"""
    try:
        parsed = urllib.parse.urlparse(iframe_url)
        api = f'{parsed.scheme}://{parsed.netloc}/kj/caiji/amkj.js'
        r = requests.get(api, headers=HEADERS, timeout=15)
        if r.status_code != 200:
            return None
        k = r.json().get('k', '')
        if k:
            return parse_k_data(k)
    except Exception:
        pass
    return None


def fetch_lottery_data():
    global _last_fetch_time
    now = time.time()

    if _cache['data'] and (now - _cache['time']) < CACHE_DURATION:
        return _cache['data']

    if (now - _last_fetch_time) < RETRY_DELAY:
        if _cache['data']:
            return _cache['data']
        return None

    _last_fetch_time = now

    # 只使用澳门彩数据源，无大陆彩票
    fetchers = [
        ('direct_api', fetch_direct),
        ('entry_page', fetch_via_entry),
    ]

    for name, fn in fetchers:
        try:
            result = fn()
            if result:
                _cache['data'] = result
                _cache['time'] = now
                return result
        except Exception:
            continue

    if _cache['data']:
        return _cache['data']
    return None


class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, status, body, ct='text/plain; charset=utf-8'):
        self.send_response(status)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Content-Type', ct)
        self.end_headers()
        if isinstance(body, str):
            body = body.encode('utf-8')
        self.wfile.write(body)

    def do_OPTIONS(self):
        self._send(200, b'')

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path.rstrip('/')

        if path in ('', '/lottery'):
            data = fetch_lottery_data()
            if data:
                self._send(200, json.dumps(data, ensure_ascii=False),
                           'application/json; charset=utf-8')
            else:
                self._send(502, json.dumps(
                    {'error': '获取澳门彩数据失败，请检查网络'},
                    ensure_ascii=False), 'application/json; charset=utf-8')
            return

        if path == '/debug':
            try:
                r = requests.get(
                    'https://yyswz.uhfasuf.com:14949/kj/caiji/amkj.js',
                    headers=HEADERS, timeout=15)
                self._send(r.status_code, r.text, 'application/json')
            except Exception as e:
                self._send(502, f'Error: {e}')
            return

        # /relay?url=XXX
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        target = qs.get('url', [None])[0]
        if not target:
            self._send(400, 'Missing ?url=')
            return
        try:
            r = requests.get(target, headers=HEADERS, timeout=15)
            self._send(r.status_code, r.content,
                       r.headers.get('content-type', 'text/plain'))
        except Exception as e:
            self._send(502, f'Proxy error: {e}')

    def log_message(self, fmt, *args):
        pass


if __name__ == '__main__':
    s = http.server.HTTPServer(('127.0.0.1', PORT), Handler)
    print(f'Macau proxy on http://localhost:{PORT}', flush=True)
    s.serve_forever()
