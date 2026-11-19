# MiliConfig VPN (Android — Flutter + Go)

**One vibrant app. Multiple ways to stay connected — powered by MiliConfig & Xray-core.**

MiliConfig VPN brings customizable Cloudflare Workers & Pages deployment, **VLESS**, **WARP**, **MASQUE**, **Serverless**, **Psiphon**, **Tor**, a **REAL** Cloudflare/WARP/MASQUE scanner, and **Mili Hub** (696 Clean IPs across 21 countries, 1-tap Fragment & WARP OBF presets, and live Mili Panel sync) together in a lively Neon AMOLED Android client.

## Key Capabilities

- **One-Tap Cloudflare Deployment:** Guided Setup Wizard deploys private Workers & Pages directly from the app using your own Cloudflare account (with Domain Fronting, ECH, and Tor fallback).
- **Multi-Protocol Core:** Native Go Xray-core (`xray/`), Psiphon (`psiphon/`), Tor + lyrebird, WARP, MASQUE, and Serverless modes.
- **Built-in REAL Scanner (`scanner/`):** Scan live Cloudflare IPs and WARP/MASQUE endpoints tuned to your ISP.
- **Mili Hub Built-In:**
  - **696 Clean IP Pool (21 Countries):** Browse by country, lock a **Fixed IP**, or apply a random batch to VLESS Clean IPs in 1 tap.
  - **Mili Presets:** 1-tap TCP Fragment presets (`Mili Balanced`, `Mili Aggressive DPI Bypass`, `Mili Stealth`, `Mili High-Speed`), WARP OBF profiles (`OBF LITE`, `OBF BALANCED`, `OBF AGGRESSIVE`, `OBF STEALTH`), and DNS/Anti-Sanction presets.
  - **Mili Panel Sync:** Pull live `/ips` from any deployed MiliConfig Panel or import user subscriptions directly into Chain Proxies.
- **Vibrant Mili UI (7 Themes):** Neon Green AMOLED (default), Dark Emerald, Cyber Blue, Quantum Purple, Amber Gold, Blaze Fire, and Daylight Emerald — paired with Mili's glowing neon shield logo and animated ambient canvas.
- **Everyday Power Tools:** Per-app proxy, Chain Proxies (VLESS/VMess/Trojan/Shadowsocks/WireGuard/Hysteria), Routing rules, DNS/FakeDNS, LAN sharing, Live Logs, and Config import/export.

## Building & Releasing APKs (GitHub Actions)

1. Push this repository to GitHub.
2. (Optional) Add `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` in **Settings → Secrets and variables → Actions** for signed release APKs.
3. Tag a release matching `pubspec.yaml`:
   ```bash
   git tag v1.2.1 && git push origin v1.2.1
   ```
4. GitHub Actions (`.github/workflows/release.yml`) automatically builds `xray.aar`, `libpsiphon.so`, fetches Tor & Iran geo rules, minifies `worker/worker.js`, and publishes split + universal APKs.

## License

Licensed under [GNU GPL v3.0](LICENSE).
