{ lib, ... }:
let
  inherit (lib.lists) sublist imap1;
  inherit (lib.attrsets) mapAttrsToList;
in
rec {
  textSensor = {
    versionReporter = {
      platform = "version";
      name = "boneio-dimmer- Version";
      icon = "mdi:cube-outline";
      entity_category = "diagnostic";
    };
    ethReporter =
      {
        platform = "ethernet_info";
        ip_address = {
          entity_category = "diagnostic";
          name = "boneio-dimmer IP";
        };
      };
    hostnameReporter = {
      platform = "template";
      name = "Hostname";
      id = "hostname";
      entity_category = "diagnostic";
      lambda = ''
        return id(eth).get_use_address();
      '';
      update_interval = "5min";
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


  mkGpio = { id, pin }: {
    platform = "gpio";
    inherit id pin;
  };

  mkPinPcf8574 = { number, inverted ? true }: {
    pcf8574 = "pcf_inputs";
    inherit number;
    mode = {
      input = true;
    };
    inherit inverted;
  };

  mkPin = { number, inverted ? true }: {
    inherit number;
    mode = {
      input = true;
    };
    inherit inverted;
  };

  mkBinarySensors = { items }:
    builtins.concatLists [
      (imap1
        (i: item: (mkGpio {
          inherit (item) id; pin = mkPinPcf8574 { number = i; };
        }) // item.conf)
        (sublist 0 4 (mapAttrsToList (key: fKey: { id = key; conf = fKey key; }) items)))

      (imap1
        (i: item: (mkGpio {
          inherit (item) id; pin = mkPin { number = i; };
        }) // item.conf)
        (sublist 4 4 (mapAttrsToList (key: fkey: { id = key; conf = fkey key; }) items)))
    ];

}
