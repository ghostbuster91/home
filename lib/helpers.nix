_: rec {
  mkIf = conf: {
    "if" =
      {
        condition = conf.cond;
        "then" = conf.then_;
        "else" = conf.else_ or null;
      };
  };
  mkAction = action: { "then" = action; };
  actions = {
    delay = time: { delay = time; };
  };
  lambda = {
    gt = first: second: { lambda = "return ${builtins.toString first} > ${builtins.toString second}"; };
    gte = first: second: { lambda = "return ${builtins.toString first} >= ${builtins.toString second}"; };
    lt = first: second: { lambda = "return ${builtins.toString first} < ${builtins.toString second}"; };
    lte = first: second: { lambda = "return ${builtins.toString first} <= ${builtins.toString second}"; };
  };
  light = {
    is_on = { id }: { "light.is_on" = id; };
    is_off = { id }: { "light.is_off" = id; };
    turn_on = { id, brightness }: {
      "light.turn_on" = {
        inherit id brightness;
      };
    };
    turn_off = { id }: {
      "light.turn_off" = {
        inherit id;
      };
    };
    get_brightness = { id }: "id(${id}).current_values.get_brightness()";
    toggle = { id, brightness ? 1.0 }: (mkIf {
      cond = light.is_off { inherit id; };
      then_ = light.turn_on { inherit id brightness; };
      else_ = light.turn_off { inherit id; };
    });
    dimm = { light_id, bsensor }:
      (mkIf {
        cond = {
          or = [
            (light.is_off { id = light_id; })
            (lambda.gt (light.get_brightness { id = light_id; }) 0.5)
          ];
        };
        then_ = [
          (actions.delay "0.5s")
          {
            while = {
              condition = {
                and = [
                  (binary_sensor.is_on { id = bsensor; })
                  (lambda.gt (light.get_brightness { id = light_id; }) 0.2)
                  (light.is_on { id = light_id; })
                ];
              };
              "then" = [
                (log.brightness { id = light_id; })
                {
                  "light.dim_relative" = {
                    id = light_id;
                    relative_brightness = "-5%";
                    transition_length = "0.1s";

                  };
                }
                (actions.delay "0.1s")
              ];
            };
          }
        ];
        else_ = [
          (actions.delay "0.5s")
          {
            while = {
              condition = {
                and = [
                  (binary_sensor.is_on { id = bsensor; })
                  (lambda.lt (light.get_brightness { id = light_id; }) 1.0)
                  (light.is_on { id = light_id; })
                ];
              };
              "then" = [
                (log.brightness { id = light_id; })
                {
                  "light.dim_relative" = {
                    id = light_id;
                    relative_brightness = "5%";
                    transition_length = "0.1s";

                  };
                }
                (actions.delay "0.1s")
              ];
            };
          }
        ];
      })
    ;
  };

  log = {
    brightness = { id }: {
      "logger.log" =
        {
          format = "Current brightness %.1f";
          args = [ (light.get_brightness { inherit id; }) ];
        };
    };
  };

  binary_sensor = {
    is_on = { id }: { "binary_sensor.is_on" = id; };
  };
  switch =
    {
      turn_on = { id }: {
        "switch.turn_on" = id;
      };
      turn_off = { id }: {
        "switch.turn_off" = id;
      };
    };
}
