-- 全局变量管理
local constants = require "src.core.constants"

local M = {}

-- 游戏全局状态
M.game_state = constants.GAME_STATES.START_SCREEN
M.game_mode = constants.GAME_MODES.SINGLE  -- 当前游戏模式
M.score = 0
M.level = 1
M.lines_cleared = 0

-- 自动模式：决策后暂停相关配置
-- 由用户手动开关：true 启用“每步暂停”，false 关闭
M.auto_pause_enabled = false
-- 当前是否在等待用户按键继续（仅当 auto_pause_enabled=true 时有效）
M.auto_pause_waiting = false

-- 渲染相关全局变量
M.board_x = 0
M.board_y = 0
M.screen_width = 480
M.screen_height = 800


-- 计算游戏板位置
function M.calculate_board_position(screen_width, screen_height)
    M.screen_width = screen_width
    M.screen_height = screen_height
    M.board_x = math.floor((screen_width - constants.GRID_COLS * constants.CELL_SIZE) / 2)
    M.board_y = math.floor((screen_height - constants.GRID_ROWS * constants.CELL_SIZE) / 2)
end

-- 重置全局状态
function M.reset()
    M.game_state = constants.GAME_STATES.PLAYING
    M.score = 0
    M.level = 1
    M.lines_cleared = 0
    -- 重置暂停等待状态，但不改变开关（由用户控制）
    M.auto_pause_waiting = false
end

return M
