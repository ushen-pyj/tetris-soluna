-- 俄罗斯方块游戏主文件 - 重构版本
local ltask = require "ltask"

-- 导入核心模块
local constants = require "src.core.constants"
local colors = require "src.core.colors"
local globals = require "src.core.globals"
local game_config = require "src.config.game_config"
local font_init = require "src.core.font_init"

-- 导入UI模块
local game_board = require "src.ui.game_board"
local side_panel = require "src.ui.side_panel"
local start_screen = require "src.ui.start_screen"

-- 导入输入处理
local input_handler = require "src.input.input_handler"

local args = ...

local font_initialized = false

-- 执行字体初始化（只在第一帧执行一次）
local function do_font_init()
    if font_initialized then return end
    font_initialized = true
    local success = font_init.init()
    if success then
        print("字体系统初始化成功")
    else
        print("字体系统初始化失败，但游戏将继续运行")
    end
end
local batch = args.batch
local width = args.width or globals.screen_width
local height = args.height or globals.screen_height

globals.calculate_board_position(width, height)

local logic_addr
local dual_logic_addr
local mouse_x, mouse_y = 0, 0
local cached_game_over = false
local cached_snapshot = nil

local function ensure_logic()
    if globals.game_mode == constants.GAME_MODES.SINGLE then
        if not logic_addr then
            logic_addr = ltask.uniqueservice "src.logic.tetris_logic"
            ltask.call(logic_addr, "init", game_config)
        end
    else -- DUAL mode
        if not dual_logic_addr then
            dual_logic_addr = ltask.uniqueservice "src.logic.dual_tetris_logic"
            ltask.call(dual_logic_addr, "init", game_config)
        end
    end
end

local function get_logic_addr()
    return globals.game_mode == constants.GAME_MODES.SINGLE and logic_addr or dual_logic_addr
end

local callback = {}

function callback.window_resize(re_width, re_height)
    width = re_width
    height = re_height
    globals.screen_width = width
    globals.screen_height = height
    globals.calculate_board_position(width, height)
end

function callback.init()
    print("init")
end

function callback.event(ev)
    print("event: ", ev)
end

function callback.mouse_move(x, y)
    mouse_x, mouse_y = x, y
end

function callback.mouse_button(btn, down)
    if globals.game_state == constants.GAME_STATES.START_SCREEN then
        if down and btn == 0 then
            if start_screen.is_single_button_clicked(mouse_x, mouse_y, width, height) then
                globals.game_mode = constants.GAME_MODES.SINGLE
                globals.game_state = constants.GAME_STATES.PLAYING
                ensure_logic()
                return
            end
            if start_screen.is_dual_button_clicked(mouse_x, mouse_y, width, height) then
                globals.game_mode = constants.GAME_MODES.DUAL
                globals.game_state = constants.GAME_STATES.PLAYING
                ensure_logic()
                return
            end
        end
        return
    end
    
    if globals.game_state == constants.GAME_STATES.PLAYING then
        ensure_logic()
        local current_logic = get_logic_addr()
        local game_over = cached_game_over
        if cached_snapshot == nil then
            local snapshot = ltask.call(current_logic, "snapshot")
            if snapshot then
                if globals.game_mode == constants.GAME_MODES.SINGLE then
                    game_over = snapshot.game_over
                else
                    game_over = snapshot.player1.game_over and snapshot.player2.game_over
                end
            end
        end
        
        local action = input_handler.handle_mouse_input(btn, down, current_logic, game_over)
        if action == "reset" then
            ltask.call(current_logic, "reset")
            globals.game_state = constants.GAME_STATES.PLAYING
            cached_snapshot = nil
            cached_game_over = false
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        if down and btn == 0 then
            ensure_logic()
            local current_logic = get_logic_addr()
            ltask.call(current_logic, "reset")
            globals.game_state = constants.GAME_STATES.PLAYING
            cached_snapshot = nil
            cached_game_over = false
        end
    end
end

