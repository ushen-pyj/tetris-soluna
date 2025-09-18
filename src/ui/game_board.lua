-- 游戏板渲染模块
local renderer = require "src.ui.renderer"
local colors = require "src.core.colors"

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

-- 渲染双人模式游戏板
function M.render_dual(batch, screen_width, screen_height, game_state)
    local constants = require "src.core.constants"
    local board_width = constants.GRID_COLS * constants.CELL_SIZE
    local board_height = constants.GRID_ROWS * constants.CELL_SIZE
    
    -- 计算双人游戏板位置
    local spacing = 60  -- 两个游戏板之间的间距
    local total_width = board_width * 2 + spacing
    local start_x = (screen_width - total_width) / 2
    local board_y = (screen_height - board_height) / 2
    
    -- Player 1游戏板（左侧）
    local p1_board_x = start_x
    renderer.render_game_board_background(batch, p1_board_x, board_y)
    renderer.render_fixed_pieces(batch, p1_board_x, board_y, game_state.player1.grid)
    if not game_state.player1.game_over then
        renderer.render_current_piece(batch, p1_board_x, board_y, game_state.player1.cur)
    end
    
    -- Player 2游戏板（右侧）
    local p2_board_x = start_x + board_width + spacing
    renderer.render_game_board_background(batch, p2_board_x, board_y)
    renderer.render_fixed_pieces(batch, p2_board_x, board_y, game_state.player2.grid)
    if not game_state.player2.game_over then
        renderer.render_current_piece(batch, p2_board_x, board_y, game_state.player2.cur)
    end
    
    -- 渲染玩家标识
    local text_renderer = require "src.ui.renderer"
    text_renderer.render_text(batch, "PLAYER 1", p1_board_x + 10, board_y - 30, 14, colors.PLAYER1_LABEL)
    text_renderer.render_text(batch, "PLAYER 2", p2_board_x + 10, board_y - 30, 14, colors.PLAYER2_LABEL)
    
    -- 如果某个玩家游戏结束，显示提示
    if game_state.player1.game_over then
        local game_over_text = "GAME OVER"
        local text_size = 12
        local text_width = #game_over_text * text_size * 0.6
        local text_x = p1_board_x + (board_width - text_width) / 2
        text_renderer.render_text(batch, game_over_text, text_x, board_y + board_height / 2, text_size, colors.GAME_OVER_TEXT)
    end
    
    if game_state.player2.game_over then
        local game_over_text = "GAME OVER"
        local text_size = 12
        local text_width = #game_over_text * text_size * 0.6
        local text_x = p2_board_x + (board_width - text_width) / 2
        text_renderer.render_text(batch, game_over_text, text_x, board_y + board_height / 2, text_size, colors.GAME_OVER_TEXT)
    end
end

return M
