#pragma once

#include <vector>
#include "esphome/core/component.h"
#include "esphome/components/binary_sensor/binary_sensor.h"
#include "esphome/components/light/light_state.h"
#include "esphome/components/time/real_time_clock.h"
#include "esphome/components/dim_light_base/dim_light_base.h"

namespace esphome {
    namespace hold_dim_button {
        // Click-vs-hold semantics for one binary_sensor driving one or more lights.
        //
        // Works with any light platform: it only ever sets brightness on a
        // light::LightState, and makes no assumption about how a fixture realises
        // that brightness. A per-fixture floor is the light's own business (see
        // dim_light_base), which is why `dim_floor` below is a single uniform value
        // rather than a per-light one. A fixture may also publish its own night
        // level there; one that does not falls back to `night_brightness` here.
        class HoldDimButton : public Component, public binary_sensor::BinarySensor {
         public:
          void add_light(light::LightState *light) { this->lights_.push_back(light); }

          void set_brightness(float b) { brightness_ = clamp(b, 0.0f, 1.0f); }
          void set_dim_floor(float f) { dim_floor_ = clamp(f, 0.0f, 1.0f); }
          void set_step(float s) { step_ = clamp(s, 0.001f, 1.0f); }
          void set_hold_delay_ms(uint32_t d) { hold_delay_ms_ = d; }
          void set_step_interval_ms(uint32_t i) { step_interval_ms_ = i; }
          void set_transition_ms(uint32_t t) { transition_ms_ = t; }
          void set_input(binary_sensor::BinarySensor *in) { this->input_ = in; }

          // Setting a time source is what enables the night window; without one
          // every click uses `brightness`.
          void set_time(time::RealTimeClock *t) { this->time_ = t; }
          void set_night_brightness(float b) { night_brightness_ = clamp(b, 0.0f, 1.0f); }
          // Window as minutes since midnight; start > end means it wraps midnight.
          void set_night_window(uint16_t start_min, uint16_t end_min) {
            night_start_min_ = start_min;
            night_end_min_ = end_min;
          }

          void setup() override;
          void loop() override;

         protected:
          void on_press_();
          void on_release_();
          void on_click_();

          // Group helpers: the button acts on all its lights together.
          bool any_on_() const;              // is at least one light on?
          bool all_on_() const;              // are all lights on?
          void turn_off_all_();
          void turn_on_all_(float b);
          // Night turn-on: each light gets the level it published, or this
          // button's `night_brightness` if it published none. Per-light rather
          // than one shared value, so a group button can turn a fixture with a
          // high floor on dimmer than the rest of its group.
          void turn_on_all_at_night_();
          // One dim step across the group: each on-light moves by `step` between
          // `dim_floor` and full, clamped at those limits. Lights that have already
          // hit the limit are left untouched. Returns true if any light moved, so
          // the hold keeps dimming until the last light reaches its limit.
          bool dim_step_(bool down);

          // Is the clock inside the night window? False when no time source is
          // configured or the clock has not synced yet (HA may not be up right
          // after a reboot) -- better one bright turn-on than dimming at noon.
          bool is_night_() const;

          bool raw_state_{false};
          bool last_raw_state_{false};

          uint32_t press_started_ms_{0};
          bool pressed_{false};
          bool hold_mode_{false};

          enum Direction { DIM_DOWN, DIM_UP };
          Direction dir_{DIM_DOWN};
          Direction step_dir_{DIM_UP};

          std::vector<light::LightState *> lights_;
          binary_sensor::BinarySensor *input_{nullptr};
          time::RealTimeClock *time_{nullptr};

          // Params. `dim_floor` is the lowest brightness a hold will dim to; it
          // exists so dimming down cannot reach 0 and switch the light off, not as
          // a per-fixture limit -- that one lives on the light.
          float brightness_;
          float night_brightness_{1.0f};
          float dim_floor_;
          float step_;
          uint32_t hold_delay_ms_;
          uint32_t step_interval_ms_;
          uint32_t transition_ms_;
          uint16_t night_start_min_{0};
          uint16_t night_end_min_{0};

          uint32_t last_step_ms_{0};

          static float clamp(float v, float lo, float hi) {
            if (v < lo) return lo;
            if (v > hi) return hi;
            return v;
          }

          static Direction opposite(Direction dir) {
            return (dir == DIM_DOWN) ? DIM_UP : DIM_DOWN;
          }
        };

    }
}
