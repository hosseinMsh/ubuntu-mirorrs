#!/bin/bash
set -e

MIRRORS_IRAN=(
  "http://mirror.arvancloud.ir/ubuntu|ArvanCloud|تهران"
  "https://archive.ubuntu.petiak.ir/ubuntu/|Petiak|تهران"
  "http://repo.iut.ac.ir/repo/Ubuntu/|IUT|اصفهان"
  "https://mirrors.pardisco.co/ubuntu/|Pardisco|تهران"
  "http://mirror.aminidc.com/ubuntu/|AminiDC|تهران"
  "http://mirror.faraso.org/ubuntu/|Faraso|تهران"
  "https://ir.ubuntu.sindad.cloud/ubuntu/|Sindad|تهران"
  "https://ubuntu.hostiran.ir/ubuntuarchive/|Hostiran|تهران"
  "https://ubuntu.bardia.tech/|Bardia|تهران"
  "https://mirror.iranserver.com/ubuntu/|IranServer|تهران"
  "https://ir.archive.ubuntu.com/ubuntu/|Ubuntu Iran|تهران"
  "https://mirror.0-1.cloud/ubuntu/|0-1 Cloud|تهران"
  "http://linuxmirrors.ir/pub/ubuntu/|LinuxMirrors|تهران"
  "https://ubuntu.shatel.ir/ubuntu/|Shatel|تهران"
  "http://ubuntu.byteiran.com/ubuntu/|ByteIran|تهران"
  "https://mirror.rasanegar.com/ubuntu/|Rasanegar|تهران"
  "http://mirrors.sharif.ir/ubuntu/|دانشگاه شریف|تهران"
  "http://mirror.ut.ac.ir/ubuntu/|دانشگاه تهران|تهران"
  "http://mirror.afranet.com/ubuntu/|Afranet|تهران"
  "https://ubuntu.pishgaman.net/ubuntu/|Pishgaman|تهران"
  "http://mirror.manageit.ir/ubuntu/|ManageIT|تهران"
  "https://ubuntu-mirror.kimiahost.com/ubuntu/|KimiaHost|تهران"
  "https://mirror.digitalvps.ir/ubuntu/|DigitalVPS|تهران"
  "https://mirror.parsdev.com/ubuntu/|ParsDev|تهران"
  "http://mirrors.pol.hostinja.com/ubuntu/|Hostinja|تهران"
)

MIRRORS_WORLD=(
  "http://archive.ubuntu.com/ubuntu/|Ubuntu Official|USA"
  "http://mirrors.kernel.org/ubuntu/|Kernel.org|USA"
  "https://mirror.init7.net/ubuntu/|Init7|Switzerland"
  "http://ftp.rz.uni-wuerzburg.de/ubuntu/|Uni Wuerzburg|Germany"
  "http://mirror.23m.com/ubuntu/|23M|USA"
  "https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|Tsinghua|China"
  "https://mirrors.ustc.edu.cn/ubuntu/|USTC|China"
  "https://mirrors.aliyun.com/ubuntu/|Alibaba Cloud|China"
  "https://ftp.udx.icscoe.jp/Linux/ubuntu/|ICSCoE|Japan"
  "https://ftp.uni-stuttgart.de/ubuntu/|Uni Stuttgart|Germany"
  "https://mirror.aarnet.edu.au/pub/ubuntu/archive/|AARNet|Australia"
  "https://mirror.aktkn.sg/ubuntu/|AKTKN|Singapore"
)

ALL_MIRRORS=()

for m in "${MIRRORS_IRAN[@]}"; do
  ALL_MIRRORS+=("$m|ایران")
done
for m in "${MIRRORS_WORLD[@]}"; do
  ALL_MIRRORS+=("$m|خارجی")
done

