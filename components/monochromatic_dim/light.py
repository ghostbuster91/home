import esphome.codegen as cg
from esphome.components import light, output
from esphome.components.dim_light_base import (
    DIM_LIMITS_SCHEMA,
    DimLightBase,
    register_dim_limits,
)
import esphome.config_validation as cv
from esphome.const import CONF_OUTPUT, CONF_OUTPUT_ID

AUTO_LOAD = ["dim_light_base"]

monochromatic_dim_ns = cg.esphome_ns.namespace("monochromatic_dim")
MonochromaticDimLightOutput = monochromatic_dim_ns.class_(
    "MonochromaticDimLightOutput", DimLightBase
)

CONFIG_SCHEMA = light.BRIGHTNESS_ONLY_LIGHT_SCHEMA.extend(
    {
        cv.GenerateID(CONF_OUTPUT_ID): cv.declare_id(MonochromaticDimLightOutput),
        cv.Required(CONF_OUTPUT): cv.use_id(output.FloatOutput),
    }
).extend(DIM_LIMITS_SCHEMA)


async def to_code(config):
    var = cg.new_Pvariable(config[CONF_OUTPUT_ID])
    await light.register_light(var, config)

    out = await cg.get_variable(config[CONF_OUTPUT])
    cg.add(var.set_output(out))

    await register_dim_limits(var, config)
