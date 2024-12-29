{
  espConfig = {
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
    };
  };
}
