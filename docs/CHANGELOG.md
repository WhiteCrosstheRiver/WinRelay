# Changelog

## 2026-10-30 (v0.2.1) — Chinese IME / keyboard UX fix

Live typing fought the phone's keyboard: `enableSuggestions: false` told IMEs
"no candidates here", so Chinese keyboards degraded to letter-by-letter input
with no candidate bar, no 中文/EN switch, no learning.

- The hidden typing field now keeps suggestions/autocorrect on. The sentinel
  already buffers composing text, so pinyin stays local until the word is
  chosen, then the committed text is sent to the PC — candidate bar and IME
  language keys work again.
- New 🌐 button in the quick-keys bar opens the system input-method picker
  (`InputMethodManager.showInputMethodPicker` via the `winrelay/ime` platform
  channel, Android MainActivity), so switching keyboards never leaves the
  control screen.
- Note: English words are now sent on commit (word-wise) instead of per key —
  that is what makes IME composing possible. Paste from the phone clipboard
  is still available via Quick keys → Paste.

## 2026-10-30 (v0.2.0)

### Stream tuning: control frame rate, picture size, grayscale (bandwidth saver)

The phone now controls how much data the video stream eats.

- Protocol: `open` carries optional `fps`, `pic_scale` (1.0/0.75/0.5), `gray`;
  a new `stream` message retunes a live session. Both ride the normal
  reconnect path (the open request is replayed).
- Host: `capture.rs` gained shared `CaptureParams` (atomics) read every frame;
  `downscale_to_width` area-average scales to any width; `to_gray` converts
  BT.601 luma in place. No restart needed when the phone retunes.
- Phone: Settings → 画面传输/Stream — frame rate (5/10/15/30 fps), picture
  size (100/75/50%), grayscale switch. Defaults keep the old behaviour
  (15 fps, full size, colour).
- Measured on this machine: 50% + grayscale ≈ 40 KB/frame vs 128 KB at full
  colour — roughly 3× less data. Grayscale + 50% + 5 fps is the "poor
  network" preset.

### Phone app: theme + 11 languages

- Appearance section in Settings: theme (System/Light/Dark) and language
  (English, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch,
  Italiano, Português (Brasil), Русский), applied immediately via gen-l10n
  (`flutter_localizations` + intl; all UI strings extracted).
- Connection failure reasons are localized client-side (`failKind`:
  unreachable / dropped / server); PC-side texts (deny reasons, kick reasons)
  still come from the host in English.

### Fix: pairing QR used a virtual NIC's address

`net.rs` now walks `GetAdaptersAddresses` (windows-rs 0.58) instead of
`if-addrs`: VMware VMnet, Hyper-V vEthernet, ZeroTier, VPN/TAP adapters and
non-NIC iftypes are excluded; privacy-temporary IPv6 addresses are skipped
(DNS-eligible only). The pairing link prefers the permanent global IPv6
address over LAN IPv4 (user request); "Allow connections over the internet"
must be on for the IPv6 link (it is, by default now, via Settings).

### Local toolchain

- Flutter 3.47.8 at `C:\Android\flutter` (on PATH), Android SDK 36 at
  `C:\Android\sdk`, pub/flutter via flutter-io.cn mirror, Gradle via local
  Clash proxy.
- Tests: `host/tests/e2e_pair_list.py` (pair + list), `e2e_v6_ingress.py`
  (public IPv6 WS ingress), `e2e_stream_tuning.py` (half-size gray frame
  then live retune to full).