TOTAL=${#ALL_MIRRORS[@]}
COUNT=0

mkdir -p docs
echo "[" > docs/mirrors.json
FIRST=true

for entry in "${ALL_MIRRORS[@]}"; do
  IFS='|' read -r url name location category <<< "$entry"
  COUNT=$((COUNT + 1))
  echo -n "[$COUNT/$TOTAL] $name ... "

  start_time=$(date +%s%N 2>/dev/null || echo 0)
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -L "$url" 2>/dev/null || true)
  end_time=$(date +%s%N 2>/dev/null || echo 0)

  if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
    status="online"
    status_fa="آنلاین"
    duration=$(( (end_time - start_time) / 1000000 ))
    echo "OK ${duration}ms"
  else
    status="offline"
    status_fa="آفلاین"
    duration=0
    echo "FAIL"
  fi

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> docs/mirrors.json
  fi

  cat >> docs/mirrors.json << EOF
  {
    "name": "$name",
    "url": "$url",
    "location": "$location",
    "category": "$category",
    "status": "$status",
    "status_fa": "$status_fa",
    "response_time": $duration
  }
EOF
done

echo "" >> docs/mirrors.json
echo "]" >> docs/mirrors.json

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
echo "$TIMESTAMP" > docs/timestamp.txt

python3 /dev/stdin << 'PYEOF'
import json, os, shlex

with open("docs/mirrors.json") as f:
    data = json.load(f)

online = [m for m in data if m["status"] == "online"]
offline = [m for m in data if m["status"] == "offline"]
total = len(data)
fastest = min(online, key=lambda m: m["response_time"]) if online else None

os.makedirs("docs", exist_ok=True)

with open("docs/stats.env", "w") as f:
    f.write(f"TOTAL={total}\n")
    f.write(f"ONLINE={len(online)}\n")
    f.write(f"OFFLINE={len(offline)}\n")
    fastest_name_raw = fastest["name"] if fastest else "N/A"
    fastest_ms_raw = fastest["response_time"] if fastest else 0
    fastest_name = shlex.quote(fastest_name_raw)
    fastest_ms = shlex.quote(str(fastest_ms_raw))
    f.write(f"FASTEST_NAME={fastest_name}\n")
    f.write(f"FASTEST_MS={fastest_ms}\n")

fastest_label = f"{fastest_name_raw} ({fastest_ms_raw}ms)" if fastest else "---"

