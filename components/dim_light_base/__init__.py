"""Shared per-fixture dimming data for the forked light platforms.

Code-only component: it contributes no configuration of its own, just the
DimLightBase class plus the one schema key and the codegen the two forks
(monochromatic_dim, cwww_dim) share.
"""

import esphome.codegen as cg
from esphome.components import light
import esphome.config_validation as cv

CONF_MIN_BRIGHTNESS = "min_brightness"
CONF_NIGHT_BRIGHTNESS = "night_brightness"

dim_light_base_ns = cg.esphome_ns.namespace("dim_light_base")
DimLightBase = dim_light_base_ns.class_("DimLightBase", light.LightOutput)

# Keys the forks add on top of their upstream schema. The min_brightness default
# matches the floor the dimmers have always used; night_brightness has no default
# on purpose -- unset means "whatever drives this light decides", so only fixtures
# that genuinely need a different night level say so.
DIM_LIMITS_SCHEMA = cv.Schema({
    cv.Optional(CONF_MIN_BRIGHTNESS, default=0.3): cv.float_range(0.0, 1.0),
    cv.Optional(CONF_NIGHT_BRIGHTNESS): cv.float_range(0.0, 1.0),
})


async def register_dim_limits(var, config):
    """Apply the shared DimLightBase setters. Call from each fork's to_code."""
    cg.add(var.set_min_brightness(config[CONF_MIN_BRIGHTNESS]))
    if (night := config.get(CONF_NIGHT_BRIGHTNESS)) is not None:
        cg.add(var.set_night_brightness(night))
