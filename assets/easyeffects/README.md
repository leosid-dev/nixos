# EasyEffects Presets

These files are data assets only. The generic Home Manager module deploys them;
profiles decide which presets are available and which one is active.

## Presets

- `thinkbook-speakers-dolby-approximation-v1.json` targets the Lenovo ThinkBook
  16 G7 ARP internal stereo speakers and its Realtek ALC257 analog path. It is
  an approximate psychoacoustic tuning, not a Dolby-certified implementation.
  Output loudness is compensated (+4 dB EQ output gain against the −6 dB input
  headroom), and the bass-enhancer scope is bounded at 45 Hz to match the
  high-pass filter protecting the drivers.
- `headphones-neutral.json` is a neutral profile with only conservative peak
  protection. It is deployed for manual selection and is not automatically
  selected by the ThinkBook profile.

EasyEffects applies one output preset globally to its current processing chain;
automatic speaker-versus-headphone routing is not configured here. Select the
neutral preset manually before using headphones.
