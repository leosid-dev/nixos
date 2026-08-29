# mpv Shortcuts Cheatsheet

Cheatsheet for the media player configured by `modules/home/mpv.nix`
(gated by `aspects.home.mpv`). The profile ships **default keybindings
only** — no custom `input.conf` — so this documents mpv 0.41 builtin
bindings plus the keybindings added by the scripts in use:

- `uosc` — modern on-screen UI (no keys rebound by default; menus and
  commands are opened from the on-screen control bar)
- `sponsorblock-minimal` — auto-skips YouTube sponsor segments
- `webtorrent-mpv-hook` — torrent streaming (`mpv magnet:?...` /
  `mpv file.torrent`)
- `yt-dlp` (via `ytdl_hook`) — URL/stream playback

Sources: mpv `etc/input.conf` @ v0.41.0, uosc 5.12.0 README, script
sources in the nix store. Anything marked "not bound" can be added in
`~/.config/mpv/input.conf`; `?` shows every currently active binding.

## Playback

| Keys | Action |
|---|---|
| `SPACE`, `p`, `PLAY` | Pause / resume |
| `q` | Quit |
| `Q` | Quit and remember position (resumes on reopen — `save-position-on-quit`) |
| `o` / `P` | Show progress / remaining time OSD |
| `l` | Set / clear A-B loop points (loop the section twice more) |
| `L` | Toggle infinite loop of current file |
| `b` | Toggle debanding filter |
| `d` | Cycle deinterlacing |
| `T` | Toggle window-on-top |
| `ESC` | Leave fullscreen (also `F11` on most systems via compositor) |

## Seeking & chapters

| Keys | Action |
|---|---|
| `←` / `→` | Back / forward 5 s |
| `↓` / `↑` | Back / forward 60 s |
| `PgUp` / `PgDn` | Next / previous chapter |
| `Shift+PgUp` / `Shift+PgDn` | +/− 600 s |
| `Home` | Seek to start |
| `Shift+←` / `Shift+→` | Exact ±1 s (keyframe-free) |
| `Ctrl+←` / `Ctrl+→` | Previous / next subtitle cue |
| `Shift+BS` | Revert last seek (undo) |
| `.` / `,` | Step one frame forward / backward |
| `Wheel` on uosc timeline | Seek by 5 s per notch |

## Speed

| Keys | Action |
|---|---|
| `[` / `]` | Decrease / increase speed (×1.1) |
| `{` / `}` | Halve / double speed |
| `BS` | Reset to 1× |
| `Alt+Shift+\` | Reset speed + flash uosc speed bar (uosc note, see below) |

## Audio

| Keys | Action |
|---|---|
| `9` / `0` | Volume −2 / +2 |
| `/` / `*` | Volume −2 / +2 |
| `m` | Mute |
| `#` | Switch audio track |
| `Ctrl++` / `Ctrl+-` | Audio delay +0.1 s / −0.1 s (A/V sync) |
| `Ctrl+p` | uosc: audio-track menu (bound only if you add it) |
| `Wheel` on uosc volume bar | Volume ±1 per notch; right-click to reset |

## Video & subtitles

| Keys | Action |
|---|---|
| `f` | Toggle fullscreen |
| `j` / `J` | Next / previous subtitle track |
| `v` | Toggle subtitle visibility |
| `z` | Shift subtitles 100 ms earlier |
| `x` / `Z` | Delay subtitles 100 ms |
| `r` / `R` / `t` | Move subtitles up / down |
| `G` / `F` | Increase / decrease subtitle font size |
| `_` | Switch video track |
| `A` | Cycle aspect ratio (16:9 → 4:3 → 2.35:1 → auto) |
| `Alt+1` / `Alt+2` / `Alt+0` | Window scale 1× / 2× / 0.5× |
| `Alt++` / `Alt+-` | Zoom in / out |
| `Ctrl+Wheel` | Zoom in / out toward cursor |
| `Alt+←→↑↓` | Pan the video |
| `Alt+BS` | Reset zoom / pan |
| `Ctrl+h` | Toggle hardware decoding |

