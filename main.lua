local ltask = require "ltask"

local constants = require "src.core.constants"
local colors = require "src.core.colors"
local globals = require "src.core.globals"
local game_config = require "src.config.game_config"
local font_init = require "src.core.font_init"

local game_board = require "src.ui.game_board"
local side_panel = require "src.ui.side_panel"
local start_screen = require "src.ui.start_screen"

local input_handler = require "src.input.input_handler"
local unified_logic = require "src.logic.unified_game_logic"
local animated_renderer = require "src.ui.animated_renderer"

local args = ...

local font_initialized = false

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

local mouse_x, mouse_y = 0, 0
local cached_game_over = false
local cached_snapshot = nil
local last_time = 0
local logic_initialized = false
local bot_addr = nil
local pending_actions = nil
local pending_resume_actions = nil -- 用于自动暂停后等待执行的剩余动作（通常仅硬降）

local function ensure_logic()
    if not logic_initialized then
        unified_logic.init(game_config, globals.game_mode)
        logic_initialized = true
    end
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
end

function callback.event(ev)
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
                logic_initialized = false -- 重置以支持模式切换
                ensure_logic()
                return
            end
            if start_screen.is_dual_button_clicked(mouse_x, mouse_y, width, height) then
                globals.game_mode = constants.GAME_MODES.DUAL
                globals.game_state = constants.GAME_STATES.PLAYING
                logic_initialized = false -- 重置以支持模式切换
                ensure_logic()
                return
            end
            if start_screen.is_auto_button_clicked(mouse_x, mouse_y, width, height) then
                globals.game_mode = constants.GAME_MODES.AUTO
                globals.game_state = constants.GAME_STATES.PLAYING
                logic_initialized = false
                ensure_logic()
                -- 启动机器人服务
                bot_addr = ltask.uniqueservice("robot")
                pending_actions = nil
                return
            end
        end
        return
    end
    
    if globals.game_state == constants.GAME_STATES.PLAYING then
        ensure_logic()
        
        -- 统一架构处理输入
        local game_over = cached_game_over
        local action = input_handler.handle_mouse_input_main_thread(btn, down, game_over)
        if action == "reset" then
            unified_logic.reset()
            globals.game_state = constants.GAME_STATES.PLAYING
            cached_snapshot = nil
            cached_game_over = false
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        if down and btn == 0 then
            unified_logic.reset()
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

    -- 自动模式：当启用了“每步暂停”并处于等待状态时，空格用于继续执行剩余动作（硬降）
    if globals.game_mode == constants.GAME_MODES.AUTO and globals.auto_pause_enabled and globals.auto_pause_waiting then
        if code == constants.KEYS.HARD_DROP then
            if pending_resume_actions and #pending_resume_actions > 0 then
                for i = 1, #pending_resume_actions do
                    local act = pending_resume_actions[i]
                    if act[1] == "move" then
                        unified_logic.move(nil, act[2], 0)
                    elseif act[1] == "rotate" then
                        unified_logic.rotate()
                    elseif act[1] == "hard_drop" then
                        unified_logic.hard_drop()
                    elseif act[1] == "soft_drop_step" then
                        unified_logic.soft_drop_step()
                    end
                end
            else
                -- 兜底：若无缓存动作，至少执行一次硬降
                unified_logic.hard_drop()
            end
            pending_resume_actions = nil
            globals.auto_pause_waiting = false
            return
        end
        -- 处于等待状态时，其他按键不处理
        return
    end
    
    if globals.game_mode == constants.GAME_MODES.SINGLE then
        if cached_game_over then 
            return 
        end
        
        -- 单人模式输入处理
        local action, arg1, arg2 = input_handler.handle_key_input(code)
        if action then
            if action == "move" then
                unified_logic.move(nil, arg1, arg2)
            elseif action == "soft_drop_step" then
                unified_logic.soft_drop_step()
            elseif action == "rotate" then
                unified_logic.rotate()
            elseif action == "hard_drop" then
                unified_logic.hard_drop()
            end
        end
    else
        -- 双人模式输入处理
        local action, player_id = input_handler.handle_dual_key_input(code)
        if action and player_id then
            local player = (player_id == 1) and cached_snapshot.player1 or cached_snapshot.player2
            if not player.game_over then
                if action == "move" then
                    local dx = input_handler.get_move_direction(code, player_id)
                    unified_logic.move(player_id, dx, 0)
                elseif action == "soft_drop_step" then
                    unified_logic.soft_drop_step(player_id)
                elseif action == "rotate" then
                    unified_logic.rotate(player_id)
                elseif action == "hard_drop" then
                    unified_logic.hard_drop(player_id)
                end
            end
        end
    end
end

local auto_first = false

