{
  uci = {
    ephome = {
      name = "my_esp_device";
      platform = "ESP8266";
      board = "esp01_1m";
    };

    logger = { };
    ota = { };
    status_led = {
      pin = {
        number = "GPIO2";
        inverted = true;
      };
    };
  };
}
