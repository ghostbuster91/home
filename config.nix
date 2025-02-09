{ espLib, ... }:
let
  mkBoneioDimmer = espLib.boneio-dr-8ch;
  inherit (espLib.helpers) light mkAction log;
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
    in
    {
      dimmer1 =
        mkBoneioDimmer {
          name = "boneio-dr-8ch-03-32ce68";
          friendly_name = "dimmer-1-hall";

          logger = { };
          api = {
            reboot_timeout = "0s";
          };

          binarySensors = {
            in_01 = self:
              let
                conf = { light = lights.u; };
              in
              {
                name = "Switch 11.2-TL";

                on_click = mkAction [
                  (light.toggle { id = conf.light; })
                ];

                on_press = mkAction
                  [
                    (log.brightness { id = conf.light; })
                    (light.dimm { light_id = conf.light; bsensor = self; })
                  ];
              };
          };

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

        };
    };
}
