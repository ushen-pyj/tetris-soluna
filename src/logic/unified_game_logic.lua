local BaseTetrisLogic = require "src.logic.base_tetris_logic"
local game_config = require "src.config.game_config"
local animated_renderer = require "src.ui.animated_renderer"
local animation = require "src.utils.animation"
local constants = require "src.core.constants"

local M = {}

local state = {
    mode = constants.GAME_MODES.SINGLE,
    running = false,
    single = {
        player = nil,
        level = 1,
        drop_interval = game_config.DROP_INTERVAL,
        last_drop_time = 0,
        animation_state = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        }
    },
    dual = {
        player1 = nil,
        player2 = nil,
        level1 = 1,
        level2 = 1,
        drop_interval1 = game_config.DROP_INTERVAL,
        drop_interval2 = game_config.DROP_INTERVAL,
        last_drop_time1 = 0,
        last_drop_time2 = 0,
        animation_state1 = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        },
        animation_state2 = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        }
    }
}

local function update_level(player_data, cleared_lines)
    if cleared_lines > 0 then
        local new_level = math.floor(player_data.player.lines_cleared / 10) + 1
        if new_level > player_data.level then
            player_data.level = new_level
            player_data.drop_interval = math.max(0.1, game_config.DROP_INTERVAL - (player_data.level - 1) * game_config.LEVEL_SPEED_INCREASE)
        end
    end
end

local function perform_line_clear(player, cleared_rows)
    local new_rows = {}
    local cleared = #cleared_rows

    for r = BaseTetrisLogic.get_config().GRID_ROWS, 1, -1 do
        local should_clear = false
        for _, cleared_row in ipairs(cleared_rows) do
            if r == cleared_row then
                should_clear = true
                break
            end
        end
        
        if not should_clear then
            table.insert(new_rows, player.grid[r])
        end
    end

    for i = 1, cleared do
        local row = {}
        for c = 1, BaseTetrisLogic.get_config().GRID_COLS do 
            row[c] = false 
        end
        table.insert(new_rows, row)
    end

    local rebuilt = {}
    for i = #new_rows, 1, -1 do
        table.insert(rebuilt, new_rows[i])
    end
    player.grid = rebuilt
end

local function clear_lines_with_animation(player, animation_state, player_data, on_complete)
    local cleared_rows = {}
    local cleared = 0

    for r = 1, BaseTetrisLogic.get_config().GRID_ROWS do
        local full = true
        for c = 1, BaseTetrisLogic.get_config().GRID_COLS do
            if not player.grid[r][c] then 
                full = false 
                break 
            end
        end
        if full then
            cleared = cleared + 1
            table.insert(cleared_rows, r)
        end
    end
    if cleared > 0 then
        animation_state.is_animating = true
        animation_state.cleared_lines = cleared_rows

        local blocks_to_animate = {}
        for _, row in ipairs(cleared_rows) do
            for col = 1, BaseTetrisLogic.get_config().GRID_COLS do
                if player.grid[row][col] then
                    table.insert(blocks_to_animate, {
                        row = row,
                        col = col,
                        color = player.grid[row][col]
                    })
                end
            end
        end

        local anim_data = {
            type = "line_clear",
            blocks = blocks_to_animate,
            duration = 1.0,
            start_time = 0,
            easing = animation.EASING.EASE_OUT,
            on_complete = function()
                perform_line_clear(player, cleared_rows)

                local gain = game_config.SCORE_BASE * cleared * (game_config.SCORE_MULTIPLIER ^ (cleared - 1))
                player.score = player.score + gain
                player.lines_cleared = player.lines_cleared + cleared

                update_level(player_data, cleared)

                animation_state.is_animating = false
                animation_state.cleared_lines = {}
                animation_state.current_animation = nil

                if on_complete then
                    on_complete(cleared)
                end
            end,
            active = true,
            progress = 0
        }

        animation_state.current_animation = anim_data

        animated_renderer.start_main_thread_animation(anim_data)

        return cleared, cleared_rows
    end

    return 0, {}
end

local function new_piece_if_needed(player, animation_state, player_data, on_line_clear)
    if not BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) then
        BaseTetrisLogic.lock_piece(player)

        local cleared, cleared_rows = clear_lines_with_animation(player, animation_state, player_data, on_line_clear)

        BaseTetrisLogic.spawn(player)
        return cleared, cleared_rows
    else
        player.cur.r = player.cur.r + 1
        return 0, {}
    end
end

