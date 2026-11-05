#pragma once

#include "esphome/core/component.h"
#include "esphome/components/output/float_output.h"
#include "esphome/components/dim_light_base/dim_light_base.h"

namespace esphome {
namespace monochromatic_dim {

// Fork of the upstream `monochromatic` platform: identical, except the level is
// lifted onto [min_brightness, 1] on its way to the output. A single channel
// could equally use the output's own min_power, but keeping it here means both
// forked platforms spell the limit the same way.
class MonochromaticDimLightOutput : public dim_light_base::DimLightBase {
 public:
  void set_output(output::FloatOutput *output) { output_ = output; }
  light::LightTraits get_traits() override {
    auto traits = light::LightTraits();
    traits.set_supported_color_modes({light::ColorMode::BRIGHTNESS});
    return traits;
  }
  void write_state(light::LightState *state) override {
    float bright;
    state->current_values_as_brightness(&bright);
    this->output_->set_level(this->apply_min_(bright, state->get_gamma_correct()));
  }

 protected:
  output::FloatOutput *output_;
};

}  // namespace monochromatic_dim
}  // namespace esphome
