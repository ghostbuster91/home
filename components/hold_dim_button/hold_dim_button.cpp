#include "hold_dim_button.h"
#include "esphome/core/log.h"

namespace esphome {
namespace hold_dim_button {

static const char *const TAG = "hold_dim_button";

void HoldDimButton::setup() {
  if (light_ == nullptr || input_ == nullptr) {
    ESP_LOGE(TAG, "input and light_id are required!");
    return;
  }
  ESP_LOGW(TAG, "CONFIG: min=%.3f step=%.3f thresh=%.3f initial=%.3f",
         min_brightness_, step_, threshold_, brightness_);

  input_->add_on_state_callback([this](bool state) {
    if (state) this->on_press_();
    else this->on_release_();
  });
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

    bool is_on = light_ && light_->current_values.is_on();

    if (!is_on) {
      // Light is off, we start from min_brightness_ and dimm up
      auto call = light_->turn_on();
      call.set_transition_length(transition_ms_);
      call.set_brightness(clamp(min_brightness_, 0.0f, 1.0f));
      call.perform();

      dir_ = DIM_UP;  // first hold from OFF always UP
      ESP_LOGD(TAG, "Hold start from OFF: turning on at min=%.3f, direction=UP", min_brightness_);
      last_step_ms_ = now + 2 * step_interval_ms_; // skip next 2 steps
    } else {
      // Light is on
      float b = light_->current_values.get_brightness();
      ESP_LOGD(TAG, "Hold start, direction: %s", dir_ == DIM_DOWN ? "DOWN" : "UP");
      last_step_ms_ = 0;  // force first step immediately
      dir_ = opposite(dir_);
    }
  }

  // while in "hold" mode: execute steps with step_interval_ms_
  if (local_hold) {
    if (last_step_ms_ == 0 || (now - last_step_ms_) >= step_interval_ms_) {
      last_step_ms_ = now;

      if (!light_ || !light_->current_values.is_on())
        return;

      float b = light_->current_values.get_brightness();

      // dimming down
      if (dir_ == DIM_DOWN) {
        if (b - step_ <= min_brightness_) {
          ESP_LOGD(TAG, "At min brightness: %.3f", b);
          return;
        }

        ESP_LOGD(TAG, "Dimming down: %.3f", b);
        auto call = light_->turn_on();
        call.set_transition_length(transition_ms_);
        call.set_brightness(clamp(b - step_, 0.0f, 1.0f));
        call.perform();
      }

      // dimming up
      else {
        if (b >= 1.0f) {
          ESP_LOGD(TAG, "At max brightness: %.3f", b);
          return;
        }

        ESP_LOGD(TAG, "Dimming up: %.3f", b);
        auto call = light_->turn_on();
        call.set_transition_length(transition_ms_);
        call.set_brightness(clamp(b + step_, 0.0f, 1.0f));
        call.perform();
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
  if (light_ == nullptr) return;

  if (!light_->current_values.is_on()) {
    auto call = light_->turn_on();
    call.set_brightness(brightness_);
    call.perform();
    ESP_LOGD(TAG, "Click -> turn on %.2f", brightness_);

    // After turning on with a click the first hold needs to always dimm down
    dir_ = DIM_UP; 
  } else {
    auto call = light_->turn_off();
    call.perform();
    ESP_LOGD(TAG, "Click -> turn off");
  }
}

} 
} 


