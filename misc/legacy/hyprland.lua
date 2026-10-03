local active_border_color = "rgb(c0c0c0)"
local active_shadow_color = "rgb(d3d3d3)"
local inactive_border_color = "rgba(e5e5e5e5)"
local inactive_shadow_color = "rgba(b0b0b0b0)"
local active_border_gradient = {
  colors = {
    "rgb(c0c0c0)",
    "rgb(d3d3d3)",
    "rgb(e5e5e5)",
    "rgb(b0b0b0)",
  },
  angle = 45,
}

hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 6,
    border_size = 1,
    col = {
      active_border = active_border_gradient,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_gradient,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    rounding = 5,
    dim_inactive = true,
    dim_strength = 0.15,
    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 1,
      render_power = 1,
      color = active_shadow_color,
      color_inactive = inactive_shadow_color,
    },

    blur = {
      enabled = true,
      size = 4,
      passes = 3,
      contrast = 1.0,
      brightness = 0.9,
      vibrancy = 0.1,
      noise = 0.01,
      ignore_opacity = false,
      new_optimizations = true,
    },
  },
})

hl.config({
  animations = {
    enabled = false,
  },
})

hl.curve("mycurve", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "mycurve", style = "popin" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default", style = "slide" })

hl.layer_rule({
  name = "blur_with_ignore_alpha",
  match = { namespace = "^(walker|notifications|swayosd|waybar)$" },
  blur = true,
  ignore_alpha = 0.1,
})
