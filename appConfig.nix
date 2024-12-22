{ config, ... }:
{
  config = {
    rendererdYaml =
      let
        yamlData = {
          name = config.appConfig.name;
        };
      in
      yamlData;
  };
}
