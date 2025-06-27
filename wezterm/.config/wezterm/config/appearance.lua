local gpu_adapters = require('utils.gpu-adapter')
local colors = require('colors.custom')
return {
  -- webgpu
  max_fps = 60,
  animation_fps = 60,
  webgpu_power_preference = 'HighPerformance',
  webgpu_preferred_adapter = gpu_adapters:pick_best(),
  underline_thickness = '1.5pt',
  colors = colors,
  -- 窗口
  initial_cols = 200,
  initial_rows = 50,
  text_background_opacity = .9,
  window_background_opacity = .75,
  window_decorations = "RESIZE",
  -- 关闭窗口不提示
  window_close_confirmation = 'NeverPrompt',
  window_frame = {
    active_titlebar_bg = '#090909',
    -- font = fonts.font,
    -- font_size = fonts.font_size,
  },
  inactive_pane_hsb = {
    saturation = 1,
    brightness = 1,
  },
  --tab_bar
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = false,
  tab_max_width = 25,
  show_tab_index_in_tab_bar = false,
  switch_to_last_active_tab_when_closing_tab = true,

  -- 光标
  cursor_blink_ease_in = 'EaseOut',
  cursor_blink_ease_out = 'EaseOut',
  default_cursor_style = 'BlinkingBlock',
  cursor_blink_rate = 650,

  -- bell
  visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 250,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 250,
    target = 'CursorColor',
  },
}
