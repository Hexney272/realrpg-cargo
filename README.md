# RealRPG Cargo v2.1.0

Modern cargo delivery system for FiveM (ESX Framework).

![ecocargo gallery](https://github.com/Ekhion76/eco_cargo/blob/main/preview_images/eco_cargo_gallery.jpg)

## Demo

[![Watch the video](https://img.youtube.com/vi/Q2TpDI_MPdI/sddefault.jpg)](https://youtu.be/Q2TpDI_MPdI)

[![Convoy video](https://img.youtube.com/vi/8f7a2wVr2HU/sddefault.jpg)](https://youtu.be/8f7a2wVr2HU)

[Screenshots](https://postimg.cc/gallery/hmm2bTb)

---

## Dependencies

| Resource | Required | Description |
|----------|----------|-------------|
| [es_extended](https://github.com/esx-framework/esx-legacy) | Yes | ESX Legacy framework |
| [oxmysql](https://github.com/overextended/oxmysql) | Yes | Modern MySQL resource (replaces mysql-async) |
| [ox_lib](https://github.com/overextended/ox_lib) | Yes | Utility library (callbacks, locales, zones) |

---

## Features

### Core Gameplay
- Cargo delivery missions with 90+ unique products
- Trailer-based transport with real-time monitoring
- Dynamic pricing based on distance and cargo properties
- Cargo theft system (steal other players' trailers)
- Mission system with faction-based protection/defense mechanics
- Cruise control (built-in speed limiter)

### Monitoring System
- Real-time HUD: speed limit, trailer health, goods quality
- Roll detection, collision monitoring, overturning detection
- Dynamic damage calculation based on cargo properties
- Zone-based speed limit enforcement (city/country)

### Achievement System (New in v2.1)
- 11 achievements with automatic unlock detection
- Golden animated popup notification on achievement earned
- Persistent storage in database (JSON in `eco_cargo_stats.achievement`)
- Discord webhook notification on unlock
- Configurable conditions in `Config.achievements`

### Discord Integration (New in v2.1)
- Webhook notifications for major events
- Configurable event types: mission registered, cargo started/delivered/stolen/destroyed
- Rich embeds with color coding
- Configure in `Config.discord`

### Statistics & Ranking
- Per-player delivery statistics (distance, quality, time, success rate)
- Rank system (Iron -> Platinum) with progression conditions
- Title system (Newbie -> Divine Champion) based on distance + rank
- Leaderboard with sorting options

### Security
- Server-side payment calculation (prevents client-side money exploits)
- SQL injection prevention with column whitelist
- Server-validated caution money from product database
- Deprecated insecure client events with warning logs

---

## Installation

### 1. Database Setup
Import the SQL file into your database:
```sql
source eco_cargo.sql
```

### 2. Resource Installation
1. Place the `realrpg-cargo` folder (rename to `eco_cargo`) in your server's `resources` directory
2. Add to your `server.cfg`:
```cfg
ensure ox_lib
ensure oxmysql
ensure es_extended
ensure eco_cargo
```

### 3. Configuration
Edit `config.lua`:

```lua
Config.Locale = 'hu'  -- 'en' or 'hu'

-- Discord Webhook (optional)
Config.discord = {
    enabled = true,
    webhookUrl = 'YOUR_DISCORD_WEBHOOK_URL',
    -- ...
}

-- Faction lists
Config.lawEnforcementFactions = { 'police', 'sheriff', ... }
Config.illegalFactions = { 'vagos', 'ballas', ... }
```

### 4. Multi-Character Support
If using a multi-character system (e.g., kashacters):

1. Set `Config.kashacters = true` in config.lua
2. Ensure your character select script triggers `esx:kashloaded`:
```lua
RegisterNetEvent('kashactersC:SpawnCharacter')
AddEventHandler('kashactersC:SpawnCharacter', function(spawn, isnew)
    -- Character loading...
    TriggerEvent('esx:kashloaded')
end)
```

---

## Commands

### Player Commands
| Command | Description |
|---------|-------------|
| `/inspect` | Inspect a nearby trailer (on foot, within 10m) |
| `/mission` | Open mission list (available protection missions) |
| `/cargostat` | View personal delivery statistics |
| `/closenui` | Force close NUI interface |

### Admin Commands
| Command | Description |
|---------|-------------|
| `/cargodiag` | Database diagnostics & maintenance panel (admin/superadmin only) |

### Cruise Control (Built-in)
| Key | Action |
|-----|--------|
| Numpad `+` / Scroll Up | Increase speed by 10 km/h |
| Numpad `-` / Scroll Down | Decrease speed by 10 km/h |
| Brake / Handbrake | Disable cruise control |

> Enable cruise control in config: `Config.enableSpeedControl = true`

---

## Technical Architecture

### File Structure
```
eco_cargo/
├── client/
│   ├── main.lua            -- Client initialization, zone handling, NUI
│   ├── monitoring.lua      -- Real-time cargo monitoring threads
│   └── cruise_control.lua  -- Speed limiter system
├── server/
│   ├── main.lua            -- Server callbacks, events, payment logic
│   ├── discord.lua         -- Discord webhook module
│   └── achievements.lua    -- Achievement check & award system
├── libs/
│   ├── helper.lua          -- Shared utilities (ECO.Utils namespace)
│   ├── calculator.lua      -- Price & payment calculation (ECO.Calc)
│   ├── cargo.lua           -- Cargo state management
│   ├── hud.lua             -- HUD communication (ECO.Hud)
│   ├── monitor.lua         -- Monitoring functions (ECO.MonitorFn)
│   ├── mission.lua         -- Mission UI callbacks
│   ├── statistics.lua      -- Statistics page logic
│   ├── maintenance.lua     -- Admin diagnostics
│   ├── coords.lua          -- Coordinate utilities
│   └── distance.lua        -- Distance calculation
├── html/
│   ├── ui.html             -- NUI page (no jQuery)
│   ├── styles.css          -- Stylesheet + achievement popup
│   └── js/
│       ├── app.js          -- Main NUI logic (vanilla JS)
│       ├── helper.js       -- JS utilities, nuiPost(), formatStr()
│       └── hud.js          -- HUD rendering & notifications
├── locales/
│   ├── en.lua / en.json    -- English translations
│   └── hu.lua / hu.json    -- Hungarian translations
├── config.lua              -- All configuration
├── fxmanifest.lua          -- Resource manifest
└── eco_cargo.sql           -- Database schema + sample data
```

### Technology Stack
- **Lua 5.4** enabled (`lua54 'yes'`)
- **ox_lib** – `lib.callback` for client-server communication
- **oxmysql** – `MySQL.query.await` / `MySQL.update` for database
- **Vanilla JS** – No jQuery dependency in NUI
- **Namespaced modules** – `ECO.Calc`, `ECO.Hud`, `ECO.Utils`, `ECO.MonitorFn`

### Performance Optimizations
- Dynamic monitoring frequency based on vehicle speed (100ms idle → 0ms at speed)
- Squared distance comparison (no sqrt) for zone proximity checks
- Separated DrawMarker rendering from game logic
- Efficient cruise control with state-based Wait times
- Server-side product caching (loaded once from DB)

---

## Changelog

### v2.1.0 (2025)
- **NUI**: Complete rewrite from jQuery to vanilla JavaScript
- **Discord**: Webhook integration for cargo events
- **Achievements**: 11 achievements with auto-detection and golden popup
- **Performance**: Squared distance, dynamic wait optimization, cruise control refactor

### v2.0.0 (2025)
- **Security**: Server-side payment, SQL injection prevention
- **Database**: mysql-async → oxmysql migration
- **Framework**: ox_lib integration (lib.callback replaces ESX callbacks)
- **Code**: Namespaced modules with LuaDoc annotations
- **Locale**: JSON locale files for ox_lib compatibility
- **FXManifest**: Lua 5.4, explicit script loading, proper dependencies

### v1.0.0 (2021)
- Original release by Tutya & Ekhion

---

## Credits

- Original authors: **Tutya & Ekhion** (2020-2021)
- Modernization: Kiro AI (2025)
- Cruise Control based on: [teb_speed_control](https://github.com/hojgr/teb_speed_control)

---

## License

This project is provided as-is for educational and community use.
