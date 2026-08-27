# EasyEffects Presets

These files are data assets only. The generic Home Manager module
(`modules/home/audio.nix`) deploys presets to `easyeffects/output/` and
impulse responses to `easyeffects/irs/`; profiles decide which presets are
available and which one is active.

## Approach: convolution, not EQ

The ThinkBook speakers were designed to run behind Lenovo's Dolby DAX3
processing on Windows; without it they sound thin and harsh. The v1 preset
approximated that chain with a hand-tuned parametric EQ, which cannot capture
the model-specific correction Lenovo's engineers measured. The current presets
instead convolve the audio with impulse responses captured from the Windows
Dolby endpoint of a ThinkBook 16 G7 (WASAPI loopback of an impulse, following
the method of `shuhaowu/linux-thinkpad-speaker-improvements`). Such a capture
contains the *linear* part of the Dolby chain — IEQ frequency correction,
per-channel audio-optimizer gains, the protective high-pass, and the
profile's linear effects — while the nonlinear stages (multiband compression,
limiting) are replaced by a single brickwall limiter with threshold boost:

`convolver → limiter` (and for the enhanced variant,
`convolver → exciter → autogain → limiter`, mirroring the stage design of
`mister2d/thinkpad-linux-audio`, which removes the classifier-dependent
multiband compressor and re-adds clarity/loudness stages instead).

## Presets

| Preset | Chain | Use |
|---|---|---|
| `thinkbook-speakers-dolby-music` | convolver (DolbyMusic) → limiter | Default; autoloaded at session start |
| `thinkbook-speakers-dolby-movie` | convolver (DolbyMovie) → limiter | Video; the Movie kernel includes Dolby's widening/dialog tuning |
| `thinkbook-speakers-enhanced` | convolver (DolbyMusic) → exciter → autogain → limiter | Extra clarity (5.5 kHz harmonics) and loudness normalisation (−14 LUFS) |
| `headphones-neutral` | limiter only | Neutral; select manually before using headphones |

The limiter is identical in all speaker presets: LSP brickwall at −1 dBFS
(Herm Thin, 4x half oversampling, 1 ms lookahead/attack, 5 ms release,
threshold boost on — peaks exit at 0 dBFS), stereo-linked.

Switching presets manually:

```
easyeffects --load-preset thinkbook-speakers-dolby-movie
```

(The EasyEffects service runs display-connected, so CLI commands and the GUI
share the same instance — opening the app from the launcher shows the
service's window instead of starting a second, blocked instance.)

## Impulse response provenance

`irs/thinkbook16-g7/DolbyMusic.irs` and `irs/thinkbook16-g7/DolbyMovie.irs`
were taken verbatim from
<https://github.com/shuhaowu/linux-thinkpad-speaker-improvements> at commit
`92410d62834508e20805c9431e192da21b12c339` (git blob SHAs verified). They are
48 kHz, 32-bit stereo WAV files (~1.6 KB, ~4 ms kernels) recorded by a
community contributor on a ThinkBook 16 G7 whose CPU variant is not stated.
The repository carries no license; the files are treated like binary firmware
data — sourced from the community for hardware compatibility, use at your own
risk. If the tuning ever sounds off on this machine (ARP variant), re-capture
locally per that repository's WASAPI loopback recipe.

## Warnings

- EasyEffects applies one output preset globally to its processing chain;
  automatic speaker-versus-headphone routing is not configured here. Select
  `headphones-neutral` manually before using headphones — the convolution
  kernels are tuned to the internal speakers and will color headphone output.
- The autogain stage in the enhanced variant normalises quiet content
  *upwards*; the limiter protects against the resulting peaks, but use the
  plain Dolby presets if you prefer level-stable output.
