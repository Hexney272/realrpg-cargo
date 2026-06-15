# 🚛 RealRPG Cargo | Advanced Trucking & Company System

> The most complete cargo delivery and trucking company script for FiveM (ESX).

![banner](https://img.shields.io/badge/Framework-ESX%20Legacy-green) ![version](https://img.shields.io/badge/Version-2.3-gold) ![lua](https://img.shields.io/badge/Lua-5.4-blue) ![vue](https://img.shields.io/badge/NUI-Vue%203-42b883)

---

## 🎥 Preview

[![Watch the video](https://img.youtube.com/vi/Q2TpDI_MPdI/maxresdefault.jpg)](https://youtu.be/Q2TpDI_MPdI)

---

## ⭐ Features

### 🚚 Cargo Delivery System
- **90+ unique products** with different properties (fragile, explosive, toxic, etc.)
- **Real-time trailer monitoring** – roll detection, collision damage, overturning
- **Dynamic pricing** – distance-based with property multipliers
- **Cargo theft** – steal other players' trailers for black money
- **Mission system** – faction-based protection/defense mechanics
- **Speed limit enforcement** – city/country zones with HUD alerts
- **Built-in cruise control** with speed limiter

### 🏢 Trucking Company System
- **Found your own company** – hire employees, build your fleet
- **4 employee roles** – Sofőr, Diszpécser, Menedzser, Tulajdonos
- **Role-based permissions** – hire, fire, manage vehicles, accept contracts
- **Vehicle fleet management** – buy/sell trucks, track mileage & health
- **Shared contract system** – competitive! All companies see the same contracts, first to accept wins
- **Company treasury** – deposit/withdraw, automatic salary payments
- **Tax system** – configurable tax rate on company income
- **5 company levels** – progress through reputation and deliveries
- **Transaction history** – full audit log of all financial operations

### 📱 Quasar Smartphone V3 Integration
- **Custom phone app** – manage your company from your phone
- **Dashboard** – company overview, balance, reputation
- **Contracts** – browse and accept contracts on the go
- **Statistics** – delivery history, quality rate
- **Finance** – deposit/withdraw from company treasury
- **Push notifications** – real-time alerts for cargo events

### 🏆 Achievement System
- **11 achievements** with automatic detection
- **Golden animated popup** on unlock
- **Persistent storage** in database
- **Discord webhook** notifications

### 📊 Statistics & Ranking
- **Per-player stats** – distance, quality, success rate, working time
- **5 ranks** (Iron → Platinum) with progression conditions
- **10 titles** (Newbie → Divine Champion)
- **Leaderboard** with sorting options

### 🔒 Security
- **Server-side payment calculation** – prevents money exploits
- **SQL injection prevention** – whitelist validation
- **pcall error handling** – prevents server crashes
- **Anti-cheat** – all monetary values validated server-side

### 🔔 Discord Integration
- Webhook notifications for: mission start, delivery, theft, destruction
- Company events logging
- Achievement unlock notifications

---

## 📋 Requirements

| Resource | Version | Required |
|----------|---------|----------|
| [es_extended](https://github.com/esx-framework/esx-legacy) | Legacy | ✅ |
| [oxmysql](https://github.com/overextended/oxmysql) | Latest | ✅ |
| [ox_lib](https://github.com/overextended/ox_lib) | Latest | ✅ |
| [qs-smartphone](https://www.quasar-store.com/smartphone) | V3 | Optional (phone app) |

---

## 🛠️ Installation

### 1. Database
```sql
-- Import main tables
mysql -u root -p your_database < realrpg_cargo.sql

-- Import company system tables
mysql -u root -p your_database < realrpg_cargo_company.sql
```

### 2. Resource Setup
```cfg
# server.cfg
ensure ox_lib
ensure oxmysql
ensure es_extended
ensure realrpg-cargo

# Optional: Phone app (requires qs-smartphone V3)
ensure realrpg-cargo-phone
```

### 3. Configuration
All settings in `config.lua`:
- Delivery pricing (km fee, base fee, multipliers)
- Company system (registration fee, levels, roles, salaries, vehicles)
- Faction lists (defenders, attackers)
- Achievement conditions
- Discord webhook
- Speed limits
- And much more...

---

## 💰 Economy (Configurable)

| Activity | Earnings |
|----------|----------|
| Normal delivery (5km) | ~27.000 Ft |
| Normal delivery (10km) | ~39.000 Ft |
| Dangerous cargo (20km) | ~80.000 Ft |
| **Defender mission (10km)** | **~156.000 Ft** |
| **Defender mission (20km)** | **~240.000 Ft** |
| Contract bonus | +20% quality bonus |
| Stolen cargo | 2.000.000 Ft (high risk) |

### Company costs:
- Registration: 2.500.000 Ft
- Trucks: 8.500.000 - 18.500.000 Ft
- Employee salary: 35.000 - 85.000 Ft/delivery

*All values configurable in config.lua*

---

## 🎮 Commands

| Command | Description |
|---------|-------------|
| `/inspect` | Inspect a nearby trailer |
| `/mission` | Open mission list |
| `/cargostat` | View statistics |
| `/company` | Open company panel |
| `/gencontracts` | Generate contracts (admin) |
| `/cargodiag` | Database diagnostics (admin) |

---

## 🏗️ Technical Details

### Stack
- **Lua 5.4** – modern syntax, better performance
- **Vue 3 + Vite** – premium NUI with glassmorphism design
- **ox_lib** – callbacks, server communication
- **oxmysql** – async database with prepared statements
- **Quasar Bridge** – phone app iframe integration

### Performance
- Dynamic monitoring frequency (idle: 100ms, speed: every frame)
- Squared distance calculations (no sqrt overhead)
- Server-side product caching
- Optimized zone proximity checks

### Database Tables
- `realrpg_cargo_products` – 94 products
- `realrpg_cargo_zones` – 80+ delivery zones
- `realrpg_cargo_distances` – pre-calculated routes
- `realrpg_cargo_stats` – player statistics + achievements
- `realrpg_cargo_companies` – trucking companies
- `realrpg_cargo_employees` – company members
- `realrpg_cargo_vehicles` – company fleet
- `realrpg_cargo_contracts` – shared competitive contracts
- `realrpg_cargo_transactions` – financial audit log
- `realrpg_cargo_invites` – employee invitations

---

## 🌐 Localization

- 🇭🇺 Hungarian (full)
- 🇬🇧 English (full)
- Easy to add new languages (JSON + Lua locale files)

---

## 📸 Screenshots

*Company Dashboard • Contract System • Real-time HUD • Achievement Popup • Phone App*

---

## 📝 Changelog

### v2.3 (Latest)
- Trucking Company System (5 levels, roles, vehicles, contracts)
- Shared competitive contracts (first come, first served)
- Quasar Smartphone V3 integration
- Achievement system (11 achievements)
- Discord webhooks
- Premium glassmorphism UI (Vue 3)
- ESX + ox_inventory compatible money system
- Realistic Hungarian economy (Ft)

### v2.0
- ox_lib integration (lib.callback)
- oxmysql migration
- Server-side payment security
- Performance optimizations
- Lua 5.4 support

### v1.0
- Original cargo delivery system
- 94 products, 80+ zones
- Mission/defense system
- Statistics & ranking

---

## 🤝 Support

- Discord: [Your Discord Link]
- Documentation: Included in package
- Updates: Free lifetime updates

---

## 📄 License

This script is sold as-is. Redistribution or resale is prohibited.
One purchase = one server license.

---

*Made with ❤️ for the FiveM community*
