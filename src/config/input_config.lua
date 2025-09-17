-- 输入配置
local constants = require "src.core.constants"

local M = {}

-- 输入键位配置
M.KEYS = constants.KEYS

-- 输入处理配置
M.REPEAT_DELAY = 0.3  -- 按键重复延迟（秒）
M.REPEAT_RATE = 0.1   -- 按键重复频率（秒）

return M
