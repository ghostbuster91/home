{ pkgs, ... }:
let
  mkBoneioDimmer = pkgs.callPackage ./lib/boneio-dr-8ch-03-4023d { };
in
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
                    cond = shouldIncreaseBrightness {
                      light = light.u;
                      var = globals.nextDirection_U;
                    };
                    then_ = [
                      (actions.delay "0.5s")
                      (increseBrightnessWhileHeld {
                        light = light.u;
                        var = globals.nextDirection_U;
                        binary_sensor = binary_sensor.in_01;
                      })
                    ];
                    else_ = [
                      (actions.delay "0.5s")
                      (decreaseBrightnessWhileHeld {
                        light = light.u;
                        var = globals.nextDirection_U;
                        binary_sensor = binary_sensor.in_01;
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
