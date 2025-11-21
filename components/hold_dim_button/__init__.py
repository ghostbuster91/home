import esphome.codegen as cg
import esphome.config_validation as cv
from esphome.components import binary_sensor, light
from esphome.const import CONF_ID

CONF_INPUT = "input"
CONF_LIGHT_ID = "light_id"
CONF_BRIGHTNESS = "brightness"
CONF_THRESHOLD = "threshold"
CONF_STEP = "step"
CONF_MIN_BRIGHTNESS = "min_brightness"
CONF_HOLD_DELAY = "hold_delay"
CONF_STEP_INTERVAL = "step_interval"
CONF_TRANSITION = "transition"

hold_dim_ns = cg.esphome_ns.namespace("hold_dim_button")
HoldDimButton = hold_dim_ns.class_("HoldDimButton", cg.Component)

SINGLE_SCHEMA = cv.Schema({
    cv.Required(CONF_ID): cv.declare_id(HoldDimButton),
    cv.Required(CONF_INPUT): cv.use_id(binary_sensor.BinarySensor),
    cv.Required(CONF_LIGHT_ID): cv.use_id(light.LightState),

    cv.Optional(CONF_BRIGHTNESS, default=0.9): cv.float_range(0.0, 1.0),
    cv.Optional(CONF_THRESHOLD, default=0.5): cv.float_range(0.0, 1.0),
    cv.Optional(CONF_STEP, default=0.05): cv.float_range(0.001, 1.0),
    cv.Optional(CONF_MIN_BRIGHTNESS, default=0.4): cv.float_range(0.0, 1.0),
    cv.Optional(CONF_HOLD_DELAY, default="500ms"): cv.positive_time_period_milliseconds,
    cv.Optional(CONF_STEP_INTERVAL, default="100ms"): cv.positive_time_period_milliseconds,
    cv.Optional(CONF_TRANSITION, default="100ms"): cv.positive_time_period_milliseconds,
}).extend(cv.COMPONENT_SCHEMA)

CONFIG_SCHEMA = cv.ensure_list(SINGLE_SCHEMA)

async def to_code(config):
    for conf in config:
        var = cg.new_Pvariable(conf[CONF_ID])
        await cg.register_component(var, conf)

        inp = await cg.get_variable(conf[CONF_INPUT])
        l = await cg.get_variable(conf[CONF_LIGHT_ID])

        cg.add(var.set_input(inp))
        cg.add(var.set_light(l))

        cg.add(var.set_brightness(conf[CONF_BRIGHTNESS]))
        cg.add(var.set_threshold(conf[CONF_THRESHOLD]))
        cg.add(var.set_step(conf[CONF_STEP]))
        cg.add(var.set_min_brightness(conf[CONF_MIN_BRIGHTNESS]))
        cg.add(var.set_hold_delay_ms(conf[CONF_HOLD_DELAY]))
        cg.add(var.set_step_interval_ms(conf[CONF_STEP_INTERVAL]))
        cg.add(var.set_transition_ms(conf[CONF_TRANSITION]))

