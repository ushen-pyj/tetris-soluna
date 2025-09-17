-- 输入处理器
local constants = require "src.core.constants"
local input_config = require "src.config.input_config"

local M = {}

-- 检查字符是否匹配键位
local function is_key_match(code, keys)
    if type(keys) == "table" then
        for _, key in ipairs(keys) do
            if code == string.byte(key) then
                return true
            end
        end
    else
        return code == string.byte(keys)
    end
    return false
end

-- 处理字符输入
function M.handle_char_input(code, logic_addr)
    -- 转换为小写
    if code >= 65 and code <= 90 then
        code = code + 32
    end
    
    -- 处理移动
    if is_key_match(code, input_config.KEYS.MOVE_LEFT) then
        return "move", -1, 0
    elseif is_key_match(code, input_config.KEYS.MOVE_RIGHT) then
        return "move", 1, 0
    elseif is_key_match(code, input_config.KEYS.SOFT_DROP) then
        return "soft_drop_step"
    elseif is_key_match(code, input_config.KEYS.ROTATE) then
        return "rotate"
    elseif code == string.byte(input_config.KEYS.HARD_DROP) then
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

return M
