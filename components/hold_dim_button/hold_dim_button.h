#pragma once

#include <vector>
#include "esphome/core/component.h"
#include "esphome/components/binary_sensor/binary_sensor.h"
#include "esphome/components/light/light_state.h"

namespace esphome {
    namespace hold_dim_button {
        class HoldDimButton : public Component, public binary_sensor::BinarySensor {
         public:
          // Each light carries its own min brightness (the Python layer fills it
          // in from the per-light value or the button-level default).
          void add_light(light::LightState *light, float min_brightness) {
            this->lights_.push_back({light, clamp(min_brightness, 0.0f, 1.0f)});
          }

          void set_brightness(float b) { brightness_ = clamp(b, 0.0f, 1.0f); }
          void set_threshold(float t) { threshold_ = clamp(t, 0.0f, 1.0f); }
          void set_step(float s) { step_ = clamp(s, 0.001f, 1.0f); }
          void set_hold_delay_ms(uint32_t d) { hold_delay_ms_ = d; }
          void set_step_interval_ms(uint32_t i) { step_interval_ms_ = i; }
          void set_transition_ms(uint32_t t) { transition_ms_ = t; }
          void set_input(binary_sensor::BinarySensor *in) { this->input_ = in; }

          void setup() override;
          void loop() override;

         protected:
          struct LightEntry {
            light::LightState *light;
            float min_brightness;  // stop dimming this light below here
          };

          void on_press_();
          void on_release_();
          void on_click_();

          // Group helpers: the button acts on all its lights together.
          bool any_on_() const;              // is at least one light on?
          void turn_on_all_at_min_();        // turn each light on at its own min (used when starting from OFF)
          // One dim step across the group: each on-light moves by `step` toward
          // its own min (down) or max (up), clamped at that limit. Lights that have
          // already hit the limit are left untouched. Returns true if any light
          // moved, so the hold keeps dimming until the last light reaches its limit.
          bool dim_step_(bool down);
          void turn_off_all_();
          void turn_on_all_(float b);

          bool raw_state_{false};
          bool last_raw_state_{false};

          uint32_t press_started_ms_{0};
          bool pressed_{false};
          bool hold_mode_{false};

          enum Direction { DIM_DOWN, DIM_UP };
          Direction dir_{DIM_DOWN};
          Direction step_dir_{DIM_UP};

          std::vector<LightEntry> lights_;
          binary_sensor::BinarySensor *input_{nullptr};

          // Params
          float brightness_;
          float threshold_;
          float step_;
          uint32_t hold_delay_ms_;
          uint32_t step_interval_ms_;
          uint32_t transition_ms_;

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
