_: rec {
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
  light = {
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

  binary_sensor = {
    is_on = id: { "binary_sensor.is_on" = id; };
  };
  switch =
    {
      turn_on = id: {
        "switch.turn_on" = id;
      };
      turn_off = id: {
        "switch.turn_off" = id;
      };
    };
}
