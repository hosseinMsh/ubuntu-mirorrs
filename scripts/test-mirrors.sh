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
  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>📡</text></svg>">
  <style>
    :root { --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #f0f6fc; --muted: #8b949e; --green: #3fb950; --red: #f85149; --orange: #d29922; --blue: #58a6ff; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Vazirmatn', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    header { text-align: center; padding: 40px 0 30px; }
    header h1 { font-size: 2em; font-weight: 800; background: linear-gradient(135deg, #e95420, #f9a825); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    header p { color: var(--muted); margin-top: 8px; font-size: 0.95em; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 30px; }
    .stat-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; text-align: center; }
    .stat-card .num { font-size: 2em; font-weight: 700; }
    .stat-card .label { color: var(--muted); font-size: 0.85em; margin-top: 4px; }
    .stat-card.online .num { color: var(--green); }
    .stat-card.offline .num { color: var(--red); }
    .stat-card.total .num { color: var(--blue); }
    .stat-card.fastest .num { color: var(--orange); font-size: 1em; }
    .controls { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; align-items: center; }
    .controls input, .controls select { background: var(--card); border: 1px solid var(--border); color: var(--text); padding: 10px 14px; border-radius: 8px; font-size: 0.9em; }
    .controls input { flex: 1; min-width: 200px; }
    .controls select { cursor: pointer; }
    .refresh-btn { background: var(--blue); color: #fff; border: none; padding: 10px 18px; border-radius: 8px; cursor: pointer; font-size: 0.9em; transition: opacity 0.2s; }
    .refresh-btn:hover { opacity: 0.85; }
    .github-btn { background: var(--card); color: var(--text); border: 1px solid var(--border); padding: 10px 18px; border-radius: 8px; text-decoration: none; font-size: 0.9em; transition: border-color 0.2s; }
    .github-btn:hover { border-color: var(--blue); }
    .count { margin-right: auto; color: var(--muted); font-size: 0.9em; }
    .last-updated { text-align: center; color: var(--muted); font-size: 0.85em; margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; background: var(--card); border-radius: 12px; overflow: hidden; border: 1px solid var(--border); }
    th { background: #1c2333; padding: 14px 16px; text-align: right; font-weight: 600; font-size: 0.85em; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; }
    td { padding: 12px 16px; border-top: 1px solid var(--border); font-size: 0.9em; }
    tr:hover td { background: rgba(88,166,255,0.04); }
    .badge { display: inline-block; padding: 2px 10px; border-radius: 20px; font-size: 0.8em; font-weight: 600; }
    .badge.online { background: rgba(63,185,80,0.15); color: var(--green); }
    .badge.offline { background: rgba(248,81,73,0.15); color: var(--red); }
    .badge.iran { background: rgba(88,166,255,0.12); color: var(--blue); }
    .badge.world { background: rgba(210,153,34,0.12); color: var(--orange); }
    .ping { font-family: monospace; direction: ltr; display: inline-block; }
    .ping.fast { color: var(--green); }
    .ping.medium { color: var(--orange); }
    .ping.slow { color: var(--red); }
    .url-cell { direction: ltr; text-align: left; font-family: monospace; font-size: 0.8em; color: var(--muted); max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .status-col { text-align: center; }
    footer { text-align: center; padding: 40px 0; color: var(--muted); font-size: 0.85em; }
    footer a { color: var(--blue); text-decoration: none; }
    footer a:hover { text-decoration: underline; }
    @media (max-width: 768px) {
      .stats { grid-template-columns: repeat(2, 1fr); }
      th, td { padding: 8px; font-size: 0.8em; }
      .url-cell { max-width: 100px; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>📡 وضعیت میرورهای Ubuntu ایران</h1>
      <p>بررسی وضعیت دسترسی و سرعت میرورهای Ubuntu در ایران و جهان</p>
    </header>

    <div class="stats" id="stats"></div>

    <div class="controls">
      <input type="text" id="search" placeholder="جستجوی نام، آدرس یا موقعیت..." oninput="renderTable()">
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

    <footer>
      <p>طراحی شده با ❤️ توسط <a href="https://github.com/hosseinMsh" target="_blank">Hossein.Msh</a></p>
      <p style="margin-top:4px;">قدرت گرفته از <a href="https://github.com/features/actions" target="_blank">GitHub Actions</a></p>
      <p style="margin-top:4px;"><a href="https://github.com/hosseinMsh/ubuntu-mirorrs" target="_blank">📂 مخزن پروژه در GitHub</a></p>
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
      const ts = new Date().toLocaleString('fa-IR', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
      document.getElementById('lastUpdated').innerHTML = '🕒 آخرین بروزرسانی: <strong>' + ts + '</strong>';
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
        <div class="stat-card total"><div class="num">${data.length}</div><div class="label">تعداد کل میرورها</div></div>
        <div class="stat-card online"><div class="num">${online}</div><div class="label">میرورهای آنلاین</div></div>
        <div class="stat-card offline"><div class="num">${offline}</div><div class="label">میرورهای آفلاین</div></div>
        <div class="stat-card fastest"><div class="num">${fastest ? fastest.name + ' - ' + fastest.response_time + 'ms' : '---'}</div><div class="label">سریع‌ترین میرور</div></div>
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
        if (search && !m.name.toLowerCase().includes(search) && !m.url.toLowerCase().includes(search) && !m.location.toLowerCase().includes(search)) return false;
        return true;
      });
      document.getElementById('mirrorCount').textContent = 'نمایش ' + filtered.length + ' از ' + data.length + ' میرور';
      const tbody = document.getElementById('mirrorTable');
      if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">میروری یافت نشد</td></tr>';
        return;
      }
      tbody.innerHTML = filtered.map((m, i) => {
        const catBadge = m.category === 'ایران' ? 'iran' : 'world';
        const catLabel = m.category === 'ایران' ? '🇮🇷 ایران' : '🌍 خارجی';
        const pingHtml = m.status === 'online'
          ? '<span class="ping ' + pingClass(m.response_time) + '">' + m.response_time + ' ms</span>'
          : '---';
        return '<tr>' +
          '<td>' + (i + 1) + '</td>' +
          '<td><strong>' + m.name + '</strong></td>' +
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