function callback.key(code, down)
    if down == 0 then return end
    if globals.game_state ~= constants.GAME_STATES.PLAYING then
        return
    end
    
    if not cached_snapshot then
        return
    end
    
    ensure_logic()
    local current_logic = get_logic_addr()
    
    if globals.game_mode == constants.GAME_MODES.SINGLE then
        if cached_game_over then 
            return 
        end
        
        local action, arg1, arg2 = input_handler.handle_key_input(code)
        if action then
            if action == "move" then
                ltask.call(current_logic, "move", arg1, arg2)
            elseif action == "soft_drop_step" then
                ltask.call(current_logic, "soft_drop_step")
            elseif action == "rotate" then
                ltask.call(current_logic, "rotate")
            elseif action == "hard_drop" then
                ltask.call(current_logic, "hard_drop")
            end
        end
    else
        local action, player_id = input_handler.handle_dual_key_input(code)
        if action and player_id then
            local player = (player_id == 1) and cached_snapshot.player1 or cached_snapshot.player2
            if not player.game_over then
                if action == "move" then
                    local dx = input_handler.get_move_direction(code, player_id)
                    ltask.call(current_logic, "move", player_id, dx, 0)
                elseif action == "soft_drop_step" then
                    ltask.call(current_logic, "soft_drop_step", player_id)
                elseif action == "rotate" then
                    ltask.call(current_logic, "rotate", player_id)
                elseif action == "hard_drop" then
                    ltask.call(current_logic, "hard_drop", player_id)
                end
            end
        end
    end
end

function callback.frame(count)
    do_font_init()
    
    if globals.game_state == constants.GAME_STATES.START_SCREEN then
        start_screen.render(batch, width, height)
    elseif globals.game_state == constants.GAME_STATES.PLAYING then
        ensure_logic()
        local current_logic = get_logic_addr()
        local snapshot = ltask.call(current_logic, "snapshot")
        if not snapshot then return end
        
        cached_snapshot = snapshot
        if globals.game_mode == constants.GAME_MODES.SINGLE then
            cached_game_over = snapshot.game_over
        else
            cached_game_over = snapshot.player1.game_over and snapshot.player2.game_over
        end
        
        if globals.game_mode == constants.GAME_MODES.SINGLE then
            game_board.render(batch, globals.board_x, globals.board_y, snapshot)
            side_panel.render(batch, globals.board_x, globals.board_y, snapshot, args.width)
            
            if snapshot.game_over then
                globals.game_state = constants.GAME_STATES.GAME_OVER
            end
        else
            game_board.render_dual(batch, width, height, snapshot)
            side_panel.render_dual(batch, width, height, snapshot)
            
            if snapshot.player1.game_over and snapshot.player2.game_over then
                globals.game_state = constants.GAME_STATES.GAME_OVER
            end
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        ensure_logic()
        local current_logic = get_logic_addr()
        local snapshot = ltask.call(current_logic, "snapshot")
        if snapshot then
            if globals.game_mode == constants.GAME_MODES.SINGLE then
                game_board.render(batch, globals.board_x, globals.board_y, snapshot)
                side_panel.render(batch, globals.board_x, globals.board_y, snapshot, args.width)
            else
                game_board.render_dual(batch, width, height, snapshot)
                side_panel.render_dual(batch, width, height, snapshot)
            end
            
            local renderer = require "src.ui.renderer"
            local center_x = width / 2
            local center_y = height / 2
            local game_over_text = "GAME OVER"
            local text_size = 20
            local text_width = #game_over_text * text_size * 0.6
            local text_x = center_x - text_width / 2
            renderer.render_text(batch, game_over_text, text_x, center_y - 10, text_size, colors.GAME_OVER_TEXT)
            
            local restart_text = "Click to restart"
            local restart_size = 14
            local restart_width = #restart_text * restart_size * 0.6
            local restart_x = center_x - restart_width / 2
            renderer.render_text(batch, restart_text, restart_x, center_y + 20, restart_size, colors.RESTART_TEXT)
        end
    end
end

return callback