#pragma once

#include "esphome/core/component.h"
#include "esphome/core/helpers.h"
#include "esphome/components/output/float_output.h"
#include "esphome/components/dim_light_base/dim_light_base.h"

namespace esphome {
namespace cwww_dim {

// Fork of the upstream `cwww` platform, adding the DimLightBase limits.
//
// The floor cannot be pushed down to the outputs' own min_power here: that would
// floor the cold and the warm channel independently, so at a warm colour
// temperature the cold channel -- which should sit at zero -- would be forced up,
// shifting the colour and roughly doubling the effective floor. Instead both
// channels are scaled by one shared factor derived from the brightness term they
// are both linear in, which lifts the floor and leaves the colour untouched.
class CWWWDimLightOutput : public dim_light_base::DimLightBase {
 public:
  void set_cold_white(output::FloatOutput *cold_white) { cold_white_ = cold_white; }
  void set_warm_white(output::FloatOutput *warm_white) { warm_white_ = warm_white; }
  void set_cold_white_temperature(float cold_white_temperature) {
    cold_white_temperature_ = cold_white_temperature;
  }
  void set_warm_white_temperature(float warm_white_temperature) {
    warm_white_temperature_ = warm_white_temperature;
  }
  void set_constant_brightness(bool constant_brightness) { constant_brightness_ = constant_brightness; }
  light::LightTraits get_traits() override {
    auto traits = light::LightTraits();
    traits.set_supported_color_modes({light::ColorMode::COLD_WARM_WHITE});
    traits.set_min_mireds(this->cold_white_temperature_);
    traits.set_max_mireds(this->warm_white_temperature_);
    return traits;
  }
  void write_state(light::LightState *state) override {
    float cwhite, wwhite;
    state->current_values_as_cwww(&cwhite, &wwhite, this->constant_brightness_);

    // Both channels come out of as_cwww() linear in this same gamma-corrected
    // brightness term, so one factor lifts both without changing their ratio.
    const float gamma = state->get_gamma_correct();
    const float level = gamma_correct(
        state->current_values.get_state() * state->current_values.get_brightness(), gamma);
    const float scale = this->min_scale_(level, gamma);

    this->cold_white_->set_level(cwhite * scale);
    this->warm_white_->set_level(wwhite * scale);
  }

 protected:
  output::FloatOutput *cold_white_;
  output::FloatOutput *warm_white_;
  float cold_white_temperature_{0};
  float warm_white_temperature_{0};
  bool constant_brightness_;
};

}  // namespace cwww_dim
}  // namespace esphome