html = r'''<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>وضعیت میرورهای Ubuntu ایران</title>
  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='45' fill='%23E95420'/><text x='50' y='68' font-size='45' text-anchor='middle' fill='white'>U</text></svg>">
  <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    :root {
      --bg: #0a0e14;
      --bg-alt: #0f1a1f;
      --card: #131a22;
      --card-hover: #1a2533;
      --border: rgba(233,84,32,0.12);
      --border-light: rgba(255,255,255,0.06);
      --text: #e8edf5;
      --text-secondary: #8899aa;
      --orange: #E95420;
      --orange-dim: rgba(233,84,32,0.15);
      --orange-glow: rgba(233,84,32,0.25);
      --aubergine: #772953;
      --green: #3fb950;
      --green-dim: rgba(63,185,80,0.15);
      --red: #f85149;
      --red-dim: rgba(248,81,73,0.15);
      --blue: #58a6ff;
      --yellow: #d29922;
    }
    body {
      font-family: 'Vazirmatn', -apple-system, BlinkMacSystemFont, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      overflow-x: hidden;
    }
    body::before {
      content: '';
      position: fixed;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: radial-gradient(ellipse at 20% 50%, rgba(233,84,32,0.06) 0%, transparent 50%),
                  radial-gradient(ellipse at 80% 20%, rgba(119,41,83,0.05) 0%, transparent 50%),
                  radial-gradient(ellipse at 50% 80%, rgba(233,84,32,0.03) 0%, transparent 50%);
      z-index: -1;
      animation: bgShift 20s ease-in-out infinite;
    }
    @keyframes bgShift {
      0%, 100% { transform: translate(0, 0) rotate(0deg); }
      33% { transform: translate(2%, -1%) rotate(1deg); }
      66% { transform: translate(-1%, 1%) rotate(-1deg); }
    }
    @keyframes fadeInUp {
      from { opacity: 0; transform: translateY(30px); }
      to { opacity: 1; transform: translateY(0); }
    }
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes pulse {
      0%, 100% { box-shadow: 0 0 0 0 var(--orange-glow); }
      50% { box-shadow: 0 0 20px 5px var(--orange-glow); }
    }
    @keyframes shimmer {
      0% { background-position: -200% 0; }
      100% { background-position: 200% 0; }
    }

    .container { max-width: 1280px; margin: 0 auto; padding: 24px 20px; animation: fadeIn 0.6s ease; }

    header {
      text-align: center;
      padding: 50px 0 40px;
      animation: fadeInUp 0.8s ease;
    }
    .logo {
      display: inline-flex;
      align-items: center;
      gap: 14px;
      margin-bottom: 12px;
    }
    .logo-icon {
      width: 52px;
      height: 52px;
      background: linear-gradient(135deg, #E95420, #c34113);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      font-weight: 900;
      color: #fff;
      box-shadow: 0 8px 32px rgba(233,84,32,0.3);
      animation: pulse 3s ease-in-out infinite;
    }
    header h1 {
      font-size: 2.2em;
      font-weight: 900;
      letter-spacing: -0.5px;
      background: linear-gradient(135deg, #E95420 0%, #f9a825 50%, #E95420 100%);
      background-size: 200% auto;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      animation: shimmer 4s linear infinite;
    }
    header p {
      color: var(--text-secondary);
      margin-top: 8px;
      font-size: 1em;
      font-weight: 400;
    }
    .header-badge {
      display: inline-block;
      margin-top: 12px;
      padding: 5px 16px;
      background: var(--orange-dim);
      border: 1px solid var(--border);
      border-radius: 20px;
      color: var(--orange);
      font-size: 0.8em;
      font-weight: 500;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 14px;
      margin-bottom: 32px;
      animation: fadeInUp 0.8s ease 0.1s both;
    }
    .stat-card {
      background: var(--card);
      border: 1px solid var(--border-light);
      border-radius: 16px;
      padding: 22px 18px;
      text-align: center;
      transition: all 0.3s ease;
      position: relative;
      overflow: hidden;
    }
    .stat-card::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 3px;
    }
    .stat-card:hover {
      transform: translateY(-4px);
      border-color: var(--border);
      background: var(--card-hover);
    }
    .stat-card.total::before { background: var(--blue); }
    .stat-card.online::before { background: var(--green); }
    .stat-card.offline::before { background: var(--red); }
    .stat-card.fastest::before { background: linear-gradient(90deg, var(--orange), var(--yellow)); }
    .stat-card .stat-icon { font-size: 1.6em; margin-bottom: 8px; }
    .stat-card .num { font-size: 2.4em; font-weight: 800; line-height: 1.1; }
    .stat-card .label { color: var(--text-secondary); font-size: 0.8em; font-weight: 500; margin-top: 4px; }
    .stat-card.total .num { color: var(--blue); }
    .stat-card.online .num { color: var(--green); }
    .stat-card.offline .num { color: var(--red); }
    .stat-card.fastest .num { color: var(--yellow); font-size: 1.2em; }

    .controls {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
      flex-wrap: wrap;
      align-items: center;
      animation: fadeInUp 0.8s ease 0.2s both;
    }
    .search-wrap {
      flex: 1;
      min-width: 200px;
      position: relative;
    }
    .search-wrap::before {
      content: '\01F50D';
      position: absolute;
      right: 14px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 0.85em;
      opacity: 0.5;
    }
    .search-wrap input {
      width: 100%;
      background: var(--card);
      border: 1px solid var(--border-light);
      color: var(--text);
      padding: 11px 40px 11px 14px;
      border-radius: 12px;
      font-size: 0.9em;
      font-family: inherit;
      transition: all 0.3s ease;
    }
    .search-wrap input:focus {
      outline: none;
      border-color: var(--orange);
      box-shadow: 0 0 0 3px var(--orange-dim);
    }
    .search-wrap input::placeholder { color: var(--text-secondary); opacity: 0.6; }
    .controls select {
      background: var(--card);
      border: 1px solid var(--border-light);
      color: var(--text);
      padding: 11px 14px;
      border-radius: 12px;
      font-size: 0.9em;
      font-family: inherit;
      cursor: pointer;
      transition: all 0.3s ease;
      appearance: none;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='%238899aa' viewBox='0 0 16 16'%3E%3Cpath d='M8 11L3 6h10z'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: left 10px center;
      padding-left: 30px;
    }
    .controls select:focus {
      outline: none;
      border-color: var(--orange);
      box-shadow: 0 0 0 3px var(--orange-dim);
    }
    .github-btn {
      background: var(--card);
      color: var(--text);
      border: 1px solid var(--border-light);
      padding: 11px 18px;
      border-radius: 12px;
      text-decoration: none;
      font-size: 0.85em;
      font-family: inherit;
      transition: all 0.3s ease;
      white-space: nowrap;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .github-btn:hover {
      border-color: var(--orange);
      background: var(--orange-dim);
      color: var(--orange);
      transform: translateY(-2px);
    }
    .count {
      color: var(--text-secondary);
      font-size: 0.85em;
      font-weight: 500;
      white-space: nowrap;
    }

    .last-updated {
      text-align: center;
      color: var(--text-secondary);
      font-size: 0.8em;
      margin-bottom: 20px;
      animation: fadeInUp 0.8s ease 0.25s both;
    }
    .last-updated strong { color: var(--text); }

    .table-wrap {
      border-radius: 16px;
      border: 1px solid var(--border-light);
      overflow: hidden;
      background: var(--card);
      animation: fadeInUp 0.8s ease 0.3s both;
    }
    table { width: 100%; border-collapse: collapse; }
    th {
      background: rgba(233,84,32,0.08);
      padding: 16px 16px;
      text-align: right;
      font-weight: 600;
      font-size: 0.8em;
      color: var(--text-secondary);
      letter-spacing: 0.5px;
      white-space: nowrap;
    }
    td {
      padding: 13px 16px;
      border-top: 1px solid rgba(255,255,255,0.04);
      font-size: 0.88em;
      transition: background 0.2s ease;
    }
    tr { transition: background 0.2s ease; }
    tr:hover td { background: rgba(233,84,32,0.04); }
    tr:first-child td { border-top: none; }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 3px 12px;
      border-radius: 20px;
      font-size: 0.78em;
      font-weight: 600;
      white-space: nowrap;
    }
    .badge.online { background: var(--green-dim); color: var(--green); }
    .badge.offline { background: var(--red-dim); color: var(--red); }
    .badge.iran { background: rgba(88,166,255,0.1); color: var(--blue); }
    .badge.world { background: rgba(210,153,34,0.1); color: var(--yellow); }
    .ping { font-family: 'Courier New', monospace; direction: ltr; display: inline-block; font-weight: 600; }
    .ping.fast { color: var(--green); }
    .ping.medium { color: var(--yellow); }
    .ping.slow { color: var(--red); }
    .url-cell { direction: ltr; text-align: left; font-family: 'Courier New', monospace; font-size: 0.78em; color: var(--text-secondary); max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .status-col { text-align: center; }
    .name-cell { font-weight: 600; color: var(--text); }

    footer {
      text-align: center;
      padding: 50px 0 30px;
      color: var(--text-secondary);
      font-size: 0.82em;
      animation: fadeInUp 0.8s ease 0.4s both;
    }
    footer a { color: var(--orange); text-decoration: none; font-weight: 500; transition: all 0.2s ease; }
    footer a:hover { text-decoration: underline; color: #f9a825; }
    footer .footer-links { display: flex; justify-content: center; gap: 20px; margin-top: 12px; flex-wrap: wrap; }

    @media (max-width: 900px) {
      .stats { grid-template-columns: repeat(2, 1fr); }
      .stats .stat-card.fastest { grid-column: 1 / -1; }
      header h1 { font-size: 1.6em; }
    }
    @media (max-width: 640px) {
      .container { padding: 16px 12px; }
      header { padding: 30px 0 24px; }
      header h1 { font-size: 1.3em; }
      .stats { gap: 10px; }
      .stat-card { padding: 16px 12px; }
      .stat-card .num { font-size: 1.8em; }
      .stat-card .stat-icon { font-size: 1.2em; }
      th, td { padding: 10px 10px; font-size: 0.78em; }
      .url-cell { max-width: 80px; }
      .controls select { font-size: 0.8em; padding: 9px 25px 9px 10px; }
      .search-wrap input { font-size: 0.8em; padding: 9px 35px 9px 10px; }
      .github-btn { font-size: 0.78em; padding: 9px 12px; }
      th:first-child, td:first-child { display: none; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="logo">
        <div class="logo-icon">U</div>
        <h1>وضعیت میرورهای Ubuntu</h1>
      </div>
      <p>بررسی لحظه‌ای وضعیت دسترسی و سرعت میرورهای Ubuntu در ایران و جهان</p>
      <div class="header-badge">⚡ به‌روزرسانی خودکار هر ۶ ساعت</div>
    </header>

    <div class="stats" id="stats">
      <div class="stat-card total"><div class="stat-icon">🗂️</div><div class="num">—</div><div class="label">تعداد کل میرورها</div></div>
      <div class="stat-card online"><div class="stat-icon">✅</div><div class="num">—</div><div class="label">میرورهای آنلاین</div></div>
      <div class="stat-card offline"><div class="stat-icon">❌</div><div class="num">—</div><div class="label">میرورهای آفلاین</div></div>
      <div class="stat-card fastest"><div class="stat-icon">⚡</div><div class="num">—</div><div class="label">سریع‌ترین میرور</div></div>
    </div>

    <div class="controls">
      <div class="search-wrap">
        <input type="text" id="search" placeholder="جستجو در نام، آدرس یا موقعیت..." oninput="renderTable()">
      </div>
      <select id="filter" onchange="renderTable()">
        <option value="all">همه میرورها</option>
        <option value="iran">🇮🇷 ایران</option>
        <option value="world">🌍 خارجی</option>
        <option value="online">✅ آنلاین</option>
        <option value="offline">❌ آفلاین</option>
      </select>
      <a href="https://github.com/hosseinMsh/ubuntu-mirorrs" target="_blank" class="github-btn">📂 مخزن پروژه</a>
      <span class="count" id="mirrorCount"></span>
    </div>

    <p class="last-updated" id="lastUpdated">در حال بارگذاری...</p>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>نام میرور</th>
            <th>موقعیت</th>
            <th>دسته</th>
            <th>وضعیت</th>
            <th>زمان پاسخ</th>
            <th>آدرس</th>
          </tr>
        </thead>
        <tbody id="mirrorTable"></tbody>
      </table>
    </div>

    <footer>
      <p>طراحی شده با ❤️ توسط <a href="https://github.com/hosseinMsh" target="_blank">Hossein.Msh</a></p>
      <div class="footer-links">
        <span>قدرت گرفته از <a href="https://github.com/features/actions" target="_blank">GitHub Actions</a></span>
        <span>·</span>
        <a href="https://github.com/hosseinMsh/ubuntu-mirorrs" target="_blank">📂 مخزن پروژه</a>
      </div>
    </footer>
  </div>

  <script>
    let data = [];

    async function fetchData() {
      try {
        const res = await fetch('mirrors.json?' + Date.now());
        data = await res.json();
        renderAll();
      } catch(e) {
        document.getElementById('lastUpdated').textContent = '❌ خطا در بارگذاری داده‌ها';
      }
    }

    function renderAll() {
      renderStats();
      renderTable();
      const ts = new Date().toLocaleString('fa-IR', {
        year: 'numeric', month: 'long', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
      });
      document.getElementById('lastUpdated').innerHTML =
        '🕒 آخرین به‌روزرسانی: <strong>' + ts + '</strong>';
    }

    function renderStats() {
      const online = data.filter(m => m.status === 'online').length;
      const offline = data.filter(m => m.status === 'offline').length;
      const onlineMirrors = data.filter(m => m.status === 'online');
      let fastest = null;
      if (onlineMirrors.length) {
        fastest = onlineMirrors.reduce((a, b) => a.response_time < b.response_time ? a : b);
      }
      document.getElementById('stats').innerHTML = `
        <div class="stat-card total"><div class="stat-icon">🗂️</div><div class="num">${data.length}</div><div class="label">تعداد کل میرورها</div></div>
        <div class="stat-card online"><div class="stat-icon">✅</div><div class="num">${online}</div><div class="label">میرورهای آنلاین</div></div>
        <div class="stat-card offline"><div class="stat-icon">❌</div><div class="num">${offline}</div><div class="label">میرورهای آفلاین</div></div>
        <div class="stat-card fastest"><div class="stat-icon">⚡</div><div class="num">${fastest ? fastest.name + ' — ' + fastest.response_time + ' ms' : '———'}</div><div class="label">سریع‌ترین میرور</div></div>
      `;
    }

    function pingClass(ms) {
      if (ms === 0) return '';
      if (ms < 300) return 'fast';
      if (ms < 800) return 'medium';
      return 'slow';
    }

    function renderTable() {
      const search = document.getElementById('search').value.toLowerCase();
      const filter = document.getElementById('filter').value;
      let filtered = data.filter(m => {
        if (filter === 'iran' && m.category !== 'ایران') return false;
        if (filter === 'world' && m.category !== 'خارجی') return false;
        if (filter === 'online' && m.status !== 'online') return false;
        if (filter === 'offline' && m.status !== 'offline') return false;
        if (search && !m.name.toLowerCase().includes(search) &&
            !m.url.toLowerCase().includes(search) &&
            !m.location.toLowerCase().includes(search)) return false;
        return true;
      });
      document.getElementById('mirrorCount').textContent =
        'نمایش ' + filtered.length + ' از ' + data.length + ' میرور';
      const tbody = document.getElementById('mirrorTable');
      if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7"><div class="empty-state" style="text-align:center;padding:60px 20px;color:var(--text-secondary)"><div style="font-size:3em;margin-bottom:12px;opacity:0.5">🔍</div>میروری یافت نشد</div></td></tr>';
        return;
      }
      tbody.innerHTML = filtered.map((m, i) => {
        const catBadge = m.category === 'ایران' ? 'iran' : 'world';
        const catLabel = m.category === 'ایران' ? '🇮🇷 ایران' : '🌍 خارجی';
        const pingHtml = m.status === 'online'
          ? '<span class="ping ' + pingClass(m.response_time) + '">' + m.response_time + ' ms</span>'
          : '<span style="color:var(--text-secondary)">———</span>';
        return '<tr>' +
          '<td style="color:var(--text-secondary)">' + (i + 1) + '</td>' +
          '<td class="name-cell">' + m.name + '</td>' +
          '<td>' + m.location + '</td>' +
          '<td><span class="badge ' + catBadge + '">' + catLabel + '</span></td>' +
          '<td class="status-col"><span class="badge ' + m.status + '">' + m.status_fa + '</span></td>' +
          '<td>' + pingHtml + '</td>' +
          '<td class="url-cell" title="' + m.url + '">' + m.url + '</td>' +
          '</tr>';
      }).join('');
    }

    fetchData();
  </script>
</body>
</html>'''

with open("docs/index.html", "w", encoding="utf-8") as f:
    f.write(html)

print(f"TOTAL={total}")
print(f"ONLINE={len(online)}")
print(f"OFFLINE={len(offline)}")
print(f"FASTEST={fastest_label}")
PYEOF

source docs/stats.env

echo ""
echo "============================================"
echo "  نتایج تست میرورها"
echo "============================================"
echo "  کل میرورها:  $TOTAL"
echo "  آنلاین:      $ONLINE"
echo "  آفلاین:      $OFFLINE"
echo "  سریع‌ترین:   $FASTEST_NAME ($FASTEST_MS ms)"
echo "============================================"
echo ""
echo "✅ فایل‌های خروجی در docs/ تولید شدند:"
echo "   - docs/index.html"
echo "   - docs/mirrors.json"
echo "   - docs/stats.env"
echo "   - docs/timestamp.txt"
ls -la docs/
