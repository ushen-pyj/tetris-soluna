-- 开始界面UI模块
local renderer = require "src.ui.renderer"
local colors = require "src.core.colors"
local quad = require "soluna.material.quad"

local M = {}

local function render_button(batch, x, y, width, height, text, text_size, bg_color, border_color, text_color)
    batch:add(quad.quad(width, height, bg_color), x, y)
    batch:add(quad.quad(width, 2, border_color), x, y)
    batch:add(quad.quad(width, 2, border_color), x, y + height - 2)
    batch:add(quad.quad(2, height, border_color), x, y)
    batch:add(quad.quad(2, height, border_color), x + width - 2, y)
    
    local text_width = #text * text_size * 0.6
    local text_x = math.floor(x + width / 2 - text_width / 2)
    local text_y = y + math.floor((height - text_size) / 2) + 2
    renderer.render_text(batch, text, text_x, text_y, text_size, text_color, width, height)
end

function M.render(batch, screen_width, screen_height)
    batch:layer(0, 0)
    
    local center_x = math.floor(screen_width / 2)
    local center_y = math.floor(screen_height / 2)
    
    local title = "TETRIS"
    local title_size = 24
    local title_width = #title * title_size * 0.6
    local title_x = math.floor(center_x - title_width / 2)
    local title_y = center_y - 100
    renderer.render_text(batch, title, title_x, title_y, title_size, colors.TITLE_TEXT, screen_width, screen_height)
    
    local button_width = 160
    local button_height = 40
    local button_spacing = 20
    
    local single_button_x = math.floor(center_x - button_width / 2)
    local single_button_y = center_y - 30
    render_button(batch, single_button_x, single_button_y, button_width, button_height, 
                  "SINGLE PLAYER", 14, colors.BUTTON_BACKGROUND, colors.BUTTON_TEXT, colors.BUTTON_BORDER)
    
    local dual_button_x = math.floor(center_x - button_width / 2)
    local dual_button_y = single_button_y + button_height + button_spacing
    render_button(batch, dual_button_x, dual_button_y, button_width, button_height, 
                  "DUAL PLAYER", 14, colors.BUTTON_BACKGROUND, colors.BUTTON_TEXT, colors.BUTTON_BORDER)
    
    local controls_y = center_y + 80
    local control_size = 11
    
    renderer.render_text(batch, "SINGLE PLAYER CONTROLS:", center_x - 80, controls_y, control_size, colors.CONTROL_HINT, screen_width, screen_height)
    renderer.render_text(batch, "A/D - Move Left/Right", center_x - 80, controls_y + 15, control_size, colors.CONTROL_TEXT, screen_width, screen_height)
    renderer.render_text(batch, "S - Soft Drop", center_x - 50, controls_y + 30, control_size, colors.CONTROL_TEXT, screen_width, screen_height)
    renderer.render_text(batch, "W - Rotate", center_x - 40, controls_y + 45, control_size, colors.CONTROL_TEXT, screen_width, screen_height)
    renderer.render_text(batch, "SPACE - Hard Drop", center_x - 60, controls_y + 60, control_size, colors.CONTROL_TEXT, screen_width, screen_height)
    
    renderer.render_text(batch, "DUAL PLAYER CONTROLS:", center_x - 75, controls_y + 85, control_size, colors.CONTROL_HINT, screen_width, screen_height)
    renderer.render_text(batch, "1P: WASD + SPACE  |  2P: 4826 + ENTER", center_x - 100, controls_y + 100, control_size, colors.CONTROL_TEXT, screen_width, screen_height)
    
    local hint_text = "Click a button to select game mode!"
    local hint_size = 12
    local hint_width = #hint_text * hint_size * 0.6
    local hint_x = math.floor(center_x - hint_width / 2)
    local hint_y = center_y + 220
    renderer.render_text(batch, hint_text, hint_x, hint_y, hint_size, colors.CLICK_HINT, screen_width, screen_height)
    
    batch:layer()
end

function M.is_single_button_clicked(mouse_x, mouse_y, screen_width, screen_height)
    -- 检查参数有效性
    if not mouse_x or not mouse_y or not screen_width or not screen_height then
        return false
    end
    
    local center_x = screen_width / 2
    local center_y = screen_height / 2
    local button_width = 160
    local button_height = 40
    local button_x = center_x - button_width / 2
    local button_y = center_y - 30
    
    return mouse_x >= button_x and mouse_x <= button_x + button_width and
           mouse_y >= button_y and mouse_y <= button_y + button_height
end

function M.is_dual_button_clicked(mouse_x, mouse_y, screen_width, screen_height)
    -- 检查参数有效性
    if not mouse_x or not mouse_y or not screen_width or not screen_height then
        return false
    end
    
    local center_x = screen_width / 2
    local center_y = screen_height / 2
    local button_width = 160
    local button_height = 40
    local button_spacing = 20
    local button_x = center_x - button_width / 2
    local button_y = center_y - 30 + button_height + button_spacing
    
    return mouse_x >= button_x and mouse_x <= button_x + button_width and
           mouse_y >= button_y and mouse_y <= button_y + button_height
end

return M