-- 初始化
function M.init(config, mode)
    BaseTetrisLogic.init(config)
    state.mode = mode or constants.GAME_MODES.SINGLE
    state.running = true
    
    if state.mode == constants.GAME_MODES.SINGLE then
        state.single.player = BaseTetrisLogic.new_player_state()
        state.single.level = 1
        state.single.drop_interval = config.DROP_INTERVAL or game_config.DROP_INTERVAL
        state.single.last_drop_time = 0
        state.single.animation_state = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        }
        BaseTetrisLogic.spawn(state.single.player)
    else
        state.dual.player1 = BaseTetrisLogic.new_player_state()
        state.dual.player2 = BaseTetrisLogic.new_player_state()
        state.dual.level1 = 1
        state.dual.level2 = 1
        state.dual.drop_interval1 = config.DROP_INTERVAL or game_config.DROP_INTERVAL
        state.dual.drop_interval2 = config.DROP_INTERVAL or game_config.DROP_INTERVAL
        state.dual.last_drop_time1 = 0
        state.dual.last_drop_time2 = 0
        state.dual.animation_state1 = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        }
        state.dual.animation_state2 = {
            is_animating = false,
            cleared_lines = {},
            current_animation = nil
        }
        BaseTetrisLogic.spawn(state.dual.player1)
        BaseTetrisLogic.spawn(state.dual.player2)
    end
end

function M.update(current_time, delta_time)
    if not state.running then
        return
    end
    if state.mode == constants.GAME_MODES.SINGLE then
        local s = state.single
        if s.player.game_over or s.animation_state.is_animating then
            return
        end

        -- 避免刚生成立即下落：首次更新时初始化last_drop_time
        if s.last_drop_time == 0 then
            s.last_drop_time = current_time
        end

        if current_time - s.last_drop_time >= s.drop_interval then
            local player_data = { player = s.player, level = s.level, drop_interval = s.drop_interval }
            new_piece_if_needed(s.player, s.animation_state, player_data)
            s.last_drop_time = current_time
        end
    else
        local d = state.dual

        if not d.player1.game_over and not d.animation_state1.is_animating then
            if d.last_drop_time1 == 0 then
                d.last_drop_time1 = current_time
            end
            if current_time - d.last_drop_time1 >= d.drop_interval1 then
                local player_data = { player = d.player1, level = d.level1, drop_interval = d.drop_interval1 }
                new_piece_if_needed(d.player1, d.animation_state1, player_data)
                d.last_drop_time1 = current_time
            end
        end

        if not d.player2.game_over and not d.animation_state2.is_animating then
            if d.last_drop_time2 == 0 then
                d.last_drop_time2 = current_time
            end
            if current_time - d.last_drop_time2 >= d.drop_interval2 then
                local player_data = { player = d.player2, level = d.level2, drop_interval = d.drop_interval2 }
                new_piece_if_needed(d.player2, d.animation_state2, player_data)
                d.last_drop_time2 = current_time
            end
        end
    end
end

function M.move(player_id, dx, dy)
    if state.mode == constants.GAME_MODES.SINGLE then
        return BaseTetrisLogic.move(state.single.player, dx, dy)
    else
        local player = (player_id == 1) and state.dual.player1 or state.dual.player2
        return BaseTetrisLogic.move(player, dx, dy)
    end
end

function M.rotate(player_id)
    if state.mode == constants.GAME_MODES.SINGLE then
        return BaseTetrisLogic.rotate(state.single.player)
    else
        local player = (player_id == 1) and state.dual.player1 or state.dual.player2
        return BaseTetrisLogic.rotate(player)
    end
end

function M.hard_drop(player_id)
    if state.mode == constants.GAME_MODES.SINGLE then
        local s = state.single
        if s.player.game_over then return end

        while BaseTetrisLogic.can_place(s.player.grid, s.player.cur.kind, s.player.cur.rot, s.player.cur.r+1, s.player.cur.c) do
            s.player.cur.r = s.player.cur.r + 1
        end

        BaseTetrisLogic.lock_piece(s.player)

        local player_data = { player = s.player, level = s.level, drop_interval = s.drop_interval }
        local cleared, cleared_rows = clear_lines_with_animation(s.player, s.animation_state, player_data)

        BaseTetrisLogic.spawn(s.player)
        return cleared, cleared_rows
    else
        local d = state.dual
        if not player_id or (player_id ~= 1 and player_id ~= 2) then
            return
        end

        local player = (player_id == 1) and d.player1 or d.player2
        local animation_state = (player_id == 1) and d.animation_state1 or d.animation_state2
        local level = (player_id == 1) and d.level1 or d.level2
        local drop_interval = (player_id == 1) and d.drop_interval1 or d.drop_interval2

        if not player or player.game_over then return end

        while BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) do
            player.cur.r = player.cur.r + 1
        end

        BaseTetrisLogic.lock_piece(player)
        local player_data = { player = player, level = level, drop_interval = drop_interval }
        local cleared, cleared_rows = clear_lines_with_animation(player, animation_state, player_data)

        BaseTetrisLogic.spawn(player)
        return cleared, cleared_rows
    end
