local renderer = require "src.ui.renderer"
local animated_renderer = require "src.ui.animated_renderer"
local colors = require "src.core.colors"
local text_renderer = require "src.ui.renderer"

local M = {}

function M.render(batch, board_x, board_y, game_state)
    renderer.render_game_board_background(batch, board_x, board_y)
    animated_renderer.render_fixed_pieces_animated(batch, board_x, board_y, game_state.grid)
    
    if not game_state.game_over then
        renderer.render_current_piece(batch, board_x, board_y, game_state.cur)
    end
end

function M.render_dual(batch, screen_width, screen_height, game_state)
    local constants = require "src.core.constants"
    local board_width = constants.GRID_COLS * constants.CELL_SIZE
    local board_height = constants.GRID_ROWS * constants.CELL_SIZE

    local spacing = 60
    local total_width = board_width * 2 + spacing
    local start_x = (screen_width - total_width) / 2
    local board_y = (screen_height - board_height) / 2

    local p1_board_x = start_x
    renderer.render_game_board_background(batch, p1_board_x, board_y)
    animated_renderer.render_fixed_pieces_animated(batch, p1_board_x, board_y, game_state.player1.grid, 1)
    if not game_state.player1.game_over then
        renderer.render_current_piece(batch, p1_board_x, board_y, game_state.player1.cur)
    end

    local p2_board_x = start_x + board_width + spacing
    renderer.render_game_board_background(batch, p2_board_x, board_y)
    animated_renderer.render_fixed_pieces_animated(batch, p2_board_x, board_y, game_state.player2.grid, 2)
    if not game_state.player2.game_over then
        renderer.render_current_piece(batch, p2_board_x, board_y, game_state.player2.cur)
    end

    text_renderer.render_text(batch, "PLAYER 1", p1_board_x + 10, board_y - 30, 14, colors.PLAYER1_LABEL, screen_width, screen_height)
    text_renderer.render_text(batch, "PLAYER 2", p2_board_x + 10, board_y - 30, 14, colors.PLAYER2_LABEL, screen_width, screen_height)

    if game_state.player1.game_over then
        local game_over_text = "GAME OVER"
        local text_size = 12
        local text_width = #game_over_text * text_size * 0.6
        local text_x = p1_board_x + (board_width - text_width) / 2
        text_renderer.render_text(batch, game_over_text, text_x, board_y + board_height / 2, text_size, colors.GAME_OVER_TEXT, screen_width, screen_height)
    end

    if game_state.player2.game_over then
        local game_over_text = "GAME OVER"
        local text_size = 12
        local text_width = #game_over_text * text_size * 0.6
        local text_x = p2_board_x + (board_width - text_width) / 2
        text_renderer.render_text(batch, game_over_text, text_x, board_y + board_height / 2, text_size, colors.GAME_OVER_TEXT, screen_width, screen_height)
    end
end

return M
