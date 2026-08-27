# modules/home/noctalia-cpu-power.nix — Noctalia CPU package power plugin (HM).
#
# Deploy-only: enables the local plugin, installs plugin.toml + main.luau, and
# declares [widget.actions]. Capsule membership and member presentation
# (0.9x scale) are owned by noctalia.nix (reads
# aspects.home.noctalia.cpuPower.enable); this module never writes
# bar.main.capsule_group.
#
# Sensor paths are explicit host data — never hardcoded machine facts here.
# Hosts enable only with a verified package-power source (e.g. ThinkBook
# RAPL); assertions fail eval when enabling without one or with unparallel
# energy/max path lists. Path and glyph options are charset-constrained so
# host data can never break the generated Luau.
#
# Sampling semantics (main.luau): watts are Δenergy/Δt between consecutive
# samples on one pinned source. The baseline resets whenever the resolved
# source changes, and samples are dropped + re-baselined on clock/suspend
# discontinuities (dt > max(4x pollIntervalMs, 10s)), on unrecoverable
# counter wraps, and on readings above maxWatts (sanity gate, not a display
# clamp). Tooltip mirrors the sibling sysmon widgets: own stat first, then
# noctalia.systemStats() rows when the monitor is up, then the source path.
#
# Tunables: pollIntervalMs, maxWatts, glyph. Format/tooltip strings are
# module intent. Left-click via plugin.toml [widget.actions] matches the
# sysmon type default (panel-toggle control-center system) so the whole
# capsule shares one action — capsule-level actions do not exist upstream,
# and bar-wide [bar.main].actions would override unrelated widgets.
{
  config,
  lib,
  ...
}:
let
  cfgShell = config.aspects.home.noctalia;
  cfg = config.aspects.home.noctalia.cpuPower;

  # Absolute sysfs paths only, restricted charset: every value is interpolated
  # into the generated Luau as a string literal, so anything outside this set
  # (quotes, backslashes, whitespace) is rejected at eval time, never at
  # plugin load time.
  sysfsPathType = lib.types.strMatching "^/[A-Za-z0-9/_.:-]+$";
