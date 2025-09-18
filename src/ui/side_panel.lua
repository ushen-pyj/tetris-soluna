-- 侧边栏渲染模块
local renderer = require "src.ui.renderer"
local colors = require "src.core.colors"

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

-- 渲染双人模式侧边栏
function M.render_dual(batch, screen_width, screen_height, game_state)
    local constants = require "src.core.constants"
    local board_width = constants.GRID_COLS * constants.CELL_SIZE
    local board_height = constants.GRID_ROWS * constants.CELL_SIZE
    
    -- 计算双人游戏板位置
    local spacing = 60  -- 两个游戏板之间的间距
    local total_width = board_width * 2 + spacing
    local start_x = (screen_width - total_width) / 2
    local board_y = (screen_height - board_height) / 2
    
    batch:layer(0, 0)
    
    -- Player 1侧边栏（左侧游戏板下方）
    local p1_board_x = start_x
    local p1_side_x = p1_board_x
    local p1_side_y = board_y + board_height + 20
    
    -- Player 1信息
    renderer.render_text(batch, "P1 SCORE: " .. game_state.player1.score, p1_side_x, p1_side_y, 12, colors.PLAYER1_UI)
    renderer.render_text(batch, "P1 LINES: " .. game_state.player1.lines_cleared, p1_side_x, p1_side_y + 15, 12, colors.PLAYER1_UI)
    
    -- Player 1下一块预览
    if game_state.player1.next_kind then
        renderer.render_text(batch, "P1 NEXT:", p1_side_x, p1_side_y + 35, 12, colors.PLAYER1_UI)
        renderer.render_mini_piece(batch, p1_side_x + 10, p1_side_y + 50, game_state.player1.next_kind)
    end
    
    -- Player 2侧边栏（右侧游戏板下方）
    local p2_board_x = start_x + board_width + spacing
    local p2_side_x = p2_board_x
    local p2_side_y = board_y + board_height + 20
    
    -- Player 2信息
    renderer.render_text(batch, "P2 SCORE: " .. game_state.player2.score, p2_side_x, p2_side_y, 12, colors.PLAYER2_UI)
    renderer.render_text(batch, "P2 LINES: " .. game_state.player2.lines_cleared, p2_side_x, p2_side_y + 15, 12, colors.PLAYER2_UI)
    
    -- Player 2下一块预览
    if game_state.player2.next_kind then
        renderer.render_text(batch, "P2 NEXT:", p2_side_x, p2_side_y + 35, 12, colors.PLAYER2_UI)
        renderer.render_mini_piece(batch, p2_side_x + 10, p2_side_y + 50, game_state.player2.next_kind)
    end
    
    -- 共享信息（屏幕顶部中央）
    local center_x = screen_width / 2
    local shared_y = 20
    renderer.render_text(batch, "LEVEL: " .. game_state.level, center_x - 30, shared_y, 14, colors.SHARED_INFO)
    renderer.render_text(batch, "TOTAL LINES: " .. game_state.total_lines_cleared, center_x - 50, shared_y + 20, 12, colors.SHARED_INFO)
    
    -- 控制说明
    local control_y = screen_height - 80
    renderer.render_text(batch, "P1: WASD + SPACE", 20, control_y, 10, colors.CONTROL_HELP)
    renderer.render_text(batch, "P2: 4826 + ENTER", 20, control_y + 15, 10, colors.CONTROL_HELP)
    
    batch:layer()
end

return M
