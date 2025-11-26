#pragma once

#include "esphome/core/component.h"
#include "esphome/components/binary_sensor/binary_sensor.h"
#include "esphome/components/light/light_state.h"

namespace esphome {
    namespace hold_dim_button {
        class HoldDimButton : public Component, public binary_sensor::BinarySensor {
         public:
          void set_light(light::LightState *light) { this->light_ = light; }

          void set_brightness(float b) { brightness_ = clamp(b, 0.0f, 1.0f); }
          void set_threshold(float t) { threshold_ = clamp(t, 0.0f, 1.0f); }
          void set_step(float s) { step_ = clamp(s, 0.001f, 1.0f); }
          void set_min_brightness(float m) { min_brightness_ = clamp(m, 0.0f, 1.0f); }
          void set_hold_delay_ms(uint32_t d) { hold_delay_ms_ = d; }
          void set_step_interval_ms(uint32_t i) { step_interval_ms_ = i; }
          void set_transition_ms(uint32_t t) { transition_ms_ = t; }
          void set_input(binary_sensor::BinarySensor *in) { this->input_ = in; }

          void setup() override;
          void loop() override;

         protected:
          void on_press_();
          void on_release_();
          void on_click_();

          bool raw_state_{false};
          bool last_raw_state_{false};

          uint32_t press_started_ms_{0};
          bool pressed_{false};
          bool hold_mode_{false};

          enum Direction { DIM_DOWN, DIM_UP };
          Direction dir_{DIM_DOWN};

          light::LightState *light_{nullptr};
          binary_sensor::BinarySensor *input_{nullptr};

          // Params 
          float brightness_;
          float threshold_;
          float step_;
          float min_brightness_;  // stop dimming below this
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

