-- 主渲染器
local quad = require "soluna.material.quad"
local text = require "soluna.material.text"
local constants = require "src.core.constants"
local ui_config = require "src.config.ui_config"
local ltask = require "ltask"

local M = {}

-- 渲染游戏板背景网格
function M.render_game_board_background(batch, board_x, board_y)
    batch:layer(board_x, board_y)
    for r=1, constants.GRID_ROWS do
        for c=1, constants.GRID_COLS do
            local x = (c-1) * constants.CELL_SIZE
            local y = (r-1) * constants.CELL_SIZE
            batch:add(quad.quad(constants.CELL_SIZE-2, constants.CELL_SIZE-2, constants.COLORS.G), x+1, y+1)
        end
    end
    batch:layer()
end

-- 渲染已固定的方块
function M.render_fixed_pieces(batch, board_x, board_y, grid)
    batch:layer(board_x, board_y)
    for r=1, constants.GRID_ROWS do
        for c=1, constants.GRID_COLS do
            local k = grid[r][c]
            if k then
                local col = constants.COLORS[k]
                local x = (c-1) * constants.CELL_SIZE
                local y = (r-1) * constants.CELL_SIZE
                batch:add(quad.quad(constants.CELL_SIZE-4, constants.CELL_SIZE-4, col), x+2, y+2)
            end
        end
    end
    batch:layer()
end

-- 渲染当前下落的方块
function M.render_current_piece(batch, board_x, board_y, current_piece)
    if not current_piece or not current_piece.kind then return end
    
    local m = M.shape_matrix(current_piece.kind, current_piece.rot)
    local col = constants.COLORS[current_piece.kind]
    
    batch:layer(board_x, board_y)
    for i=1,4 do 
        for j=1,4 do 
            if m[i][j]==1 then
                local r = current_piece.r + i - 1
                local c = current_piece.c + j - 1
                local x = (c-1) * constants.CELL_SIZE
                local y = (r-1) * constants.CELL_SIZE
                batch:add(quad.quad(constants.CELL_SIZE-4, constants.CELL_SIZE-4, col), x+2, y+2)
            end 
        end 
    end
    batch:layer()
end

-- 渲染下一块预览
function M.render_next_piece_preview(batch, x, y, next_kind)
    if not next_kind then return end
    
    local preview_cell = ui_config.PREVIEW_CELL_SIZE
    local px = x
    local py = y
    
    -- 渲染预览背景
    batch:layer(0, 0)
    for rr=0,3 do
        for cc=0,3 do
            batch:add(quad.quad(preview_cell-2, preview_cell-2, ui_config.PREVIEW_BACKGROUND_COLOR), 
                     px + cc*preview_cell + 1, py + rr*preview_cell + 1)
        end
    end
    
    -- 渲染预览方块
    local pm = M.shape_matrix(next_kind, 1)
    local pcol = constants.COLORS[next_kind]
    for i=1,4 do 
        for j=1,4 do 
            if pm[i][j]==1 then
                local preview_x = px + (j-1) * preview_cell
                local preview_y = py + (i-1) * preview_cell
                batch:add(quad.quad(preview_cell-4, preview_cell-4, pcol), preview_x+2, preview_y+2)
            end 
        end 
    end
    batch:layer()
    
    return py + 4*preview_cell + 24  -- 返回下一个渲染位置的y坐标
end

-- 渲染分数显示
function M.render_score_display(batch, x, y, game_state)
    local sx = x
    local sy = y
    
    batch:layer(0, 0)
    
    -- 渲染分数标题
    local title_y = sy
    M.render_text(batch, "SCORE", sx, title_y, 12, 0xFFFFFF)
    
    -- 渲染分数数值
    local score_y = title_y + 18
    local score_text = tostring(game_state.score)
    M.render_text(batch, score_text, sx, score_y, 14, 0xFFFF00)
    
    -- 渲染等级标题
    local level_y = score_y + 24
    M.render_text(batch, "LEVEL", sx, level_y, 12, 0xFFFFFF)
    
    -- 渲染等级数值
    local level_val_y = level_y + 18
    local level_text = tostring(game_state.level)
    M.render_text(batch, level_text, sx, level_val_y, 14, 0x00FF00)
    
    -- 渲染行数标题
    local lines_y = level_val_y + 24
    M.render_text(batch, "LINES", sx, lines_y, 12, 0xFFFFFF)
    
    -- 渲染行数数值
    local lines_val_y = lines_y + 18
    local lines_text = tostring(game_state.lines_cleared)
    M.render_text(batch, lines_text, sx, lines_val_y, 14, 0x00FFFF)
    
    batch:layer()
    
    return lines_val_y + 24  -- 返回下一个渲染位置
end

-- 渲染文本辅助函数（使用方块代替文字作为临时方案）
function M.render_text(batch, str, x, y, size, color)
    local char_x = math.floor(x)
    local char_width = math.floor(size * 0.8)
    local char_height = math.floor(size)
    
    for i = 1, #str do
        -- 使用小方块表示每个字符
        batch:add(quad.quad(char_width, char_height, color), char_x, y)
        char_x = char_x + char_width + 2  -- 字符间距
    end
end

-- 渲染分数条（保留原有功能）
function M.render_score_bar(batch, x, y, score)
    local bar_w = ui_config.SCORE_BAR_WIDTH
    local bar_h = ui_config.SCORE_BAR_HEIGHT
    local sx = math.floor(x)
    local sy = math.floor(y)
    
    batch:layer(0, 0)
    -- 背景条
    batch:add(quad.quad(bar_w, bar_h, ui_config.SCORE_BAR_COLOR), sx, sy)
    -- 填充条（基于分数百分比）
    local maxw = bar_w - 6
    local ratio = math.min(1, (score % 1000) / 1000)
    local fillw = math.floor(maxw * ratio)
    batch:add(quad.quad(fillw, bar_h-6, ui_config.SCORE_BAR_FILL_COLOR), sx+3, sy+3)
    batch:layer()
end

-- 获取形状矩阵（从原代码迁移）
function M.shape_matrix(kind, rot)
    local mats = constants.SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

return M
