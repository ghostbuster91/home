#pragma once

#include "esphome/core/helpers.h"
#include "esphome/core/optional.h"
#include "esphome/components/light/light_output.h"
#include "esphome/components/light/light_state.h"

namespace esphome {
namespace dim_light_base {

// Per-fixture night level, published by a forked platform for whatever drives the
// light to read back.
//
// A lookup rather than a cast on LightState::get_output(): ESP-IDF builds with
// -fno-rtti (CONFIG_COMPILER_CXX_RTTI unset), so such a cast would have to be
// unchecked, and it would force every caller to know which platforms are forked.
// Here a light that publishes nothing simply has no entry, and the caller falls
// back to its own default -- so a driver works with any light platform.
void publish_night_brightness(light::LightState *state, float brightness);
optional<float> night_brightness_for(light::LightState *state);

// A light output that knows the lowest level its fixture still renders usefully.
//
// This is a hardware property, so it lives on the light and is enforced in the
// forked platforms' write_state(): it binds *every* control path -- Home
// Assistant, the web server, automations -- not just the wall button. Levels are
// lifted onto [floor, 1] rather than clamped, so a 1..100% slider stays
// meaningful and 0 still means off.
//
// A fixture may also carry a `night_brightness`, but note the difference: that
// one cannot be *enforced* here, because a light output cannot tell a default
// turn-on from someone deliberately asking for 100%. So it is published for
// whatever drives the light to look up, not applied -- see
// publish_night_brightness() below. Deciding *when* it applies stays policy, and
// policy lives in hold_dim_button.
class DimLightBase : public light::LightOutput {
 public:
  void set_min_brightness(float b) { min_brightness_ = clamp(b, 0.0f, 1.0f); }
  float get_min_brightness() const { return min_brightness_; }

  // Optional: leave unset and whatever drives the light uses its own night level.
  void set_night_brightness(float b) { night_brightness_ = clamp(b, 0.0f, 1.0f); }

  // LightState hands us itself once, which is the only chance to key the
  // published level by the object drivers actually hold.
  void setup_state(light::LightState *state) override {
    if (night_brightness_ >= 0.0f)
      publish_night_brightness(state, night_brightness_);
  }

 protected:
  // Lift `level` onto [floor, 1]; 0 stays 0 so the light can still go off.
  //
  // `level` is an output level, i.e. already gamma-corrected, while
  // min_brightness is written in brightness space -- so the floor has to go
  // through the same gamma to land where the configured number says. At gamma 2.8
  // a min_brightness of 0.3 is a floor of 0.3^2.8 ~= 0.033 of full duty, which is
  // what that number has always meant here.
  float apply_min_(float level, float gamma) const {
    if (level <= 0.0f || min_brightness_ <= 0.0f)
      return level;
    const float floor_level = gamma_correct(min_brightness_, gamma);
    return level * (1.0f - floor_level) + floor_level;
  }

  // Same lift expressed as a factor, for outputs that have to scale several
  // channels by the same amount to keep their ratio (and so their colour) intact.
  float min_scale_(float level, float gamma) const {
    if (level <= 0.0f || min_brightness_ <= 0.0f)
      return 1.0f;
    return this->apply_min_(level, gamma) / level;
  }

  float min_brightness_{0.0f};
  float night_brightness_{-1.0f};  // < 0 -> nothing published
};

}  // namespace dim_light_base
}  // namespace esphome
