{
  uci.settings = {
    # The block below will translate to the following uci settings:
    # root@OpenWrt:~# uci show dropbear
    #dropbear.@dropbear[0]=dropbear
    #dropbear.@dropbear[0].Interface='lan'
    #dropbear.@dropbear[0].PasswordAuth='off'
    #dropbear.@dropbear[0].Port='22'
    dropbear.dropbear = [
      {
        # each section needs a type, denoted by `_type`
        _type = "dropbear";
        # those are normal config options
        PasswordAuth = "off";
        Port = "22";
        GatewayPorts = "1";
        Interface = "lan";
      }
      {
        # each section needs a type, denoted by `_type`
        _type = "dropbear";
        # those are normal config options
        PasswordAuth = "off";
        Port = "22";
        GatewayPorts = "1";
        Interface = "vpn";
      }
    ];
    };
}
