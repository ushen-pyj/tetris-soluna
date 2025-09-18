-- 输入处理器
local constants = require "src.core.constants"
local input_config = require "src.config.input_config"

local M = {}

-- 检查键码是否匹配键位
local function is_key_match(code, keys)
    if type(keys) == "table" then
        for _, key in ipairs(keys) do
            if code == key then
                return true
            end
        end
    else
        return code == keys
    end
    return false
end

-- 处理键盘输入
function M.handle_key_input(code)
    -- 处理移动
    if is_key_match(code, input_config.KEYS.MOVE_LEFT) then
        return "move", -1, 0
    elseif is_key_match(code, input_config.KEYS.MOVE_RIGHT) then
        return "move", 1, 0
    elseif is_key_match(code, input_config.KEYS.SOFT_DROP) then
        return "soft_drop_step"
    elseif is_key_match(code, input_config.KEYS.ROTATE) then
        return "rotate"
    elseif code == input_config.KEYS.HARD_DROP then
        return "hard_drop"
    end
    
    return nil
end

-- 处理鼠标输入
function M.handle_mouse_input(btn, down, logic_addr, game_over)
    if down and game_over then
        return "reset"
    end
    return nil
end

-- 处理双人模式键盘输入
function M.handle_dual_key_input(code)
    -- 检查Player 1的键位
    local p1_keys = constants.DUAL_KEYS.PLAYER1
    if code == p1_keys.MOVE_LEFT then
        return "move", 1
    elseif code == p1_keys.MOVE_RIGHT then
        return "move", 1
    elseif code == p1_keys.SOFT_DROP then
        return "soft_drop_step", 1
    elseif code == p1_keys.ROTATE then
        return "rotate", 1
    elseif code == p1_keys.HARD_DROP then
        return "hard_drop", 1
    end
    
    -- 检查Player 2的键位
    local p2_keys = constants.DUAL_KEYS.PLAYER2
    if code == p2_keys.MOVE_LEFT then
        return "move", 2
    elseif code == p2_keys.MOVE_RIGHT then
        return "move", 2
    elseif code == p2_keys.SOFT_DROP then
        return "soft_drop_step", 2
    elseif code == p2_keys.ROTATE then
        return "rotate", 2
    elseif code == p2_keys.HARD_DROP then
        return "hard_drop", 2
    end
    
    return nil, nil
end

-- 获取移动方向
function M.get_move_direction(code, player_id)
    local keys = (player_id == 1) and constants.DUAL_KEYS.PLAYER1 or constants.DUAL_KEYS.PLAYER2
    
    if code == keys.MOVE_LEFT then
        return -1
    elseif code == keys.MOVE_RIGHT then
        return 1
    end
    
    return 0
end

return M
