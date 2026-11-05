#include "dim_light_base.h"
#include <utility>
#include <vector>

namespace esphome {
namespace dim_light_base {

namespace {
// A handful of entries per device (21 across the whole installation, at most 8
// per board), so a flat vector with a linear scan beats a map on both code size
// and lookup cost. Function-local static to dodge static init order entirely.
std::vector<std::pair<light::LightState *, float>> &registry() {
  static std::vector<std::pair<light::LightState *, float>> reg;
  return reg;
}
}  // namespace

void publish_night_brightness(light::LightState *state, float brightness) {
  for (auto &entry : registry()) {
    if (entry.first == state) {
      entry.second = brightness;
      return;
    }
  }
  registry().emplace_back(state, brightness);
}

optional<float> night_brightness_for(light::LightState *state) {
  for (auto &entry : registry()) {
    if (entry.first == state)
      return entry.second;
  }
  return {};
}

}  // namespace dim_light_base
}  // namespace esphome
