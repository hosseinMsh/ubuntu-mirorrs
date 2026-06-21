<div align="center">
  <h1>📡 Ubuntu Mirrors Iran</h1>
  <p>
    <strong>Monitor the status and response time of Ubuntu mirrors in Iran and around the world</strong>
  </p>
  <p>
    <a href="https://github.com/hosseinMsh/ubuntu-mirorrs/actions/workflows/deploy.yml">
      <img src="https://github.com/hosseinMsh/ubuntu-mirorrs/actions/workflows/deploy.yml/badge.svg" alt="Deploy">
    </a>
    <a href="https://github.com/hosseinMsh/ubuntu-mirorrs/actions/workflows/test.yml">
      <img src="https://github.com/hosseinMsh/ubuntu-mirorrs/actions/workflows/test.yml/badge.svg" alt="CI">
    </a>
    <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fhosseinmsh.github.io%2Fubuntu-mirorrs%2Fstats.env&query=%24.ONLINE&label=%D8%A2%D9%86%D9%84%D8%A7%DB%8C%D9%86&color=3fb950" alt="Online">
    <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fhosseinmsh.github.io%2Fubuntu-mirorrs%2Fstats.env&query=%24.OFFLINE&label=%D8%A2%D9%81%D9%84%D8%A7%DB%8C%D9%86&color=f85149" alt="Offline">
  </p>
</div>

---

## 🌐 Live Site

**[→ View the Dashboard](https://hosseinmsh.github.io/ubuntu-mirorrs/)**

A live, auto-updating dashboard showing:
- ✅ Online/offline status of each mirror
- ⚡ Response time measurement
- 🔍 Search and filter by name, location, or category
- 🇮🇷 Iranian and 🌍 international mirrors

---

## 🪞 Mirrors Monitored

### 🇮🇷 Iran

| Mirror | Location |
|--------|----------|
| ArvanCloud | تهران |
| Petiak | تهران |
| IUT | اصفهان |
| Pardisco | تهران |
| AminiDC | تهران |
| Faraso | تهران |
| Sindad | تهران |
| Hostiran | تهران |
| Bardia | تهران |
| IranServer | تهران |
| Ubuntu Iran | تهران |
| 0-1 Cloud | تهران |
| LinuxMirrors | تهران |
| Shatel | تهران |
| ByteIran | تهران |
| Rasanegar | تهران |
| دانشگاه شریف | تهران |
| دانشگاه تهران | تهران |
| Afranet | تهران |
| Pishgaman | تهران |
| ManageIT | تهران |
| KimiaHost | تهران |
| DigitalVPS | تهران |
| ParsDev | تهران |
| Hostinja | تهران |

### 🌍 World

| Mirror | Location |
|--------|----------|
| Ubuntu Official | USA |
| Kernel.org | USA |
| Init7 | Switzerland |
| Uni Wuerzburg | Germany |
| 23M | USA |
| Tsinghua | China |
| USTC | China |
| Alibaba Cloud | China |
| ICSCoE | Japan |
| Uni Stuttgart | Germany |
| AARNet | Australia |
| AKTKN | Singapore |

---

## ⚙️ How It Works

1. **GitHub Actions** runs `scripts/test-mirrors.sh` every 6 hours (and on every push to `main`)
2. The script pings each mirror with `curl` and records HTTP status + response time
3. Data is saved as `mirrors.json` and a static `index.html` dashboard is generated
4. Everything is deployed to **GitHub Pages**

### Workflows

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| **Deploy** | Push to `main`, schedule (every 6h), manual | Tests mirrors and deploys to GitHub Pages |
| **CI** | Push/PR (non-main) | Validates shell scripts with ShellCheck and syntax check |
| **Weekly Report** | Every Monday, manual | Creates a GitHub Issue with mirror status summary |

---

## 🛠️ Local Development

```bash
# Clone the repo
git clone https://github.com/hosseinMsh/ubuntu-mirorrs.git
cd ubuntu-mirorrs

# Run the mirror test script
bash scripts/test-mirrors.sh

# Open the generated dashboard
open docs/index.html
```

**Requirements:** `bash`, `curl`, `python3`

---

## 🤝 Contributing

Want to add a new mirror? Edit `scripts/test-mirrors.sh` and add it to `MIRRORS_IRAN` or `MIRRORS_WORLD` arrays, then submit a pull request.

Format: `"URL|Name|Location"`

---

## 📄 License

This project is open source. Feel free to use, modify, and share.

---

<div align="center">
  <p>
    Made with ❤️ by <a href="https://github.com/hosseinMsh">Hossein.Msh</a>
  </p>
  <p>
    <a href="https://github.com/hosseinMsh/ubuntu-mirorrs">GitHub Repository</a>
  </p>
</div>
