-- 俄罗斯方块游戏主文件 - 重构版本
local ltask = require "ltask"

-- 导入核心模块
local constants = require "src.core.constants"
local globals = require "src.core.globals"
local game_config = require "src.config.game_config"

-- 导入UI模块
local game_board = require "src.ui.game_board"
local side_panel = require "src.ui.side_panel"
local start_screen = require "src.ui.start_screen"

-- 导入输入处理
local input_handler = require "src.input.input_handler"

local args = ...
local batch = args.batch
local width = args.width or globals.screen_width
local height = args.height or globals.screen_height

-- 初始化全局状态
globals.calculate_board_position(width, height)

-- 游戏逻辑服务
local logic_addr

-- 确保逻辑服务已初始化
local function ensure_logic()
    if not logic_addr then
        logic_addr = ltask.uniqueservice "src.logic.tetris_logic"
        ltask.call(logic_addr, "init", game_config)
    end
end

-- 回调函数集合
local callback = {}

-- 鼠标按键回调
function callback.mouse_button(btn, down, x, y)
    -- 处理开始界面点击
    if globals.game_state == constants.GAME_STATES.START_SCREEN then
        if down and btn == 0 then  -- 左键按下
            -- 如果没有坐标信息，直接开始游戏
            if not x or not y then
                globals.game_state = constants.GAME_STATES.PLAYING
                ensure_logic()
                return
            end
            if start_screen.is_start_button_clicked(x, y, width, height) then
                globals.game_state = constants.GAME_STATES.PLAYING
                ensure_logic()
                return
            end
        end
        return
    end
    
    -- 游戏中的鼠标处理
    if globals.game_state == constants.GAME_STATES.PLAYING then
        ensure_logic()
        local snapshot = ltask.call(logic_addr, "snapshot")
        if snapshot then
            local action = input_handler.handle_mouse_input(btn, down, logic_addr, snapshot.game_over)
            if action == "reset" then
                ltask.call(logic_addr, "reset")
                globals.game_state = constants.GAME_STATES.PLAYING
            end
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        -- 游戏结束界面点击重启
        if down and btn == 0 then  -- 左键按下
            ensure_logic()
            ltask.call(logic_addr, "reset")
            globals.game_state = constants.GAME_STATES.PLAYING
        end
    end
end

-- 字符输入回调
function callback.char(code)
    -- 只在游戏进行中处理键盘输入
    if globals.game_state ~= constants.GAME_STATES.PLAYING then
        return
    end
    
    ensure_logic()
    local snapshot = ltask.call(logic_addr, "snapshot")
    if not snapshot or snapshot.game_over then 
        return 
    end
    
    local action, arg1, arg2 = input_handler.handle_char_input(code, logic_addr)
    if action then
        if action == "move" then
            ltask.call(logic_addr, "move", arg1, arg2)
        elseif action == "soft_drop_step" then
            ltask.call(logic_addr, "soft_drop_step")
        elseif action == "rotate" then
            ltask.call(logic_addr, "rotate")
        elseif action == "hard_drop" then
            ltask.call(logic_addr, "hard_drop")
        end
    end
end

-- 帧渲染回调
function callback.frame(count)
    -- 根据游戏状态渲染不同界面
    if globals.game_state == constants.GAME_STATES.START_SCREEN then
        -- 渲染开始界面
        start_screen.render(batch, width, height)
    elseif globals.game_state == constants.GAME_STATES.PLAYING then
        -- 渲染游戏界面
        ensure_logic()
        local snapshot = ltask.call(logic_addr, "snapshot")
        if not snapshot then return end
        
        -- 渲染游戏板
        game_board.render(batch, globals.board_x, globals.board_y, snapshot)
        
        -- 渲染侧边栏
        side_panel.render(batch, globals.board_x, globals.board_y, snapshot, args.width)
        
        -- 检查游戏结束状态
        if snapshot.game_over then
            globals.game_state = constants.GAME_STATES.GAME_OVER
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        -- 游戏结束界面（目前显示游戏界面+游戏结束提示）
        ensure_logic()
        local snapshot = ltask.call(logic_addr, "snapshot")
        if snapshot then
            -- 渲染游戏板
            game_board.render(batch, globals.board_x, globals.board_y, snapshot)
            
            -- 渲染侧边栏
            side_panel.render(batch, globals.board_x, globals.board_y, snapshot, args.width)
            
            -- 渲染游戏结束提示
            local renderer = require "src.ui.renderer"
            local center_x = width / 2
            local center_y = height / 2
            local game_over_text = "GAME OVER"
            local text_size = 20
            local text_width = #game_over_text * text_size * 0.6
            local text_x = center_x - text_width / 2
            renderer.render_text(batch, game_over_text, text_x, center_y - 10, text_size, 0xFF0000)
            
            local restart_text = "Click to restart"
            local restart_size = 14
            local restart_width = #restart_text * restart_size * 0.6
            local restart_x = center_x - restart_width / 2
            renderer.render_text(batch, restart_text, restart_x, center_y + 20, restart_size, 0xFFFFFF)
        end
    end
end

return callback