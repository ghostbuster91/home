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
        get_brightness = id: "id(${id}).current_values.get_brightness()";
      };
      channel = {
        "02" = "chl02";
      };
      binary_sensor = {
        in_01 = "in_01";
        is_on = id: { "binary_sensor.is_on" = id; };
      };
      switch =
        {
          buzzer = "buzzer";
          turn_on = id: {
            "switch.turn_on" = id;
          };
          turn_off = id: {
            "switch.turn_off" = id;
          };
        };
      mkIf = conf: {
        "if" =
          {
            condition = conf.cond;
            "then" = conf.then_;
            "else" = conf.else_ or null;
          };
      };
      mkWhile = conf: {
        while = {
          condition = conf.cond;
          "then" = conf.then_;
        };
      };
      if_on_then_off = id: (mkIf { cond = light.is_on id; then_ = light.turn_off id; });
      if_off_then_on = id: (mkIf { cond = light.is_off id; then_ = light.turn_on id; });
      mkOnClick = action: { "then" = action; };
      actions = {
        delay = time: { delay = time; };
      };
      lambda = {
        gt = first: second: { lambda = "return ${first} > ${second}"; };
        lt = first: second: { lambda = "return ${first} < ${second}"; };
      };
    in
    {
      dimmer1 =
        let
          mkVar = id: {
            inherit id;
            setUp = { lambda = "id(${id}) = true;"; };
            setDown = { lambda = "id(${id}) = false;"; };
            isUp = { lambda = "return id(${id}) == true;"; };
            isDown = { lambda = "return id(${id}) == false;"; };
          };
          globals = {
            nextDirection_W = mkVar "nextDirection_W";
            nextDirection_U = mkVar "nextDirection_U";
            nextDirection_P = mkVar "nextDirection_P";
            nextDirection_T = mkVar "nextDirection_T";
            nextDirection_X = mkVar "nextDirection_X";
          };
        in
        {
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
              (mkBoolean globals.nextDirection_W.id)
              (mkBoolean globals.nextDirection_U.id)
              (mkBoolean globals.nextDirection_P.id)
              (mkBoolean globals.nextDirection_T.id)
              (mkBoolean globals.nextDirection_X.id)
            ];
          binary_sensor = [
            {
              platform = "gpio";
              id = binary_sensor.in_01;
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

              on_press = {
                "then" = [
                  (mkIf {
                    cond = {
                      or = [
                        (light.is_off light.u)
                        {
                          and = [
                            globals.nextDirection_U.isUp
                            (lambda.lt (light.get_brightness light.u) "1")
                          ];
                        }
                      ];
                    };
                    then_ = [
                      (actions.delay "0.5s")
                      {
                        while = {
                          condition = binary_sensor.is_on binary_sensor.in_01;
                          "then" = [
                            globals.nextDirection_U.setDown
                            {
                              "light.dim_relative" = {
                                id = light.u;
                                relative_brightness = "5%";
                                transition_length = "0.1s";

                              };
                            }
                            (actions.delay "0.1s")
                          ];
                        };
                      }
                    ];
                    "else" = [
                      (actions.delay "0.5s")
                      (mkWhile {
                        cond = {
                          and = [
                            (binary_sensor.is_on binary_sensor.in_01)
                            (light.is_on light.u)
                            (lambda.gt (light.get_brightness light.u) "0.2")
                          ];
                        };
                        then_ = [
                          globals.nextDirection_U.setUp
                          {
                            "logger.log" =
                              {
                                format = "Current brightness %.1f";
                                args = [ (light.get_brightness light.u) ];
                              };
                          }
                          {
                            "light.dim_relative" =
                              {
                                id = light.u;
                                relative_brightness = "-5%";
                                transition_length = "0.1s";
                              };
                          }
                          (actions.delay "0.1s")
                        ];
                      })
                    ];
                  })
                ];
              };
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

          sensor = [{
            platform = "lm75";
            id = "boneIO_temp";
            name = "Temperature";
            update_interval = "30s";
            entity_category = "diagnostic";
            on_value_range = [
              {
                above = 70.0;
                "then" = switch.turn_on switch.buzzer;
              }
              {
                below = 70.0;
                "then" = switch.turn_off switch.buzzer;
              }
            ];
          }];

          switch = [{
            platform = "gpio";
            id = switch.buzzer;
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
    };
}
