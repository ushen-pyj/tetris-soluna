local ltask = require "ltask"
local constants = require "src.core.constants"
local game_config = require "src.config.game_config"
local BaseTetrisLogic = require "src.logic.base_tetris_logic"

local S = {}

local state = {
    player = nil,  -- 使用基础逻辑的玩家状态
    drop_interval = game_config.DROP_INTERVAL,
    level = 1,
}

-- 更新等级和下降速度
local function update_level(cleared_lines)
    if cleared_lines > 0 then
        local new_level = math.floor(state.player.lines_cleared / 10) + 1
        if new_level > state.level then
            state.level = new_level
            state.drop_interval = math.max(0.1, game_config.DROP_INTERVAL - (state.level - 1) * game_config.LEVEL_SPEED_INCREASE)
        end
    end
end

local running = false

local function schedule_tick()
    if not running then return end
    if not state.player.game_over then
        local cleared = BaseTetrisLogic.new_piece_if_needed(state.player)
        update_level(cleared)
    end
    ltask.timeout(math.floor(state.drop_interval * 60), schedule_tick)
end

function S.init(config)
    BaseTetrisLogic.init(config)
    state.player = BaseTetrisLogic.new_player_state()
    state.level = 1
    state.drop_interval = config.DROP_INTERVAL or game_config.DROP_INTERVAL
    BaseTetrisLogic.spawn(state.player)
    running = true
    schedule_tick()
end

function S.reset()
    BaseTetrisLogic.reset_player(state.player)
    state.level = 1
    state.drop_interval = game_config.DROP_INTERVAL
end

function S.move(dx, dy)
    return BaseTetrisLogic.move(state.player, dx, dy)
end

function S.soft_drop_step()
    if state.player.game_over then return end
    local cleared = BaseTetrisLogic.new_piece_if_needed(state.player)
    update_level(cleared)
end

function S.rotate()
    return BaseTetrisLogic.rotate(state.player)
end

function S.hard_drop()
    if state.player.game_over then return end
    local cleared = BaseTetrisLogic.hard_drop(state.player)
    update_level(cleared)
end

function S.snapshot()
    -- 为了保持向后兼容，将玩家状态展平到顶层
    return {
        grid = state.player.grid,
        cur = state.player.cur,
        score = state.player.score,
        level = state.level,
        lines_cleared = state.player.lines_cleared,
        game_over = state.player.game_over,
        next_kind = state.player.next_kind,
        drop_interval = state.drop_interval,
    }
end

function S.quit()
    running = false
end

return S
