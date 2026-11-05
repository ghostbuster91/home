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
  ESP_LOGW(TAG, "CONFIG: lights=%u step=%.3f dim_floor=%.3f initial=%.3f",
         (unsigned) lights_.size(), step_, dim_floor_, brightness_);
  if (this->time_ != nullptr) {
    ESP_LOGW(TAG, "CONFIG: night %02u:%02u-%02u:%02u -> click turns on at %.3f",
             night_start_min_ / 60, night_start_min_ % 60,
             night_end_min_ / 60, night_end_min_ % 60, night_brightness_);
  }

  input_->add_on_state_callback([this](bool state) {
    if (state) this->on_press_();
    else this->on_release_();
  });
}

bool HoldDimButton::is_night_() const {
  if (this->time_ == nullptr)
    return false;  // night window not configured

  auto now = this->time_->now();
  if (!now.is_valid()) {
    ESP_LOGW(TAG, "Clock not synced yet, treating as day");
    return false;
  }

  uint16_t mins = (uint16_t) now.hour * 60 + now.minute;
  if (night_start_min_ == night_end_min_)
    return false;  // empty window
  if (night_start_min_ < night_end_min_)
    return mins >= night_start_min_ && mins < night_end_min_;
  return mins >= night_start_min_ || mins < night_end_min_;  // wraps midnight
}

bool HoldDimButton::any_on_() const {
  for (auto *l : lights_) {
    if (l != nullptr && l->current_values.is_on())
      return true;
  }
  return false;
}

bool HoldDimButton::all_on_() const {
  for (auto *l : lights_) {
    if (l != nullptr && !l->current_values.is_on())
      return false;
  }
  return true;
}

bool HoldDimButton::dim_step_(bool down) {
  bool any_changed = false;
  for (auto *l : lights_) {
    if (l == nullptr || !l->current_values.is_on())
      continue;

    float b = l->current_values.get_brightness();
    float nb;
    if (down) {
      if (b <= dim_floor_)         // already at the floor, leave it there
        continue;
      nb = b - step_;
      if (nb < dim_floor_) nb = dim_floor_;
    } else {
      if (b >= 1.0f)               // already at max
        continue;
      nb = b + step_;
      if (nb > 1.0f) nb = 1.0f;
    }

    auto call = l->turn_on();
    call.set_transition_length(transition_ms_);
    call.set_brightness(clamp(nb, 0.0f, 1.0f));
    call.perform();
    any_changed = true;
  }
  return any_changed;
}

void HoldDimButton::turn_off_all_() {
  for (auto *l : lights_) {
    if (l == nullptr) continue;
    auto call = l->turn_off();
    call.perform();
  }
}

void HoldDimButton::turn_on_all_(float b) {
  for (auto *l : lights_) {
    if (l == nullptr) continue;
    auto call = l->turn_on();
    call.set_brightness(clamp(b, 0.0f, 1.0f));
    call.perform();
  }
}

void HoldDimButton::turn_on_all_at_night_() {
  for (auto *l : lights_) {
    if (l == nullptr) continue;
    float b = dim_light_base::night_brightness_for(l).value_or(night_brightness_);
    auto call = l->turn_on();
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
      // All lights off: start at the dim floor and dim up. Each fixture turns
      // that into its own lowest usable level.
      turn_on_all_(dim_floor_);

      dir_ = DIM_DOWN;  // next hold will reverse to DIM_UP
      step_dir_ = DIM_UP;
      ESP_LOGD(TAG, "Hold start from OFF: turning on at dim floor, direction=UP");
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

      // Step each light independently toward the shared limits. Lights that
      // already hit the floor/max are skipped, so dimming continues for the rest
      // until the last light reaches its limit too.
      bool changed = dim_step_(step_dir_ == DIM_DOWN);
      if (!changed) {
        ESP_LOGD(TAG, "All lights at %s", step_dir_ == DIM_DOWN ? "floor" : "max");
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

  // Group toggle: turning off only happens once the whole group is on. While any
  // light is still off a click instead brings the whole group to the click
  // brightness (the on ones included), so the group re-syncs on "all on" and only
  // the next click turns everything off.
  if (all_on_()) {
    turn_off_all_();
    ESP_LOGD(TAG, "Click -> all off");
  } else if (is_night_()) {
    turn_on_all_at_night_();
    ESP_LOGD(TAG, "Click -> all on (night)");

    // dir_ is the *previous* direction, which the next hold inverts: a night
    // turn-on sits low and must brighten, a day one sits high and must dim.
    dir_ = DIM_DOWN;
  } else {
    turn_on_all_(brightness_);
    ESP_LOGD(TAG, "Click -> all on %.2f", brightness_);
    dir_ = DIM_UP;
  }
}

}
}
