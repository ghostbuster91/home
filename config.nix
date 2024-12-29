let
  substitutions = {
    serial_prefix = "dim"; #Don't change it.
  };
in
{
  espConfig = {
    dimmer1 = {
      inherit substitutions;
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



      logger = { };
      ota = {
        platform = "esphome";
      };
      network = { };
      status_led = {
        pin = {
          number = "GPIO2";
          inverted = true;
        };
      };
    };
  };
}
