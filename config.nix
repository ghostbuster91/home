{
  espConfig =
    let
      light = {
        u = "light_U";
        is_on = id: { "light.is_on" = id; };
        is_off = id: { "light.is_off" = id; };
        turn_on = id: {
          "light.turn_on" = id;
        };
        turn_off = id: {
          "light.turn_off" = id;
        };
      };
      channel = {
        "02" = "chl02";
      };
      mkIf = conf: {
        "if" =
          {
            condition = conf.cond;
            "then" = conf.then_;
          };
      };
      if_on_then_off = id: (mkIf { cond = light.is_on id; then_ = light.turn_off id; });
      if_off_then_on = id: (mkIf { cond = light.is_off id; then_ = light.turn_on id; });
      mkOnClick = action: { "then" = action; };
    in
    {
      dimmer1 = {
        substitutions = {
          serial_prefix = "dim"; #Don't change it.
        };
        esphome = {
          name = "boneio-dr-8ch-03-4023d4";
          friendly_name = "BoneIO Dimmer LED 4023d4";
          name_add_mac_suffix = false;
          project = {
            name = "boneio.dimmer-led";
            version = "0.3";
          };
        };

        esp32 = {
          board = "esp32dev";
        };
        external_components = [{
          #Original source and thank you note for BTomala https://github.com/boneIO-eu/esphome-lm75
          source = "github://boneIO-eu/esphome-LM75@main";
          components = [ "lm75" ];
        }];

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

        ethernet = {
          id = "eth";
          type = "LAN8720";
          mdc_pin = "GPIO23";
          mdio_pin = "GPIO18";
          clk_mode = "GPIO0_IN";
          phy_addr = 1;
          power_pin = "GPIO16";
        };

        dashboard_import = {
          package_import_url = "github://boneIO-eu/esphome/boneio-dimmer_8ch-v0_3.yaml@latest";
          import_full_config = true;
        };

        pcf8574 = [{
          id = "pcf_inputs";
          address = "0x38";
        }];

        logger = { };
        api = {
          reboot_timeout = "0s";
        };
        ota = {
          platform = "esphome";
        };
        web_server = {
          port = 80;
          local = true;
        };

        text_sensor = [
          {
            platform = "version";
            name = "boneio-dimmer- Version";
            icon = "mdi:cube-outline";
            entity_category = "diagnostic";
          }
          {
            platform = "ethernet_info";
            ip_address = {
              entity_category = "diagnostic";
              name = "boneio-dimmer IP";
            };
          }
          {
            platform = "template";
            name = "Hostname";
            id = "hostname";
            entity_category = "diagnostic";
            lambda = ''
              return id(eth).get_use_address();
            '';
            update_interval = "5min";
          }
        ];
        globals =
          let
            mkBoolean = name: {
              id = name;
              type = "bool";
              restore_value = "yes";
              initial_value = "true";
            };
          in
          [
            (mkBoolean "lastDirection_W")
            (mkBoolean "lastDirection_U")
            (mkBoolean "lastDirection_P")
            (mkBoolean "lastDirection_T")
            (mkBoolean "lastDirection_X")
          ];
        binary_sensor = [
          {
            platform = "gpio";
            id = "in_01";
            name = "Switch 11.2-TL";
            pin = {
              pcf8574 = "pcf_inputs";
              number = 1;
              mode = {
                input = true;
              };
              inverted = true;
            };
            on_click =
              mkOnClick [
                (if_on_then_off light.u)
                (if_off_then_on light.u)
              ];
          }
        ];

        light = [{
          platform = "monochromatic";
          output = channel."02";
          name = "Light U (lodowka)";
          id = light.u;
          default_transition_length = "0.5s";
          gamma_correct = 0;
          restore_mode = "RESTORE_DEFAULT_OFF";
        }];

        output = [{
          platform = "ledc";
          pin = 32;
          frequency = "1000Hz";
          inverted = false;
          id = channel."02";
        }];
      };
    };
}
