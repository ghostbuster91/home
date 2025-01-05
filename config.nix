{ pkgs, espLib, ... }:
let
  mkBoneioDimmer = espLib.boneio-dr-8ch-03-4023d;
  inherit (espLib.helpers) light lambda actions mkOnClick mkIf if_on_then_off if_off_then_on switch binary_sensor;
in
{
  espConfig =
    let
      lights = {
        u = "light_U";
      };
      channels = {
        "02" = "chl02";
      };
      binary_sensors = {
        in_01 = "in_01";
      };
      switches =
        {
          buzzer = "buzzer";
        };
      decreaseBrightnessWhileHeld = conf: {
        while = {
          condition = {
            and = [
              (binary_sensor.is_on conf.binary_sensor)
              (light.is_on conf.light)
              (lambda.gt (light.get_brightness conf.light) "0.2")
            ];
          };
          "then" = [
            conf.var.setUp
            {
              "logger.log" =
                {
                  format = "Current brightness %.1f";
                  args = [ (light.get_brightness conf.light) ];
                };
            }
            {
              "light.dim_relative" =
                {
                  id = conf.light;
                  relative_brightness = "-5%";
                  transition_length = "0.1s";
                };
            }
            (actions.delay "0.1s")
          ];
        };
      };
      increseBrightnessWhileHeld = conf: {
        while = {
          condition = binary_sensor.is_on conf.binary_sensor;
          "then" = [
            conf.var.setDown
            {
              "light.dim_relative" = {
                id = conf.light;
                relative_brightness = "5%";
                transition_length = "0.1s";

              };
            }
            (actions.delay "0.1s")
          ];
        };
      };
      shouldIncreaseBrightness = conf: {
        or = [
          (light.is_off conf.light)
          {
            and = [
              conf.var.isUp
              (lambda.lt (light.get_brightness conf.light) "1")
            ];
          }
        ];
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
        mkBoneioDimmer {
          name = "boneio-dr-8ch-03-4023d4";
          friendly_name = "BoneIO Dimmer LED 4023d4";

          logger = { };
          api = {
            reboot_timeout = "0s";
          };

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
              id = binary_sensors.in_01;
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
                  (if_on_then_off lights.u)
                  (if_off_then_on lights.u)
                ];

              on_press = {
                "then" = [
                  (mkIf {
                    cond = shouldIncreaseBrightness {
                      light = lights.u;
                      var = globals.nextDirection_U;
                    };
                    then_ = [
                      (actions.delay "0.5s")
                      (increseBrightnessWhileHeld {
                        light = lights.u;
                        var = globals.nextDirection_U;
                        binary_sensor = binary_sensors.in_01;
                      })
                    ];
                    else_ = [
                      (actions.delay "0.5s")
                      (decreaseBrightnessWhileHeld {
                        light = lights.u;
                        var = globals.nextDirection_U;
                        binary_sensor = binary_sensors.in_01;
                      })
                    ];
                  })
                ];
              };
            }
          ];

          light = [{
            platform = "monochromatic";
            output = channels."02";
            name = "Light U (lodowka)";
            id = lights.u;
            default_transition_length = "0.5s";
            gamma_correct = 0;
            restore_mode = "RESTORE_DEFAULT_OFF";
          }];

          output = [{
            platform = "ledc";
            pin = 32;
            frequency = "1000Hz";
            inverted = false;
            id = channels."02";
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
                "then" = switch.turn_on switches.buzzer;
              }
              {
                below = 70.0;
                "then" = switch.turn_off switches.buzzer;
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
    };
}