function callback.frame(count)
    count = count or 1
    do_font_init()
    local current_time = count / 60.0
    local delta_time = current_time - last_time
    last_time = current_time
    
    if globals.game_state == constants.GAME_STATES.START_SCREEN then
        start_screen.render(batch, width, height)
    elseif globals.game_state == constants.GAME_STATES.PLAYING then
        ensure_logic()
        local is_auto_waiting = (globals.game_mode == constants.GAME_MODES.AUTO) and globals.auto_pause_enabled and globals.auto_pause_waiting
        if not is_auto_waiting then
            unified_logic.update(current_time, delta_time)
        end
        
        local snapshot = unified_logic.get_state()
        cached_snapshot = snapshot
        
        animated_renderer.sync_animation_from_snapshot(snapshot)
        if not is_auto_waiting then
            animated_renderer.update_animations(delta_time)
        end
        
        if globals.game_mode == constants.GAME_MODES.SINGLE or globals.game_mode == constants.GAME_MODES.AUTO then
            cached_game_over = snapshot.game_over
            
            game_board.render(batch, globals.board_x, globals.board_y, snapshot)
            side_panel.render(batch, globals.board_x, globals.board_y, snapshot, width, height)
            
            -- 自动模式执行
            if globals.game_mode == constants.GAME_MODES.AUTO then
                if snapshot and not snapshot.game_over then
                    -- 若启用“每步暂停”且处于等待状态，不请求新决策也不执行动作
                    if globals.auto_pause_enabled and globals.auto_pause_waiting and auto_first then
                        -- 等待用户按空格继续
                    else
                        auto_first = true
                        if not pending_actions then
                        -- 请求一次决策
                        if not bot_addr then
                            bot_addr = ltask.uniqueservice("robot")
                        end
                        local ok, actions = pcall(ltask.call, bot_addr, "decide", snapshot)
                            if ok and actions and #actions > 0 then
                                pending_actions = actions
                            else
                                pending_actions = nil
                            end
                        end
                        if pending_actions and #pending_actions > 0 then
                            if globals.auto_pause_enabled then
                                -- 只执行移动与旋转，留下硬降到空格触发
                                local resume_actions = {}
                                for i = 1, #pending_actions do
                                    local act = pending_actions[i]
                                    if act[1] == "move" then
                                        unified_logic.move(nil, act[2], 0)
                                    elseif act[1] == "rotate" then
                                        unified_logic.rotate()
                                    elseif act[1] == "hard_drop" then
                                        table.insert(resume_actions, act)
                                    elseif act[1] == "soft_drop_step" then
                                        -- 若未来需要，也可选择提前执行或延后，这里保持原样留到继续时
                                        table.insert(resume_actions, act)
                                    end
                                end
                                pending_actions = nil
                                pending_resume_actions = (#resume_actions > 0) and resume_actions or nil
                                globals.auto_pause_waiting = true
                            else
                                -- 正常执行所有动作
                                for i = 1, #pending_actions do
                                    local act = pending_actions[i]
                                    if act[1] == "move" then
                                        unified_logic.move(nil, act[2], 0)
                                    elseif act[1] == "rotate" then
                                        unified_logic.rotate()
                                    elseif act[1] == "hard_drop" then
                                        unified_logic.hard_drop()
                                    elseif act[1] == "soft_drop_step" then
                                        unified_logic.soft_drop_step()
                                    end
                                end
                                pending_actions = nil
                            end
                        end
                    end
                end
            end

            if snapshot.game_over then
                globals.game_state = constants.GAME_STATES.GAME_OVER
                
                -- 【调试】打印最终棋盘状态
                if globals.game_mode == constants.GAME_MODES.AUTO then
                    print("\n=== 游戏结束，最终棋盘状态 ===")
                    print("最终得分:", snapshot.score)
                    print("消除行数:", snapshot.lines_cleared)
                    print("\n棋盘状态 (1=有方块, .=空):")
                    for r = 1, #snapshot.grid do
                        local line = string.format("第%2d行: ", r)
                        for c = 1, #snapshot.grid[1] do
                            line = line .. (snapshot.grid[r][c] and "1" or ".")
                        end
                        print(line)
                    end
                    
                    -- 打印每列高度
                    print("\n每列高度统计:")
                    local heights = {}
                    for c = 1, #snapshot.grid[1] do
                        heights[c] = 0
                        for r = 1, #snapshot.grid do
                            if snapshot.grid[r][c] then
                                heights[c] = #snapshot.grid - r + 1
                                break
                            end
                        end
                    end
                    local height_line = "高度: "
                    for c = 1, #heights do
                        height_line = height_line .. string.format("%2d ", heights[c])
                    end
                    print(height_line)
                    print("=====================================\n")
                end
                
                -- 清理机器人
                if bot_addr then
                    pcall(ltask.syscall, bot_addr, "quit")
                    bot_addr = nil
                end
            end
        else
            cached_game_over = snapshot.player1.game_over and snapshot.player2.game_over
            
            game_board.render_dual(batch, width, height, snapshot)
            side_panel.render_dual(batch, width, height, snapshot)
            
            if snapshot.player1.game_over and snapshot.player2.game_over then
                globals.game_state = constants.GAME_STATES.GAME_OVER
            end
        end
    elseif globals.game_state == constants.GAME_STATES.GAME_OVER then
        local snapshot = unified_logic.get_state()
        if globals.game_mode == constants.GAME_MODES.SINGLE or globals.game_mode == constants.GAME_MODES.AUTO then
            game_board.render(batch, globals.board_x, globals.board_y, snapshot)
            side_panel.render(batch, globals.board_x, globals.board_y, snapshot, width, height)
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
        renderer.render_text(batch, game_over_text, text_x, center_y - 10, text_size, colors.GAME_OVER_TEXT, width, height)
        
        local restart_text = "Click to restart"
        local restart_size = 14
        local restart_width = #restart_text * restart_size * 0.6
        local restart_x = center_x - restart_width / 2
        renderer.render_text(batch, restart_text, restart_x, center_y + 20, restart_size, colors.RESTART_TEXT, width, height)
    end
end

return callback