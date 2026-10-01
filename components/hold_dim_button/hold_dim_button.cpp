#include "hold_dim_button.h"
#include "esphome/core/log.h"

namespace esphome {
namespace hold_dim_button {

static const char *const TAG = "hold_dim_button";

void HoldDimButton::setup() {
  if (lights_.empty() || input_ == nullptr) {
    ESP_LOGE(TAG, "input and at least one light_id are required!");
    return;
  }
  ESP_LOGW(TAG, "CONFIG: lights=%u step=%.3f thresh=%.3f initial=%.3f",
         (unsigned) lights_.size(), step_, threshold_, brightness_);

  input_->add_on_state_callback([this](bool state) {
    if (state) this->on_press_();
    else this->on_release_();
  });
}

bool HoldDimButton::any_on_() const {
  for (auto &e : lights_) {
    if (e.light != nullptr && e.light->current_values.is_on())
      return true;
  }
  return false;
}

bool HoldDimButton::dim_step_(bool down) {
  bool any_changed = false;
  for (auto &e : lights_) {
    if (e.light == nullptr || !e.light->current_values.is_on())
      continue;

    float b = e.light->current_values.get_brightness();
    float lo = e.min_brightness;
    float nb;
    if (down) {
      if (b <= lo)                 // already at its own min, leave it there
        continue;
      nb = b - step_;
      if (nb < lo) nb = lo;
    } else {
      if (b >= 1.0f)               // already at max
        continue;
      nb = b + step_;
      if (nb > 1.0f) nb = 1.0f;
    }

    auto call = e.light->turn_on();
    call.set_transition_length(transition_ms_);
    call.set_brightness(clamp(nb, 0.0f, 1.0f));
    call.perform();
    any_changed = true;
  }
  return any_changed;
}

void HoldDimButton::turn_on_all_at_min_() {
  for (auto &e : lights_) {
    if (e.light == nullptr) continue;
    auto call = e.light->turn_on();
    call.set_transition_length(transition_ms_);
    call.set_brightness(clamp(e.min_brightness, 0.0f, 1.0f));
    call.perform();
  }
}

void HoldDimButton::turn_off_all_() {
  for (auto &e : lights_) {
    if (e.light == nullptr) continue;
    auto call = e.light->turn_off();
    call.perform();
  }
}

void HoldDimButton::turn_on_all_(float b) {
  for (auto &e : lights_) {
    if (e.light == nullptr) continue;
    auto call = e.light->turn_on();
    call.set_brightness(clamp(b, 0.0f, 1.0f));
    call.perform();
  }
}

void HoldDimButton::loop() {
  if (!this->pressed_) {
    return;
  }

  uint32_t now = millis();
  bool local_hold = hold_mode_;

  // should we enter "hold" mode?
  if (!local_hold && (now - press_started_ms_) >= hold_delay_ms_) {
    hold_mode_ = true;
    local_hold = true;

    bool is_on = any_on_();

    if (!is_on) {
      // All lights off: start each at its own min and dim up
      turn_on_all_at_min_();

      dir_ = DIM_DOWN;  // next hold will reverse to DIM_UP
      step_dir_ = DIM_UP;
      ESP_LOGD(TAG, "Hold start from OFF: turning on at per-light min, direction=UP");
      last_step_ms_ = now + 2 * step_interval_ms_; // skip next 2 steps
    } else {
      // At least one light on
      dir_ = opposite(dir_);
      step_dir_ = dir_;
      ESP_LOGD(TAG, "Hold start, direction: %s", step_dir_ == DIM_DOWN ? "DOWN" : "UP");
      last_step_ms_ = 0;  // force first step immediately
    }
  }

  // while in "hold" mode: execute steps with step_interval_ms_
  if (local_hold) {
    if (last_step_ms_ == 0 || (int32_t)(now - last_step_ms_) >= (int32_t)step_interval_ms_) {
      last_step_ms_ = now;

      if (!any_on_())
        return;

      // Step each light independently toward its own limit. Lights that already
      // hit min/max are skipped, so dimming continues for the rest until the last
      // light reaches its limit too.
      bool changed = dim_step_(step_dir_ == DIM_DOWN);
      if (!changed) {
        ESP_LOGD(TAG, "All lights at %s", step_dir_ == DIM_DOWN ? "min" : "max");
      }
    }
  }
}


void HoldDimButton::on_press_() {
  pressed_ = true;
  hold_mode_ = false;
  press_started_ms_ = millis();
}

void HoldDimButton::on_release_() {
  bool was_hold = hold_mode_;
  pressed_ = false;
  hold_mode_ = false;

  if (!was_hold) {
    on_click_();
  }
}

void HoldDimButton::on_click_() {
  if (lights_.empty()) return;

  // Group toggle: if any light is on, turn them all off; otherwise turn them all on.
  if (any_on_()) {
    turn_off_all_();
    ESP_LOGD(TAG, "Click -> all off");
  } else {
    turn_on_all_(brightness_);
    ESP_LOGD(TAG, "Click -> all on %.2f", brightness_);

    // After turning on with a click the first hold needs to always dim down
    dir_ = DIM_UP;
  }
}

}
}
