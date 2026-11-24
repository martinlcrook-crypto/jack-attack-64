# JACK ATTACK 64

A faithful, web-friendly & mobile-ready tribute to the 1983 Commodore 64 arcade-puzzle classic **Jack Attack**.

## Play in Your Browser
**[Play Jack Attack 64 Live](https://martinlcrook-crypto.github.io/jack-attack-64/)**

## Install on Android
Download **`jack-attack.apk`** from the [Releases page](https://github.com/martinlcrook-crypto/jack-attack-64/releases) (or directly from [`dist/jack-attack.apk`](dist/jack-attack.apk)) and open it on your Android device (Android 7.0+ / API 24–35, zero permissions required, works 100% offline).

## Gameplay & Controls
- **Goal:** Defeat every monster on screen to clear each of the **64 levels** (16 handcrafted arenas × 4 escalating speed cycles).
- **3 Ways to Defeat Monsters:**
  1. **Stomp** them by jumping and landing on their heads.
  2. **Squish** them horizontally by pushing a block against a wall, bar, or another block.
  3. **Crush** them by dropping a block onto them from above (watch your own head!).
- **Controls:**
  - **Keyboard:** `←` / `→` or `A` / `D` to move · `↑` / `W` / `X` to jump (up to 3 blocks high) · Hold `Space` / `Shift` / `Z` + direction to **push** (1+ blocks) or **pull** (1 block) · `P` pause · `R` retry · `M` mute.
  - **Touch / Android:** Responsive multi-touch D-pad + `GRAB` and `JUMP` arcade buttons (portrait & landscape).
  - **Gamepad:** Standard Bluetooth / USB controllers supported.

## Rebuilding the Android APK
```bash
./android/build-apk.sh
```
Requires Android SDK (`build-tools` 35.0.0 + `android-35`) and JDK 11+.
