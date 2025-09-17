-- 开始界面UI模块
local renderer = require "src.ui.renderer"
local constants = require "src.core.constants"

local M = {}

-- 渲染开始界面
function M.render(batch, screen_width, screen_height)
    batch:layer(0, 0)
    
    -- 计算中心位置
    local center_x = math.floor(screen_width / 2)
    local center_y = math.floor(screen_height / 2)
    
    -- 渲染游戏标题
    local title = "TETRIS"
    local title_size = 24
    local title_width = #title * title_size * 0.6
    local title_x = math.floor(center_x - title_width / 2)
    local title_y = center_y - 80
    renderer.render_text(batch, title, title_x, title_y, title_size, 0xFF00FF)
    
    -- 渲染开始按钮背景
    local quad = require "soluna.material.quad"
    local button_width = 160
    local button_height = 40
    local button_x = math.floor(center_x - button_width / 2)
    local button_y = center_y - 20
    
    -- 按钮背景
    batch:add(quad.quad(button_width, button_height, 0x444444), button_x, button_y)
    -- 按钮边框
    batch:add(quad.quad(button_width, 2, 0xFFFFFF), button_x, button_y)
    batch:add(quad.quad(button_width, 2, 0xFFFFFF), button_x, button_y + button_height - 2)
    batch:add(quad.quad(2, button_height, 0xFFFFFF), button_x, button_y)
    batch:add(quad.quad(2, button_height, 0xFFFFFF), button_x + button_width - 2, button_y)
    
    -- 按钮文字
    local button_text = "START GAME"
    local button_text_size = 14
    local button_text_width = #button_text * button_text_size * 0.6
    local button_text_x = math.floor(center_x - button_text_width / 2)
    local button_text_y = button_y + 13
    renderer.render_text(batch, button_text, button_text_x, button_text_y, button_text_size, 0xFFFFFF)
    
    -- 渲染控制说明
    local controls_y = center_y + 60
    local control_size = 12
    
    renderer.render_text(batch, "CONTROLS:", center_x - 40, controls_y, control_size, 0xFFFF00)
    renderer.render_text(batch, "A/J - Move Left", center_x - 60, controls_y + 20, control_size, 0xFFFFFF)
    renderer.render_text(batch, "D/L - Move Right", center_x - 65, controls_y + 35, control_size, 0xFFFFFF)
    renderer.render_text(batch, "S/K - Soft Drop", center_x - 60, controls_y + 50, control_size, 0xFFFFFF)
    renderer.render_text(batch, "W/I - Rotate", center_x - 50, controls_y + 65, control_size, 0xFFFFFF)
    renderer.render_text(batch, "SPACE - Hard Drop", center_x - 70, controls_y + 80, control_size, 0xFFFFFF)
    
    -- 渲染点击提示
    local hint_text = "Click START GAME to begin!"
    local hint_size = 12
    local hint_width = #hint_text * hint_size * 0.6
    local hint_x = math.floor(center_x - hint_width / 2)
    local hint_y = center_y + 180
    renderer.render_text(batch, hint_text, hint_x, hint_y, hint_size, 0x00FFFF)
    
    batch:layer()
end

-- 检查是否点击了开始按钮
function M.is_start_button_clicked(mouse_x, mouse_y, screen_width, screen_height)
    -- 检查参数有效性
    if not mouse_x or not mouse_y or not screen_width or not screen_height then
        return false
    end
    
    local center_x = screen_width / 2
    local center_y = screen_height / 2
    local button_width = 160
    local button_height = 40
    local button_x = center_x - button_width / 2
    local button_y = center_y - 20
    
    return mouse_x >= button_x and mouse_x <= button_x + button_width and
           mouse_y >= button_y and mouse_y <= button_y + button_height
end

return M
