# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

ESPHome configurations for a home installation built on boneIO hardware: one 24-channel switch board (`boneio-24-sw-07-737d50.yaml`) and seven 8-channel LED dimmers (`dimmer-1.yaml` … `dimmer-7.yaml`). Each top-level YAML compiles to firmware for one physical device. Friendly names and labels are in Polish — preserve them when editing.

## Dev environment

The Nix flake (`flake.nix`) is the source of truth for tooling: `esphome`, `gcc`, `clang-tools` (clangd), `python3`, and `treefmt` (with `nixpkgs-fmt` + `prettier`). Use direnv (`.envrc` is `use flake`) or `nix develop` to get a shell.

## Common commands

```bash
esphome config  <device>.yaml      # validate + render merged config
esphome compile <device>.yaml      # build firmware locally
esphome run     <device>.yaml      # build, upload (OTA), and tail logs
esphome logs    <device>.yaml      # tail logs only
treefmt                            # format YAML/Nix
```

CI (`.github/workflows/main.yml`) only builds `boneio-24-sw-07-737d50.yaml` and pins `ESPHOME_VERSION: 2024.6.6` — keep changes compatible with that version. The seven dimmer configs are not built in CI; verify them locally with `esphome config`.

## Architecture

**External package layering.** Each device YAML imports YAML packages from upstream repos rather than redefining hardware:

- `github://boneIO-eu/esphome` ref `v1.7.1` — board, I²C, PCF, INA219, LM75, display, output packages. Bumping this ref is a breaking change across every device file.
- `github://boneIO-eu/esphome_packages` ref `4c88a2ca9a76f9e483d5f79333ee5437395712b1` (pinned commit) — `sdm120m.yaml` / `sdm630.yaml`, instantiated once per energy meter with `vars:` overriding `device_name`, `modbus_device_id`, `modbus_device_address`. All meters share `modbus_id: boneio_modbus` (defined in the switch-board config). Each meter address must be unique on the RS-485 bus.

**Cross-device messaging.** Devices talk over UDP via ESPHome's `packet_transport` (`udp:` + `packet_transport:`), authenticated with per-device keys in `secrets.yaml`. Pattern: device A exposes a `binary_sensor` (or sensor) under its `packet_transport` block; device B declares a `binary_sensor` with `platform: packet_transport`, `provider: <device-A-name>`, and `remote_id: <id-on-A>`. Example: the switch board listens for `in_08` from `boneio-dr-8ch-03-4023d4` (dimmer-5) to toggle the bathroom heating mat thermostat. `rolling_code_enable: false` everywhere — re-enabling it has caused a desync bug (see commit `ebe1460`).

**Custom external component `hold_dim_button`.** Lives in `components/hold_dim_button/` and is loaded by every dimmer via `external_components: - source: { type: local, path: ./components }`. Implements click-vs-hold semantics for a single binary_sensor driving one or more lights. `light_id` accepts either a single id or a list; a list makes the button act on all lights as one group:

- Short press toggles the light(s). With a list it's a group toggle that re-syncs before it turns off: if _all_ lights are on, they all turn off; otherwise every light in the group is set to the configured default `brightness` — including the ones already on, so they snap back to the default too. So from a partially-on group the first click brings the whole group to the default and the next one turns everything off. (A single light is just the one-element case: on ↔ off.)
- Holding past `hold_delay` enters dim mode and steps brightness by `step` every `step_interval`. Each new hold reverses direction. Holding from OFF turns on at `min_brightness` and dims up. With a list, all lights dim together, driven from the brightest member so they re-sync.
- **Night window.** When `time_id` is set, a click inside the `night_start`…`night_end` window turns the group on at `night_brightness` (default `0.3`) instead of `brightness`. The window may wrap midnight; the default is `20:00`→`05:00`. Evaluated at click time from the clock, so there is no "ESP booted at 22:00 and thinks it's day" state — but the clock comes from Home Assistant, so until it syncs after a reboot the day brightness applies. Omitting `time_id` disables night mode entirely. Only clicks are affected: holding from OFF still starts at `min_brightness`, and turning a light on from HA/web/app bypasses the component completely.
- Python schema in `__init__.py` defines the YAML config; C++ runtime in `hold_dim_button.{h,cpp}`. When changing the schema, update both sides and re-run `esphome config <dimmer>.yaml`. `DEPENDENCIES = ["time"]` — the header includes `time/real_time_clock.h`, so every dimmer using the component must declare a `time:` platform.

**Night-mode YAML wiring.** Each dimmer defines the night parameters once as a top-level anchor `.night_mode: &night_mode` (ESPHome ignores top-level keys starting with a dot) and every `hold_dim_button` entry merges it with `<<: *night_mode`. Entries that already carry a local anchor use the merge-list form `<<: [*night_mode, *light_f]`, or nest both under a block `<<:` where the local anchor is defined. Merge precedence: explicit keys in the entry beat any merged key, and earlier anchors in a merge list beat later ones — so to override a night parameter for one button, set it directly on that entry.

**Light topology.** Dimmer boards expose ESPHome `light` entities (`monochromatic` or `cwww`) wired to PCA9685 outputs (`chl01`..`chr04`) declared in the upstream `boards/dimmer_output.yaml`. `hold_dim_button` entries target these `light_*` IDs by id.

**Water valves.** The four motorised water valves (kitchen/bathroom × hot/cold) are not raw relay switches: `valves/water_valve.yaml` is instantiated once per valve from `packages:` and turns two relay outputs into one `valve` entity. The hardware rule is the valve's own: voltage on red + green opens, voltage on red alone closes, no voltage leaves it where it is. The relays stay latched in the commanded combination (the valve's limit switches cut the motor), and `restore_mode: RESTORE_AND_CALL` re-drives them after a reboot. The two output switches are `internal: true` so nothing can energise green without red. Feedback cores exist on the valves (white + blue shorted = closed, yellow + orange = open) but are not wired to the board yet.

**Wall-switch binary_sensor naming.** Every `binary_sensor` on a dimmer/switch board carries a `name` of the form `"<switch>.<group> (NNN)"`, e.g. `"3.1 (213)"`. The number in parentheses encodes the wiring:

- The **first two digits** identify the cable (przewód), the **third digit** identifies the core (żyła) within that cable. So `213` = cable 21, core 3; `418` = cable 41, core 8.
- Cores are always the same four: **3 = white-green, 4 = green, 7 = white-brown, 8 = brown**. Each physical wall switch gathers exactly one cable's cores 3/4/7/8.
- Buttons are always wired the same way physically: **full colors on top, half (white-X) colors on the bottom, green on the left**:

  ```
                TOP (full colors)
     ┌──────────────────┬──────────────────┐
     │  green (…4)       │  brown (…8)       │
     ├──────────────────┼──────────────────┤
     │  white-green (…3) │  white-brown (…7) │
     └──────────────────┴──────────────────┘
               BOTTOM (half colors)
  ```

  So for cable 21 the four buttons are: top-left `214`, top-right `218`, bottom-left `213`, bottom-right `217`. Preserve this scheme when adding or relabeling inputs.

## Secrets

`secrets.yaml` contains per-device `packet_transport` encryption keys. It is committed (this is a private repo for a home install); do not move keys out of it without coordinating, since every YAML references them by `!secret`.
