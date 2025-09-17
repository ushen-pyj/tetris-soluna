-- 游戏板渲染模块
local renderer = require "src.ui.renderer"

local M = {}

-- 渲染完整的游戏板
function M.render(batch, board_x, board_y, game_state)
    -- 渲染背景网格
    renderer.render_game_board_background(batch, board_x, board_y)
    
    -- 渲染已固定的方块
    renderer.render_fixed_pieces(batch, board_x, board_y, game_state.grid)
    
    -- 渲染当前下落的方块
    if not game_state.game_over then
        renderer.render_current_piece(batch, board_x, board_y, game_state.cur)
    end
end

return M
