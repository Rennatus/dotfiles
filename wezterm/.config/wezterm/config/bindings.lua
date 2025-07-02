local wezterm = require('wezterm')
local platform = require('utils.platform')
local act = wezterm.action
local mod = {}

local timeout = { key = 3000, leader = 1000 }

if platform.is_mac then
   mod.SUPER = 'SUPER'
--mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   -- mod.SUPER_REV = 'ALT|CTRL'
end

local leader = { key = 'b', mods = mod.SUPER, timeout_milliseconds = timeout.leader }

local keys = {
   -- misc/useful --
   { key = 'F10', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F9', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F8', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   {
      key = 'F7',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
   },
   { key = 'F6', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },

   { key = 'p', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },
   { key = 'y', mods = mod.SUPER, action = act.CopyTo('Clipboard') },

   { key = 'q', mods = 'LEADER', action = act.QuitApplication },
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 't', mods = 'LEADER', action = act.ShowLauncherArgs({ flags = 'TABS' }) }, --table列表
   {
      key = 'u',
      mods = 'LEADER',
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+',
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },

   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentPane({ confirm = true }) }, -- 关闭面板
   { key = [[\]], mods = mod.SUPER, action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
   { key = [[\]], mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },

   -- tabs: navigation
   { key = '[', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
   { key = ']', mods = mod.SUPER, action = act.ActivateTabRelative(1) },

   -- window: zoom window
   {
      key = '-',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width - 50
         local new_height = dimensions.pixel_height - 50
         window:set_inner_size(new_width, new_height)
      end),
   },
   {
      key = '=',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width + 50
         local new_height = dimensions.pixel_height + 50
         window:set_inner_size(new_width, new_height)
      end),
   },

   -- panes: navigationH
   { key = 'k', mods = mod.SUPER, action = act.ActivatePaneDirection('Up') },
   { key = 'j', mods = mod.SUPER, action = act.ActivatePaneDirection('Down') },
   { key = 'h', mods = mod.SUPER, action = act.ActivatePaneDirection('Left') },
   { key = 'l', mods = mod.SUPER, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   { key = 'u', mods = 'CTRL', action = act.ScrollByLine(-5) },
   { key = 'd', mods = 'CTRL', action = act.ScrollByLine(5) },
   { key = 'PageUp', mods = 'NONE', action = act.ScrollByPage(-0.75) },
   { key = 'PageDown', mods = 'NONE', action = act.ScrollByPage(0.75) },
   { key = 'End', mods = 'NONE', action = act.ScrollToBottom },
   { key = 'Home', mods = 'NONE', action = act.ScrollToTop },

   { key = '/', mods = 'LEADER', action = act.Search({ CaseInSensitiveString = '' }) }, --搜索
   -- resizes fonts
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- resize panes
   {
      key = 'p',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
}

local key_tables = {
   resize_font = {
      { key = 'k', action = act.IncreaseFontSize },
      { key = 'j', action = act.DecreaseFontSize },
      { key = 'r', action = act.ResetFontSize },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q', action = 'PopKeyTable' },
   },

   resize_pane = {
      { key = 'k', action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j', action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h', action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l', action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q', action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}
return {
   disable_default_key_bindings = true,
   keys = keys,
   leader = leader,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