in
{
  options.aspects.home.noctalia.cpuPower = {
    enable = lib.mkEnableOption "CPU package power telemetry (Noctalia sysmon capsule)";

    raplEnergyPaths = lib.mkOption {
      type = lib.types.listOf sysfsPathType;
      default = [ ];
      example = [
        "/sys/class/powercap/intel-rapl:0/energy_uj"
        "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
      ];
      description = ''
        Ordered RAPL energy_uj paths to probe for package power. The plugin
        computes watts as Δenergy/Δt and handles counter wrap via the matching
        max_energy_range_uj path. The plugin pins the first readable path and
        resets its baseline whenever the resolved source changes. Host data:
        set per machine.
      '';
    };

    raplMaxPaths = lib.mkOption {
      type = lib.types.listOf sysfsPathType;
      default = [ ];
      example = [
        "/sys/class/powercap/intel-rapl:0/max_energy_range_uj"
        "/sys/class/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj"
      ];
      description = ''
        RAPL max_energy_range_uj paths, parallel to raplEnergyPaths (same
        length, same order). The counter-wrap range is read from the path
        matching the energy path in use. Host data: set per machine.
      '';
    };

    hwmonPath = lib.mkOption {
      type = lib.types.nullOr sysfsPathType;
      default = null;
      example = "/sys/class/hwmon/hwmon0/power1_input";
      description = ''
        Explicit hwmon power1_input fallback path (instantaneous microwatts).
        null disables hwmon fallback. Never use a blind hwmon scan; bind the
        verified sensor explicitly.
      '';
    };

    pollIntervalMs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2000;
      description = ''
        Plugin sampling interval in milliseconds. Watts are computed as
        Δenergy/Δt between consecutive samples; the value changes slowly,
        so higher intervals cost less and look identical. Also sets the
        discontinuity window: samples more than max(4x this value, 10s)
        apart (suspend, clock steps) are dropped and re-baselined.
      '';
    };

    maxWatts = lib.mkOption {
      type = lib.types.ints.positive;
      default = 500;
      description = ''
        Sanity gate for computed package power. Readings above this are
        treated as bogus deltas (counter glitches, path mix-ups) and
        dropped: the widget keeps its last plausible reading and
        re-baselines. Not a display clamp.
      '';
    };

    glyph = lib.mkOption {
      type = lib.types.strMatching "^[A-Za-z0-9_-]+$";
      default = "bolt";
      description = ''
        Noctalia Material glyph name shown beside the watt reading.
        Module default; hosts may override.
      '';
    };
  };

  config = lib.mkIf (cfgShell.enable && cfg.enable) {
    # Fail fast at eval time instead of shipping a widget that can only ever
    # show "-- W": a source is mandatory, and the wrap-range lists must be
    # parallel so the plugin can pair energy/max paths by index.
    assertions = [
      {
        assertion = cfg.raplEnergyPaths != [ ] || cfg.hwmonPath != null;
        message = ''
          aspects.home.noctalia.cpuPower.enable requires a package-power
          source: set raplEnergyPaths (+ parallel raplMaxPaths) or hwmonPath.
          Sensor paths are host data.
        '';
      }
      {
        assertion = lib.length cfg.raplMaxPaths == lib.length cfg.raplEnergyPaths;
        message = ''
          aspects.home.noctalia.cpuPower.raplMaxPaths must be parallel to
          raplEnergyPaths: got ${toString (lib.length cfg.raplMaxPaths)} max
          path(s) for ${toString (lib.length cfg.raplEnergyPaths)} energy
          path(s).
        '';
      }
    ];

    programs.noctalia.settings = {
      # Declaratively enable the plugin: [plugins] enabled = ["local/cpu-power"]
      # is the canonical gate per PluginsConfig::enabled. Without this the bar
      # references an unknown widget once noctalia.nix adds it to the capsule.
      plugins.enabled = [ "local/cpu-power" ];
    };

    # Local cpu-power plugin (explicit paths, no zenpower scan).
    # Deployed to ~/.local/share/noctalia/plugins/cpu-power/
    xdg.dataFile."noctalia/plugins/cpu-power/plugin.toml".text = ''
      id = "local/cpu-power"
      name = "CPU Power"
      version = "1.1.0"
      plugin_api = 27
      description = "CPU package power via explicit powercap/hwmon paths"

      [[widget]]
      id = "cpu_power"
      entry = "main.luau"

      [widget.actions]
      left = "panel-toggle control-center system"
    '';

    xdg.dataFile."noctalia/plugins/cpu-power/main.luau".text = ''
      -- local/cpu-power:cpu_power — package power via explicit paths
      -- RAPL: Δenergy/Δt on a pinned energy_uj source, wrap-corrected via
      -- the parallel max_energy_range_uj path.
      -- hwmon: single explicit power1_input path (microwatts -> watts).
      -- All sensor paths are injected from Nix host data; no blind scanning.
      --
      -- Robustness: the baseline resets when the resolved source changes;
      -- samples are dropped and re-baselined on wall-clock discontinuities
      -- (suspend, clock steps), unrecoverable counter wraps, and readings
      -- above MAX_WATTS (sanity gate, never clamped for display).

      local POLL_MS = ${toString cfg.pollIntervalMs}
      local MAX_WATTS = ${toString cfg.maxWatts}
      -- nowMs() is wall-clock: across suspend/resume or an NTP step the gap
      -- would otherwise average power over the whole discontinuity.
      local STALE_MS = math.max(4 * POLL_MS, 10000)

      noctalia.setUpdateInterval(POLL_MS)

      local energyPaths = {
      ${lib.concatMapStringsSep "\n" (p: "    \"${p}\",") cfg.raplEnergyPaths}
      }
      local maxPaths = {
      ${lib.concatMapStringsSep "\n" (p: "    \"${p}\",") cfg.raplMaxPaths}
      }
      local hwmonPath = ${if cfg.hwmonPath == null then "nil" else "\"${cfg.hwmonPath}\""}

      -- Sampling state: energy/time baseline + wrap range for the pinned source.
      local activeSource = nil
      local prevEnergy = nil
      local prevTime = nil
      local maxEnergy = nil

      local function trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
      end

      local function readNumber(path)
        local content = noctalia.readFile(path)
        if not content then return nil end
        return tonumber((trim(content)))
      end

      -- First readable counter wins; returns value, path, and its index so
      -- the parallel max-range list lines up.
      local function readEnergy()
        for i, p in ipairs(energyPaths) do
          local v = readNumber(p)
          if v then return v, p, i end
        end
        return nil
      end

      -- Wrap range for the pinned source: the parallel path first, then any
      -- readable one. May stay nil; wrap handling degrades to discarding.
      local function readMaxEnergy(idx)
        if maxPaths[idx] then
          local m = readNumber(maxPaths[idx])
          if m then return m end
        end
        for _, mp in ipairs(maxPaths) do
          local m = readNumber(mp)
          if m then return m end
        end
        return nil
      end

      local function resetBaseline()
        prevEnergy = nil
        prevTime = nil
        maxEnergy = nil
      end

      -- Tooltip mirrors the sibling sysmon widgets: own stat first, then
      -- whatever systemStats() offers (nil-safe: monitor disabled -> skip).
      local function show(watts, src)
        local text = string.format("%.1f W", watts)
        barWidget.setText(text)
        barWidget.setGlyph("${cfg.glyph}")

        local rows = { { key = "Package Power", value = text } }
        local stats = noctalia.systemStats()
        if stats then
          if stats.cpu and stats.cpu.usagePercent then
            rows[#rows + 1] = { key = "CPU", value = string.format("%.0f%%", stats.cpu.usagePercent) }
          end
          if stats.cpu and stats.cpu.tempC then
            rows[#rows + 1] = { key = "CPU Temp", value = string.format("%.0f°C", stats.cpu.tempC) }
          end
          if stats.ram and stats.ram.usedMb and stats.ram.totalMb and stats.ram.totalMb > 0 then
            rows[#rows + 1] = {
              key = "RAM",
              value = string.format("%.1f/%.0f GiB", stats.ram.usedMb / 1024, stats.ram.totalMb / 1024),
            }
          end
        end
        rows[#rows + 1] = { key = "Source", value = src }
        barWidget.setTooltip(rows)
      end

      local function unavailable(text, tip)
        barWidget.setText(text)
        barWidget.setGlyph("${cfg.glyph}")
        barWidget.setTooltip(tip)
      end

      function update()
        local now = noctalia.nowMs()
        local cur, src, idx = readEnergy()

        if cur then
          if src ~= activeSource then
            -- A different counter (permissions restored, sysfs re-enumerated):
            -- deltas across sources are meaningless.
            activeSource = src
            resetBaseline()
          end
          if maxEnergy == nil then
            maxEnergy = readMaxEnergy(idx)
          end

          if prevEnergy == nil or prevTime == nil then
            prevEnergy = cur
            prevTime = now
            unavailable("... W", "Sampling " .. src)
            return
          end

          local dt = now - prevTime
          if dt <= 0 or dt > STALE_MS then
            -- Clock step or suspend gap: keep the last reading, re-baseline.
            prevEnergy = cur
            prevTime = now
            return
          end

          local delta = cur - prevEnergy
          prevEnergy = cur
          prevTime = now
          if delta < 0 and maxEnergy then delta = delta + maxEnergy end
          if delta < 0 then
            -- Counter reset without a usable range: drop and re-baseline.
            maxEnergy = nil
            return
          end

          local watts = delta / dt / 1000
          if watts > MAX_WATTS then
            -- Implausible for package power: discard, keep the last reading.
            return
          end

          show(watts, src)
          return
        end

        -- RAPL unreadable: fall back to the explicit hwmon sensor.
        if activeSource ~= nil then
          activeSource = nil
          resetBaseline()
        end

        if hwmonPath then
          local uw = readNumber(hwmonPath)
          if uw and uw >= 0 and uw / 1e6 <= MAX_WATTS then
            show(uw / 1e6, hwmonPath)
            return
          end
        end

        unavailable("-- W", "No package power source")
      end

      barWidget.setText("... W")
      barWidget.setGlyph("${cfg.glyph}")
    '';

    # Ensure the shell restarts when the plugin source changes. The upstream
    # HM module already triggers on config.toml + palette json; we append the
    # plugin files so HM activation reliably reloads the new script.
    systemd.user.services.noctalia = {
      Unit.X-Restart-Triggers = [
        config.xdg.dataFile."noctalia/plugins/cpu-power/plugin.toml".source
        config.xdg.dataFile."noctalia/plugins/cpu-power/main.luau".source
      ];
    };
  };
}
