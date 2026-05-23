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

**Custom external component `hold_dim_button`.** Lives in `components/hold_dim_button/` and is loaded by every dimmer via `external_components: - source: { type: local, path: ./components }`. Implements click-vs-hold semantics for a single binary_sensor driving a single light:
- Short press toggles the light at the configured default `brightness`.
- Holding past `hold_delay` enters dim mode and steps brightness by `step` every `step_interval`. Each new hold reverses direction. Holding from OFF turns on at `min_brightness` and dims up.
- Python schema in `__init__.py` defines the YAML config; C++ runtime in `hold_dim_button.{h,cpp}`. When changing the schema, update both sides and re-run `esphome config <dimmer>.yaml`.

**Light topology.** Dimmer boards expose ESPHome `light` entities (`monochromatic` or `cwww`) wired to PCA9685 outputs (`chl01`..`chr04`) declared in the upstream `boards/dimmer_output.yaml`. `hold_dim_button` entries target these `light_*` IDs by id.

## Secrets

`secrets.yaml` contains per-device `packet_transport` encryption keys. It is committed (this is a private repo for a home install); do not move keys out of it without coordinating, since every YAML references them by `!secret`.
