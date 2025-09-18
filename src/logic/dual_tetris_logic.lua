local ltask = require "ltask"
local constants = require "src.core.constants"
local game_config = require "src.config.game_config"
local BaseTetrisLogic = require "src.logic.base_tetris_logic"

local S = {}

local state = {
    player1 = nil,
    player2 = nil,
    drop_interval = game_config.DROP_INTERVAL,
    level = 1,
    total_lines_cleared = 0, 
}

-- 更新双人模式的等级和下降速度
local function update_dual_level(cleared_lines)
    if cleared_lines > 0 then
        state.total_lines_cleared = state.total_lines_cleared + cleared_lines
        local new_level = math.floor(state.total_lines_cleared / 20) + 1 
        if new_level > state.level then
            state.level = new_level
            state.drop_interval = math.max(0.1, game_config.DROP_INTERVAL - (state.level - 1) * game_config.LEVEL_SPEED_INCREASE)
        end
    end
end

local running = false

local function schedule_tick()
    if not running then return end
    local total_cleared = 0
    
    if not state.player1.game_over then
        local cleared1 = BaseTetrisLogic.new_piece_if_needed(state.player1)
        total_cleared = total_cleared + cleared1
    end
    
    if not state.player2.game_over then
        local cleared2 = BaseTetrisLogic.new_piece_if_needed(state.player2)
        total_cleared = total_cleared + cleared2
    end
    
    update_dual_level(total_cleared)
    ltask.timeout(math.floor(state.drop_interval * 60), schedule_tick)
end

function S.init(config)
    BaseTetrisLogic.init(config)
    
    state.player1 = BaseTetrisLogic.new_player_state()
    state.player2 = BaseTetrisLogic.new_player_state()
    
    state.level = 1
    state.total_lines_cleared = 0
    state.drop_interval = config.DROP_INTERVAL or game_config.DROP_INTERVAL
    
    BaseTetrisLogic.spawn(state.player1)
    BaseTetrisLogic.spawn(state.player2)
    running = true
    schedule_tick()
end

function S.reset()
    BaseTetrisLogic.reset_player(state.player1)
    BaseTetrisLogic.reset_player(state.player2)
    
    state.level = 1
    state.total_lines_cleared = 0
    state.drop_interval = game_config.DROP_INTERVAL
end

function S.move(player_id, dx, dy)
    local player = (player_id == 1) and state.player1 or state.player2
    return BaseTetrisLogic.move(player, dx, dy)
end

function S.soft_drop_step(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    if not player or player.game_over then return end
    local cleared = BaseTetrisLogic.new_piece_if_needed(player)
    update_dual_level(cleared)
end

function S.rotate(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    return BaseTetrisLogic.rotate(player)
end

function S.hard_drop(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    if not player or player.game_over then return end
    local cleared = BaseTetrisLogic.hard_drop(player)
    update_dual_level(cleared)
end

function S.snapshot()
    return state
end

function S.quit()
    running = false
end

return S
