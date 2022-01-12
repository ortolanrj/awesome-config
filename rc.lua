-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
gears = require("gears")
awful = require("awful")
wibox = require("wibox")
beautiful = require("beautiful")
naughty = require("naughty")
menubar = require("menubar")
hotkeys_popup = require("awful.hotkeys_popup")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.autofocus")
require("awful.hotkeys_popup.keys")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
		naughty.notify({ preset = naughty.config.presets.critical, 
										 title = "Oops, there were errors during startup!", 
										 text = awesome.startup_errors })
end


-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function (err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
											title = "Oops, an error happened!",
											text = tostring(err) })
		in_error = false
	end)
end
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/ortolanrj/.config/awesome/theme.lua")
beautiful.get().wallpaper = "/home/ortolanrj/Pictures/wallpaper_abstract.png"

-- This is used later as the default terminal and editor to run.
terminal = "kitty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor


modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
		awful.layout.suit.spiral,
		awful.layout.suit.floating,
		awful.layout.suit.tile,
		awful.layout.suit.tile.left,
		awful.layout.suit.tile.bottom,
}
-- }}}

-- Create a launcher widget and a main menu
myawesomemenu = {
	 { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
	 { "manual", terminal .. " -e man awesome" },
	 { "edit config", editor_cmd .. " " .. awesome.conffile },
	 { "restart", awesome.restart },
	 { "quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
																		{ "open terminal", terminal }
																	}
												})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
																		 menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
										awful.button({ }, 1, function(t) t:view_only() end),
										awful.button({ modkey }, 1, function(t)
																							if client.focus then
																									client.focus:move_to_tag(t)
																							end
																					end),
										awful.button({ }, 3, awful.tag.viewtoggle),
										awful.button({ modkey }, 3, function(t)
																							if client.focus then
																									client.focus:toggle_tag(t)
																							end
																					end),
										awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
										awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
								)

local tasklist_buttons = gears.table.join(
		awful.button({ }, 1, function (c)
				if c == client.focus then
						c.minimized = true
				else
						c:emit_signal(
								"request::activate",
								"tasklist",
								{raise = true}
						)
				end
		end),
		awful.button({ }, 3, function() awful.menu.client_list({ theme = { width = 250 } }) end),
		awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
		awful.button({ }, 5, function () awful.client.focus.byidx(-1) end))

local function set_wallpaper(s)
		-- Wallpaper
		if beautiful.wallpaper then
				local wallpaper = beautiful.wallpaper
				-- If wallpaper is a function, call it with the screen
				if type(wallpaper) == "function" then
						wallpaper = wallpaper(s)
				end
				gears.wallpaper.maximized(wallpaper, s, true)
		end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
		-- Wallpaper
		set_wallpaper(s)

		-- Each screen has its own tag table.
		awful.tag({ "dev", "www", "tty", "game", "other" }, s, awful.layout.layouts[1])

		-- Create a promptbox for each screen
		s.mypromptbox = awful.widget.prompt()

		-- Create an imagebox widget which will contain an icon indicating which layout we're using.
		-- We need one layoutbox per screen.
		s.mylayoutbox = awful.widget.layoutbox(s)
		s.mylayoutbox:buttons(gears.table.join(
													 awful.button({ }, 1, function () awful.layout.inc( 1) end),
													 awful.button({ }, 3, function () awful.layout.inc(-1) end),
													 awful.button({ }, 4, function () awful.layout.inc( 1) end),
													 awful.button({ }, 5, function () awful.layout.inc(-1) end)))

		-- Create a taglist widget
		s.mytaglist = awful.widget.taglist {
				screen	= s,
				filter	= awful.widget.taglist.filter.all,
				buttons = taglist_buttons
		}

		-- Create a tasklist widget
		s.mytasklist = awful.widget.tasklist {
				screen	= s,
				filter	= awful.widget.tasklist.filter.currenttags,
				buttons = tasklist_buttons,
				style		 = {
						bg_normal = "#222222",
						bg_focus = "#555555",
						bg_minimize = "#222222",
						shape  = function(cr,w,h)
								wibox.container.margin(
								gears.shape.rounded_rect(cr,w,h,5),10,10,10,10)
						end,
				},
				layout	 = {
						spacing = 10,
						spacing_widget = {
								forced_width = 5,
								valign = 'center',
								halign = 'center',
								widget = wibox.container.place,
						},
						layout	= wibox.layout.flex.horizontal
				},
				widget_template = {
						{
								{
										{
												{
														id	= 'icon_role',
														widget = wibox.widget.imagebox,
												},
												right = 5,
												left = 3,
												widget	= wibox.container.margin,
										},
										layout = wibox.layout.fixed.horizontal,
								},
								margins = 2,
								widget = wibox.container.margin
						},
						id = 'background_role',
						bg = "#F00",
						widget = wibox.container.background
				
		}
		}

		-- Wibox Setup
		s.mywibox = awful.wibar({ position = "top", screen = s, height = 35 })
		s.mywibox:setup {
				layout = wibox.layout.align.horizontal,
				expand = "none",
				{ -- Left widgets
						layout = wibox.layout.fixed.horizontal,
						s.mytaglist,
						s.mypromptbox,
				},
				{
						s.mytasklist,
						top = 5,
						bottom = 5,
						widget = wibox.container.margin
				}, -- Middle widget
				{ -- Right widgets
						layout = wibox.layout.fixed.horizontal,
						mykeyboardlayout,
						mytextclock,
				},
		}