## Screenshots

| Keys | Action |
|---|---|
| `s` | Screenshot (with subtitles) → `~/Pictures/mpv` |
| `S` | Screenshot (no subtitles) |
| `Ctrl+s` | Screenshot of window incl. OSD |
| `Alt+s` | Auto-screenshot every frame (toggle) |

## Stats & OSD

| Keys | Action |
|---|---|
| `i` | Show stats / status page (confirm `hwdec: vaapi`, `vo=gpu-next`) |
| `I` | Toggle always-visible stats |
| `?` | Show all active keybindings (great for discovery) |
| `` ` `` | mpv console (type commands) |
| `O` | Toggle OSD mode (interaction-only / always) |

## Playlist & streaming

| Keys | Action |
|---|---|
| `<` / `>` | Previous / next playlist item |
| `ENTER` | Next playlist item |
| `F8` | Show playlist |
| `F9` | Show track list |
| `Ctrl+v` | Append clipboard path/URL to playlist |
| — | `mpv <youtube-url>` — plays via yt-dlp, no pre-roll ads |
| — | `mpv magnet:?xt=urn:btih:…` / `mpv file.torrent` — streams via webtorrent |

## Scripts

### uosc (5.12.0)

Ships no default keybindings — the UI is mouse/proximity driven. The
**menu button** in the control bar (bottom-right) opens the default menu
(subtitles, audio, video, stream quality, playlist, chapters, …). All
menus are searchable — just start typing.

While a menu is open:

| Keys | Action |
|---|---|
| `↑` / `↓`, `PgUp`/`PgDn`, `Home`/`End` | Navigate |
| `ENTER` | Activate item / open submenu |
| `BS` | Parent menu |
| `ESC` | Close menu |
| `Ctrl+F` / `\` | Menu search (when `menu_type_to_search` is off) |
| `DEL` | Delete playlist item (`Shift+DEL` while search active) |

Timeline/volume/speed bars respond to the wheel; right-click volume or
speed resets it. Optional command bindings (`script-binding uosc/menu`,
`script-binding uosc/items`, …) are documented in the uosc README.

### sponsorblock-minimal

| Keys | Action |
|---|---|
| `b` | Toggle sponsor-segment skipping on/off |

Auto-skips YouTube sponsor segments while playing (needs the segment
submitted to SponsorBlock by the community; skipped segments show a
brief OSD notification).

### webtorrent-mpv-hook

| Keys | Action |
|---|---|
| `p` | Toggle torrent info/stats OSD (only while streaming a torrent) |

> **Note:** `p` is mpv's default *pause* key. While a torrent is playing
> the hook claims `p` for its info overlay; pause is then `SPACE`. For
> non-torrent playback `p` still pauses.

> **Torrentio/Stremio magnets:** those magnets ship every tracker as
> `tracker:udp://...`, a scheme webtorrent rejects — streaming would
> stall on "Info hash" forever. The hook is patched (see
> `modules/home/patches/`) to normalise them to plain `udp://`/`https://`
> trackers before playback, so Torrentio-style magnets work as-is.

## Hardware utilization at a glance

`i` (stats) should show:

- `vo: gpu-next` — libplacebo renderer on a Wayland context
- `hwdec: vaapi` — zero-copy GPU decoding (H.264/HEVC/VP9/AV1 on the
  Radeon 680M)
- `cache:` values > 0 for large/network files (512 MiB demuxer cache)

## References

- Config module: `modules/home/mpv.nix` (options under `aspects.home.mpv`)
- mpv docs: <https://mpv.io/manual/stable/input.html> (also `?` in mpv)
- uosc: <https://github.com/tomasklaen/uosc>
- SponsorBlock: <https://sponsor.ajay.app>
- webtorrent-mpv-hook: <https://github.com/mrxdst/webtorrent-mpv-hook>
