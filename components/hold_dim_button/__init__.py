import esphome.codegen as cg
from esphome.components import binary_sensor, light, time as time_
import esphome.config_validation as cv
from esphome.const import CONF_BRIGHTNESS, CONF_ID, CONF_TIME_ID

CONF_INPUT = "input"
CONF_LIGHT_ID = "light_id"
CONF_NIGHT_BRIGHTNESS = "night_brightness"
CONF_NIGHT_START = "night_start"
CONF_NIGHT_END = "night_end"
CONF_DIM_FLOOR = "dim_floor"
CONF_STEP = "step"
CONF_HOLD_DELAY = "hold_delay"
CONF_STEP_INTERVAL = "step_interval"
CONF_TRANSITION = "transition"

# The header includes time/real_time_clock.h, so the time component's sources
# must be in the build even for a button that configures no night window.
DEPENDENCIES = ["time"]

# For the night-level lookup; no platform assumption comes with it.
AUTO_LOAD = ["dim_light_base"]

hold_dim_ns = cg.esphome_ns.namespace("hold_dim_button")
HoldDimButton = hold_dim_ns.class_("HoldDimButton", cg.Component)

SINGLE_SCHEMA = cv.Schema({
    cv.Required(CONF_ID): cv.declare_id(HoldDimButton),
    cv.Required(CONF_INPUT): cv.use_id(binary_sensor.BinarySensor),
    # A single id or a list; a list makes the button act on all lights as one
    # group. Any light platform will do -- the button only sets brightness.
    cv.Required(CONF_LIGHT_ID): cv.ensure_list(cv.use_id(light.LightState)),

    # Levels a click turns the group on at. The night window only applies when
    # `time_id` is given; it may wrap midnight (the default 20:00 -> 05:00 does).
    cv.Optional(CONF_BRIGHTNESS, default=1.0): cv.float_range(0.0, 1.0),
    # Fallback for lights that publish no night level of their own.
    cv.Optional(CONF_NIGHT_BRIGHTNESS, default=0.5): cv.float_range(0.0, 1.0),
    cv.Optional(CONF_TIME_ID): cv.use_id(time_.RealTimeClock),
    cv.Optional(CONF_NIGHT_START, default="20:30"): cv.time_of_day,
    cv.Optional(CONF_NIGHT_END, default="05:00"): cv.time_of_day,

    # Lowest brightness a hold will dim to. Only here to keep dimming down from
    # reaching 0 and switching the light off; the per-fixture floor belongs to the
    # light (see components/dim_light_base).
    cv.Optional(CONF_DIM_FLOOR, default=0.01): cv.float_range(0.0, 1.0),

    cv.Optional(CONF_STEP, default=0.05): cv.float_range(0.001, 1.0),
    cv.Optional(CONF_HOLD_DELAY, default="500ms"): cv.positive_time_period_milliseconds,
    cv.Optional(CONF_STEP_INTERVAL, default="100ms"): cv.positive_time_period_milliseconds,
    cv.Optional(CONF_TRANSITION, default="100ms"): cv.positive_time_period_milliseconds,
}).extend(cv.COMPONENT_SCHEMA)

CONFIG_SCHEMA = cv.ensure_list(SINGLE_SCHEMA)


def _minutes_of_day(tod):
    # cv.time_of_day yields {"hour": .., "minute": .., "second": ..}; seconds are
    # irrelevant for a window this coarse, so they're dropped.
    return tod["hour"] * 60 + tod["minute"]


async def to_code(config):
    for conf in config:
        var = cg.new_Pvariable(conf[CONF_ID])
        await cg.register_component(var, conf)

        inp = await cg.get_variable(conf[CONF_INPUT])
        cg.add(var.set_input(inp))

        for item in conf[CONF_LIGHT_ID]:
            l = await cg.get_variable(item)
            cg.add(var.add_light(l))

        cg.add(var.set_brightness(conf[CONF_BRIGHTNESS]))

        # No time_id -> time_ stays null, which is what disables the night window.
        if CONF_TIME_ID in conf:
            rtc = await cg.get_variable(conf[CONF_TIME_ID])
            cg.add(var.set_time(rtc))
            cg.add(var.set_night_brightness(conf[CONF_NIGHT_BRIGHTNESS]))
            cg.add(var.set_night_window(
                _minutes_of_day(conf[CONF_NIGHT_START]),
                _minutes_of_day(conf[CONF_NIGHT_END]),
            ))

        cg.add(var.set_dim_floor(conf[CONF_DIM_FLOOR]))
        cg.add(var.set_step(conf[CONF_STEP]))
        cg.add(var.set_hold_delay_ms(conf[CONF_HOLD_DELAY]))
        cg.add(var.set_step_interval_ms(conf[CONF_STEP_INTERVAL]))
        cg.add(var.set_transition_ms(conf[CONF_TRANSITION]))