end)
-- }}}

require ("configuration.keys")

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
		-- All clients will match this rule.
		{ rule = { },
			properties = { border_width = beautiful.border_width,
										 border_color = beautiful.border_normal,
										 focus = awful.client.focus.filter,
										 raise = true,
										 keys = clientkeys,
										 buttons = clientbuttons,
										 screen = awful.screen.preferred,
										 placement = awful.placement.no_overlap+awful.placement.no_offscreen
		 }
		},

		-- Floating clients.
		{ rule_any = {
				instance = {
					"DTA",	-- Firefox addon DownThemAll.
					"copyq",	-- Includes session name in class.
					"pinentry",
				},
				class = {
					"Arandr",
					"Blueman-manager",
					"Gpick",
					"Kruler",
					"MessageWin",  -- kalarm.
					"Sxiv",
					"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
					"Wpa_gui",
					"veromix",
					"xtightvncviewer"},

				-- Note that the name property shown in xprop might be set slightly after creation of the client
				-- and the name shown there might not match defined rules here.
				name = {
					"Event Tester",  -- xev.
				},
				role = {
					"AlarmWindow",	-- Thunderbird's calendar.
					"ConfigManager",	-- Thunderbird's about:config.
					"pop-up",				-- e.g. Google Chrome's (detached) Developer Tools.
				}
			}, properties = { floating = true }},

		-- Add titlebars to normal clients and dialogs
		{ rule_any = {type = { "normal", "dialog" }
			}, properties = { titlebars_enabled = false }
		},

		-- Set Firefox to always map on the tag named "2" on screen 1.
		{ rule = { class = "Firefox" },
			 properties = { screen = 1, tag = "www" } },
}
-- }}}
	
-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
		-- Set the windows at the slave,
		-- i.e. put it at the end of others instead of setting it master.
		if not awesome.startup then awful.client.setslave(c) end

		if awesome.startup
			and not c.size_hints.user_position
			and not c.size_hints.program_position then
				-- Prevent clients from being unreachable after screen count changes.
				awful.placement.no_offscreen(c)
		end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
		-- buttons for the titlebar
		local buttons = gears.table.join(
				awful.button({ }, 1, function()
						c:emit_signal("request::activate", "titlebar", {raise = true})
						awful.mouse.client.move(c)
				end),
				awful.button({ }, 3, function()
						c:emit_signal("request::activate", "titlebar", {raise = true})
						awful.mouse.client.resize(c)
				end)
		)

		awful.titlebar(c) : setup {
				{ -- Left
						awful.titlebar.widget.iconwidget(c),
						buttons = buttons,
						layout	= wibox.layout.fixed.horizontal
				},
				{ -- Middle
						{ -- Title
								align  = "center",
								widget = awful.titlebar.widget.titlewidget(c)
						},
						buttons = buttons,
						layout	= wibox.layout.flex.horizontal
				},
				{ -- Right
						awful.titlebar.widget.floatingbutton (c),
						awful.titlebar.widget.maximizedbutton(c),
						awful.titlebar.widget.stickybutton	 (c),
						awful.titlebar.widget.ontopbutton		 (c),
						awful.titlebar.widget.closebutton		 (c),
						layout = wibox.layout.fixed.horizontal()
				},
				layout = wibox.layout.align.horizontal
		}
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
		c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Disable minimization of windows
client.connect_signal("property::minimized", function(c)
		c.minimized = false
end)
