{ pkgs, ... }:
let
  components = pkgs.callPackage ./components.nix { };
  genericComponents = pkgs.callPackage ../components.nix { };
  helpers = pkgs.callPackage ../helpers.nix { };
  inherit (helpers) switch;
  switches =
    {
      buzzer = "buzzer";
    };
  mkBoneIOdr8ch = { name, friendly_name, logger, api, binarySensors, light, output }: {
    substitutions = {
      serial_prefix = "dim"; #Don't change it.
    };
    esphome = {
      inherit name friendly_name;
      name_add_mac_suffix = false;
      project = {
        name = "boneio.dimmer-led";
        version = "0.3";
      };
    };
    esp32 = {
      board = "esp32dev";
    };
    external_components = with genericComponents; [
      externalComponents.lm75
    ];
    packages = {
      internals_packages = {
        url = "https://github.com/boneIO-eu/esphome";
        ref = "v1.1.0";
        files = [
          "devices/serial_no.yaml"
          "devices/dimmer_i2c.yaml"
          "devices/dimmer_ina219.yaml"
        ];
      };
    };

    inherit (components) ethernet;

    dashboard_import = {
      package_import_url = "github://boneIO-eu/esphome/boneio-dimmer_8ch-v0_3.yaml@latest";
      import_full_config = true;
    };

    pcf8574 = [{
      id = "pcf_inputs";
      address = "0x38";
    }];

    text_sensor = with components; [
      textSensor.versionReporter
      textSensor.ethReporter
      textSensor.hostnameReporter
    ];
    ota = {
      platform = "esphome";
    };
    web_server = {
      port = 80;
      local = true;
    };

    inherit logger api;

    inherit light output;

    binary_sensor = components.mkBinarySensors { items = binarySensors; };

    sensor = [{
      platform = "lm75";
      id = "boneIO_temp";
      name = "Temperature";
      update_interval = "30s";
      entity_category = "diagnostic";
      on_value_range = [
        {
          above = 70.0;
          "then" = switch.turn_on { id = switches.buzzer; };
        }
        {
          below = 70.0;
          "then" = switch.turn_off { id = switches.buzzer; };
        }
      ];
    }];

    switch = [{
      platform = "gpio";
      id = switches.buzzer;
      name = "Buzzer";
      pin = {
        pcf8574 = "pcf_inputs";
        number = 0;
        mode = {
          output = true;
        };
        inverted = true;
      };
    }];
  };
in
mkBoneIOdr8ch

