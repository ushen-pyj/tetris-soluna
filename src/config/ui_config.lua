-- UI配置
local constants = require "src.core.constants"

local M = {}

-- UI布局配置
M.SIDE_PANEL_WIDTH = 120
M.SIDE_PANEL_MARGIN = 24
M.PREVIEW_CELL_SIZE = math.floor(constants.CELL_SIZE * 0.8)

-- 分数显示配置
M.SCORE_BAR_WIDTH = constants.CELL_SIZE * 3
M.SCORE_BAR_HEIGHT = constants.CELL_SIZE - 8
M.SCORE_BAR_COLOR = 0x444444
M.SCORE_BAR_FILL_COLOR = 0xf0c808

-- 预览区域配置
M.PREVIEW_BACKGROUND_COLOR = 0x2a2a2a

return M
