# JACK ATTACK 64

A faithful, web-friendly, Windows & Android tribute to the 1983 Commodore 64 arcade-puzzle classic **Jack Attack**.

## Play in Your Browser
**[Play Jack Attack 64 Live](https://martinlcrook-crypto.github.io/jack-attack-64/)**

## Run on Windows (`.exe`)
Download **[`jack-attack-64.exe`](https://github.com/martinlcrook-crypto/jack-attack-64/raw/main/dist/jack-attack-64.exe)** — single-file portable Windows 10/11 (x64) executable with the game & icon embedded inside (no installer, no DLLs, works offline, saves high scores in `%LOCALAPPDATA%\JackAttack64`).

## Install on Android (`.apk`)
Download **[`jack-attack.apk`](https://github.com/martinlcrook-crypto/jack-attack-64/raw/main/dist/jack-attack.apk)** and open it on your Android device (Android 7.0+ / API 24–35, zero permissions required, works 100% offline).

## Gameplay & Controls
- **Goal:** Defeat every monster on screen to clear each of the **64 levels** (16 handcrafted arenas × 4 escalating speed cycles).
- **3 Ways to Defeat Monsters:**
  1. **Stomp** them by jumping and landing on their heads.
  2. **Squish** them horizontally by pushing a block against a wall, bar, or another block.
  3. **Crush** them by dropping a block onto them from above (watch your own head!).
- **Authentic C64 Rules:** Monsters can **only** kill Jack if they land on him from **above**—side and underneath bumps are safe.
- **Controls:**
  - **Keyboard:** `←` / `→` or `A` / `D` to move · `↑` / `W` / `X` to jump (up to 3 blocks high) · Hold `Space` / `Shift` / `Z` + direction to **push** (1+ blocks) or **pull** (1 block) · `P` pause · `R` retry · `M` mute.
  - **Touch / Android:** Responsive multi-touch D-pad + `GRAB` and `JUMP` arcade buttons (portrait & landscape).
  - **Gamepad:** Standard Bluetooth / USB controllers supported.

## Rebuilding Binaries
- **Windows EXE:** `./windows/build-exe.sh` (Go 1.24 + `x86_64-w64-mingw32-windres`)
- **Android APK:** `./android/build-apk.sh` (Android SDK 35 + JDK 11+)