end

function M.soft_drop_step(player_id)
    if state.mode == constants.GAME_MODES.SINGLE then
        local s = state.single
        if s.player.game_over then return end
        local player_data = { player = s.player, level = s.level, drop_interval = s.drop_interval }
        return new_piece_if_needed(s.player, s.animation_state, player_data)
    else
        local d = state.dual
        if not player_id or (player_id ~= 1 and player_id ~= 2) then
            return
        end

        local player = (player_id == 1) and d.player1 or d.player2
        local animation_state = (player_id == 1) and d.animation_state1 or d.animation_state2
        local level = (player_id == 1) and d.level1 or d.level2
        local drop_interval = (player_id == 1) and d.drop_interval1 or d.drop_interval2

        if not player or player.game_over then return end
        local player_data = { player = player, level = level, drop_interval = drop_interval }
        return new_piece_if_needed(player, animation_state, player_data)
    end
end

function M.get_state()
    if state.mode == constants.GAME_MODES.SINGLE then
        local s = state.single
        return {
            grid = s.player.grid,
            cur = s.player.cur,
            score = s.player.score,
            level = s.level,
            lines_cleared = s.player.lines_cleared,
            game_over = s.player.game_over,
            next_kind = s.player.next_kind,
            drop_interval = s.drop_interval,
            current_animation = s.animation_state.current_animation,
        }
    else
        local d = state.dual
        return {
            player1 = {
                grid = d.player1.grid,
                cur = d.player1.cur,
                score = d.player1.score,
                level = d.level1,
                lines_cleared = d.player1.lines_cleared,
                game_over = d.player1.game_over,
                next_kind = d.player1.next_kind,
                drop_interval = d.drop_interval1,
                current_animation = d.animation_state1.current_animation,
            },
            player2 = {
                grid = d.player2.grid,
                cur = d.player2.cur,
                score = d.player2.score,
                level = d.level2,
                lines_cleared = d.player2.lines_cleared,
                game_over = d.player2.game_over,
                next_kind = d.player2.next_kind,
                drop_interval = d.drop_interval2,
                current_animation = d.animation_state2.current_animation,
            },
            level = math.max(d.level1, d.level2), 
            total_lines_cleared = d.player1.lines_cleared + d.player2.lines_cleared
        }
    end
end

function M.reset()
    if state.mode == constants.GAME_MODES.SINGLE then
        local s = state.single
        BaseTetrisLogic.reset_player(s.player)
        s.level = 1
        s.drop_interval = game_config.DROP_INTERVAL
        s.last_drop_time = 0
        s.animation_state.is_animating = false
        s.animation_state.cleared_lines = {}
        s.animation_state.current_animation = nil
    else
        local d = state.dual
        BaseTetrisLogic.reset_player(d.player1)
        BaseTetrisLogic.reset_player(d.player2)
        d.level1 = 1
        d.level2 = 1
        d.drop_interval1 = game_config.DROP_INTERVAL
        d.drop_interval2 = game_config.DROP_INTERVAL
        d.last_drop_time1 = 0
        d.last_drop_time2 = 0
        d.animation_state1.is_animating = false
        d.animation_state1.cleared_lines = {}
        d.animation_state1.current_animation = nil
        d.animation_state2.is_animating = false
        d.animation_state2.cleared_lines = {}
        d.animation_state2.current_animation = nil
    end
end

function M.is_animating(player_id)
    if state.mode == constants.GAME_MODES.SINGLE then
        return state.single.animation_state.is_animating
    else
        if player_id == 1 then
            return state.dual.animation_state1.is_animating
        elseif player_id == 2 then
            return state.dual.animation_state2.is_animating
        else
            return state.dual.animation_state1.is_animating or state.dual.animation_state2.is_animating
        end
    end
end

function M.get_mode()
    return state.mode
end

function M.quit()
    state.running = false
end

return M
