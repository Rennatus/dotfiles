local gpu_adapters = require('utils.gpu-adapter')
local backdrops = require('utils.backdrops')
local colors = require('colors.custom')

return {
   -- Graphics
   max_fps = 120,
   animation_fps = 120,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = gpu_adapters:pick_best(),
   -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
   -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),
   underline_thickness = '1.5pt',

   -- cursor
   cursor_blink_ease_in = 'EaseOut',
   cursor_blink_ease_out = 'EaseOut',
   cursor_blink_rate = 650,
   default_cursor_style = 'BlinkingBlock',

   -- color scheme
   colors = colors,

   -- background
   -- background = backdrops:initial_options(false), -- set to true if you want wezterm to start on focus mode

   -- scrollbar
   enable_scroll_bar = false,
   scrollback_lines = 10000,
   alternate_buffer_wheel_scroll_speed = 5,

   -- Tab
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = false,
   show_new_tab_button_in_tab_bar = false,
   show_tab_index_in_tab_bar = true,
   use_fancy_tab_bar = false,
   tab_max_width = 25,
   status_update_interval = 1000,

   -- window
   initial_cols = 200,
   initial_rows = 50,

   foreground_text_hsb = {
      brightness = 1.0,
      hue        = 1.0,
      saturation = 1.0,
   },

   text_background_opacity = 0.9,
   window_background_opacity = 0.9,
   window_decorations = "RESIZE",
   window_padding = {
      left = 3,
      right = 3,
      top = 10,
      bottom = 7.5,
   },
   adjust_window_size_when_changing_font_size = false,
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      -- font = fonts.font,
      -- font_size = fonts.font_size,
   },
   -- inactive_pane_hsb = {
   --    saturation = 0.9,
   --    brightness = 0.65,
   -- },
   inactive_pane_hsb = {
      saturation = 1,
      brightness = 1,
   },

   visual_bell = {
      fade_in_function = 'EaseIn',
      fade_in_duration_ms = 250,
      fade_out_function = 'EaseOut',
      fade_out_duration_ms = 250,
      target = 'CursorColor',
   },
}
