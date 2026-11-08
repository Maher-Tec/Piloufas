<div align="center">

<img src="assets/images/app_icon.png" alt="Piloufas App Icon" width="160" height="160" style="border-radius: 36px; box-shadow: 0 20px 40px rgba(255, 212, 112, 0.35);" />

# 🪙 Piloufas · بيلوفاس
### *The Sovereign 24k Gold Decision Coin & Intuition Mirror*

[![Flutter](https://img.shields.io/badge/Flutter-3.4%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-F5A623?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-101428?style=for-the-badge)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Rendering-CustomPainter%203D%20Pseudo--Engine-D4922A?style=for-the-badge)](#-bespoke-rendering-engine)

<p align="center">
  <b>Two Paths. One Moment of Truth.</b><br/>
  <i>“When a coin is in the air, you suddenly know what you are hoping for.”</i>
</p>

</div>

---

## 🌟 Overview

**Piloufas** (*بيلوفاس* — the authentic Tunisian name for the classic coin flip) is an open-source, ultra-luxury decision-making experience built with Flutter.

Unlike primitive random coin flippers, **Piloufas** is designed as a **psychological intuition mirror**. Inspired by Sigmund Freud's insight into decision-making, the app leverages realistic 3D perspective physics, device gyroscope parallax, tactile haptics, and acoustic ASMR so that during the coin's flight, your subconscious cuts through overthinking and reveals what you truly desired all along.

---

## 💎 Features at a Glance

| Feature | Category | Description | Status |
| :--- | :---: | :--- | :---: |
| **📳 Gyroscope 3D Shimmer** | *Sensory* | Real-time device tilt shifts specular light gleams across the 24k gold relief and creates 3D cosmic background parallax. | 🟢 Ready |
| **👆 Physical Flick-to-Toss** | *Physics* | Natural thumb swipe velocity detection: flick harder for higher launches and faster revolutions. | 🟢 Ready |
| **✋ Mid-Air Catch** | *Gesture* | Tap anywhere on the empty screen mid-flight to slap/catch the coin instantly with metallic impact audio. | 🟢 Ready |
| **🎬 Matrix Slow-Mo Apex** | *Cinematics* | Dynamic easing slows time at the peak trajectory with a +14% camera zoom before plunging down. | 🟢 Ready |
| **💥 Pedestal Shockwave** | *Visual FX* | Damped camera screen shake, dual expanding golden shockwaves, and 32 bouncing floor sparks upon landing. | 🟢 Ready |
| **👁️ Blind Intuition Reveal** | *Ritual* | Optional shroud covers the landed coin; test your secret hope before unveiling the verdict. | 🟢 Ready |
| **👑 The Royal Decree** | *Export* | 1-tap luxury 9:16 story card with unique decree serial (`#SA-XXXXXX`), timestamp, and clipboard copy. | 🟢 Ready |
| **🎨 4 Studio Auras** | *Atelier* | Switch between *Sovereign Gold*, *Imperial Jade*, *Crimson Velvet*, and *Astral Sapphire* lighting themes. | 🟢 Ready |
| **📊 Gut Clarity Analytics** | *Insights* | Custom-painted radial gauge analyzing how often your gut intuition rebelled against or matched randomness. | 🟢 Ready |

---

## 🆚 Why Piloufas is Different

<table>
  <thead>
    <tr style="background-color: #151824;">
      <th>Dimension</th>
      <th>Standard Coin Flipper Apps</th>
      <th>🪙 Piloufas (Sovereign Edition)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>Visual Fidelity</b></td>
      <td>Flat 2D PNG sprites rotating on an axis</td>
      <td><b>Milled rim reeding, extruded cylinder depth, dynamic specular sweeps, and ground pedestal shadow</b></td>
    </tr>
    <tr>
      <td><b>Interactivity</b></td>
      <td>Tap a button and wait</td>
      <td><b>Physical swipe flick, drag-to-tilt in 3D, and mid-air catch tap</b></td>
    </tr>
    <tr>
      <td><b>Sensory Feedback</b></td>
      <td>Generic robotic buzzer</td>
      <td><b>Device gyroscope parallax, pitch-variable spin ticks, heavy metal impact haptics</b></td>
    </tr>
    <tr>
      <td><b>Psychology</b></td>
      <td>Blindly dictates what you must do</td>
      <td><b>Intuition mirror that helps you discover what you were secretly wishing for</b></td>
    </tr>
    <tr>
      <td><b>Privacy</b></td>
      <td>Ad networks, trackers, permissions</td>
      <td><b>100% Offline, Zero trackers, MIT License, Zero telemetry</b></td>
    </tr>
  </tbody>
</table>

---

## 🎨 Royal Studio Auras

Piloufas includes 4 handcrafted lighting palettes that transform the ambient cosmos, specular coin highlights, and UI glows:

```
┌────────────────────────────────────────────────────────────────────────┐
│  👑 Sovereign Gold   │ Imperial obsidian & warm 24k minted gold        │
│  🌿 Imperial Jade    │ Deep emerald vault & burnished gold relief      │
│  🍷 Crimson Velvet   │ Royal opera crimson, velvet shroud & champagne │
│  🌌 Astral Sapphire  │ Midnight cosmos & starlight gold embers         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Architecture & Tech Stack

Piloufas is engineered with a clean, decoupled architecture utilizing native Flutter Canvas painting for high-performance 60/120 FPS rendering without third-party 3D engine overhead.

```
lib/
 ├── main.dart             # Application root, state controllers, and UI stages
 │    ├── AuraPalette      # Color definitions and studio lighting presets
 │    ├── CoinHome         # Reactive core with Gyroscope & Flick state
 │    ├── MintedCoinPainter# CustomPainter pseudo-3D coin, milled rim & sparks
 │    ├── RoyalCosmosPainter# Parallax astrolabe rings & floating embers
 │    └── ClarityGaugePainter# Radial intuition analytics visualization
assets/
 ├── images/
 │    ├── app_icon.png     # 1024x1024 Master luxury icon
 │    ├── coin_heads.png   # Maher Ahmed Sovereign Portrait (Obverse)
 │    └── coin_tails.png   # Royal Crown & Laurel Crest (Reverse)
 └── audio/
      ├── air_whoosh.wav   # Launch whoosh sound
      ├── metal_tick.wav   # Pitch-variable rotational reeding ticks
      ├── metal_land.wav   # Heavy pedestal impact
      └── reveal.wav       # Celebratory royal reveal chime
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.4.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.4.0 < 4.0.0`)
- Android Studio / Xcode / VS Code with Flutter extensions

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Maher-Tec/Piloufas.git
   cd Piloufas
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code validation:**
   ```bash
   flutter analyze
   ```

4. **Launch the application:**
   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Windows / macOS / Linux Desktop
   flutter run -d windows
   ```

---

## 📱 Gestures Guide

| Action | Where | Gesture | Result |
| :--- | :--- | :--- | :--- |
| **Launch Toss** | Oracle Stage | Swipe thumb up quickly | Launches coin with flight duration proportional to flick speed |
| **Inspect 3D Coin** | Oracle Stage | Drag finger across coin | Tilts coin in 3D perspective with real-time specular glints |
| **Flip Face Preview** | Oracle Stage | Single tap coin | Flips between **Heads (Portrait)** and **Tails (Laurel Crest)** |
| **Catch Mid-Air** | In Flight | Tap anywhere on screen | Slaps and halts coin immediately onto pedestal with metallic catch |
| **Lift Mystery Veil** | Result Stage | Tap shrouded coin or button | Dissolves velvet shroud with golden burst to reveal decree |
| **Tilt Shimmer** | Anywhere | Physically tilt phone | Gyroscope shifts lighting across gold relief and cosmos |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">
  <p>Crafted with 👑 by <b><a href="https://github.com/Maher-Tec">Maher Ahmed (Maher-Tec)</a></b></p>
  <p><i>Piloufas · بيلوفاس — Your reaction is the insight.</i></p>
</div>
