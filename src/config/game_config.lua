-- 游戏配置
local constants = require "src.core.constants"

local M = {}

M.debug = false

-- 游戏基础配置
M.GRID_COLS = constants.GRID_COLS
M.GRID_ROWS = constants.GRID_ROWS
M.CELL = constants.CELL_SIZE

-- 游戏难度配置
M.DROP_INTERVAL = 1  -- 基础下落间隔（秒）
M.LEVEL_SPEED_INCREASE = 0.1  -- 每级速度增加

-- 计分配置
M.SCORE_BASE = 100
M.SCORE_MULTIPLIER = 2

-- 形状和颜色配置
M.SHAPES = constants.SHAPES
M.COLORS = constants.COLORS

return M
