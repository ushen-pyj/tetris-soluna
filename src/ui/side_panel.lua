-- 侧边栏渲染模块
local renderer = require "src.ui.renderer"

local M = {}

-- 渲染侧边栏
function M.render(batch, board_x, board_y, game_state, screen_width)
    local side_x = board_x + 10 * 28 + 24  -- GRID_COLS * CELL_SIZE + margin
    local side_y = board_y
    
    batch:layer(0, 0)
    
    -- 渲染下一块预览
    if game_state.next_kind then
        side_y = renderer.render_next_piece_preview(batch, side_x, side_y, game_state.next_kind)
        side_y = side_y + 12  -- 额外间距
    end
    
    -- 渲染分数显示（包含分数、等级、行数）
    side_y = renderer.render_score_display(batch, side_x, side_y, game_state)
    
    batch:layer()
end

return M
