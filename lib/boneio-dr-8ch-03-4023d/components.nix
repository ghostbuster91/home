_: {
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
}
