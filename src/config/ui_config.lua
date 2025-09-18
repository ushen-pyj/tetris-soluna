-- UI配置
local constants = require "src.core.constants"
local colors = require "src.core.colors"

local M = {}

-- UI布局配置
M.SIDE_PANEL_WIDTH = 120
M.SIDE_PANEL_MARGIN = 24
M.PREVIEW_CELL_SIZE = math.floor(constants.CELL_SIZE * 0.8)

-- 分数显示配置
M.SCORE_BAR_WIDTH = constants.CELL_SIZE * 3
M.SCORE_BAR_HEIGHT = constants.CELL_SIZE - 8
M.SCORE_BAR_COLOR = colors.SCORE_BAR_BG
M.SCORE_BAR_FILL_COLOR = colors.SCORE_BAR_FILL

-- 预览区域配置
M.PREVIEW_BACKGROUND_COLOR = colors.PREVIEW_BACKGROUND

return M
