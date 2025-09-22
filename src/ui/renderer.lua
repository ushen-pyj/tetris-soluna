local quad = require "soluna.material.quad"
local constants = require "src.core.constants"
local colors = require "src.core.colors"
local ui_config = require "src.config.ui_config"
local game_config = require "src.config.game_config"
local text_material = require "soluna.material.text"
local font_api = require "soluna.font"

local M = {}

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

function M.render_next_piece_preview(batch, x, y, next_kind)
    if not next_kind then return end
    
    local preview_cell = ui_config.PREVIEW_CELL_SIZE
    local px = x
    local py = y
    
    batch:layer(0, 0)
    for rr=0,3 do
        for cc=0,3 do
            batch:add(quad.quad(preview_cell-2, preview_cell-2, ui_config.PREVIEW_BACKGROUND_COLOR), 
                     px + cc*preview_cell + 1, py + rr*preview_cell + 1)
        end
    end
    
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
    
    return py + 4*preview_cell + 24
end

function M.render_score_display(batch, x, y, game_state, screen_width, screen_height)
    local sx = x 
    local sy = y
    
    batch:layer(0, 0)
    
    local title_y = sy
    M.render_text(batch, "SCORE", sx, title_y, 12, colors.SCORE_TITLE, screen_width, screen_height)
    
    local score_y = title_y + 18
    local score_text = tostring(game_state.score)
    M.render_text(batch, score_text, sx, score_y, 14, colors.SCORE_VALUE, screen_width, screen_height)
    
    local level_y = score_y + 24
    M.render_text(batch, "LEVEL", sx, level_y, 12, colors.LEVEL_TITLE, screen_width, screen_height)
    
    local level_val_y = level_y + 18
    local level_text = tostring(game_state.level)
    M.render_text(batch, level_text, sx, level_val_y, 14, colors.LEVEL_VALUE, screen_width, screen_height)
    
    local lines_y = level_val_y + 24
    M.render_text(batch, "LINES", sx, lines_y, 12, colors.LINES_TITLE, screen_width, screen_height)
    
    local lines_val_y = lines_y + 18
    local lines_text = tostring(game_state.lines_cleared)
    M.render_text(batch, lines_text, sx, lines_val_y, 14, colors.LINES_VALUE, screen_width, screen_height)
    
    batch:layer()
    
    return lines_val_y + 24 
end

function M.debug_text(batch, text_primitives, x, y)
    local ptr, count = batch:ptr()
    print("Batch after TETRIS: ptr =", ptr, "count =", count, " x = ", x, " y = ", y)
    print("text_primitives type:", type(text_primitives))
    print("text_primitives is string?", type(text_primitives) == "string")
    if #text_primitives >= 16 then
        local first_x = string.unpack("<i4", text_primitives, 1)
        local first_y = string.unpack("<i4", text_primitives, 5)
        print("First char internal coords:", first_x / 256, first_y / 256)
    end
end

function M.render_text(batch, str, x, y, size, color, width, height)
    if not str or str == "" then
        return
    end

    size = size or 16
    color = color or colors.DEFAULT_TEXT

    local font_mgr = font_api.cobj()
    local fixed_color = color
    if (fixed_color & colors.ALPHA_MASK) == 0 then
        fixed_color = fixed_color | colors.ALPHA_MASK
    end
    local font_id = 0
    local name_ok, font_name_id = pcall(font_api.name, "")
    if name_ok and font_name_id then
        font_id = font_name_id
    end

    local test_size = size
    local test_color = fixed_color
    local text_block = text_material.block(font_mgr, font_id, test_size, test_color, "")
    local text_primitives = text_block(str, width, height)
    local font_info = font_api.size(font_id, test_size)
    local offset_y = y - ((height - (font_info.ascent + font_info.descent - font_info.lineGap)) / 2)
    batch:add(text_primitives, x, offset_y)
    if game_config.debug then
        M.debug_text(batch, text_primitives, x, offset_y)
    end
end

function M.render_score_bar(batch, x, y, score)
    local bar_w = ui_config.SCORE_BAR_WIDTH
    local bar_h = ui_config.SCORE_BAR_HEIGHT
    local sx = math.floor(x)
    local sy = math.floor(y)
    
    batch:layer(0, 0)
    batch:add(quad.quad(bar_w, bar_h, ui_config.SCORE_BAR_COLOR), sx, sy)
    local maxw = bar_w - 6
    local ratio = math.min(1, (score % 1000) / 1000)
    local fillw = math.floor(maxw * ratio)
    batch:add(quad.quad(fillw, bar_h-6, ui_config.SCORE_BAR_FILL_COLOR), sx+3, sy+3)
    batch:layer()
end

function M.render_mini_piece(batch, x, y, kind)
    if not kind then return end
    
    local mini_cell = 8 
    local m = M.shape_matrix(kind, 1)
    local col = constants.COLORS[kind]
    
    batch:layer(0, 0)
    for i=1,4 do 
        for j=1,4 do 
            if m[i][j]==1 then
                local mini_x = x + (j-1) * mini_cell
                local mini_y = y + (i-1) * mini_cell
                batch:add(quad.quad(mini_cell-2, mini_cell-2, col), mini_x+1, mini_y+1)
            end 
        end 
    end
    batch:layer()
end

function M.shape_matrix(kind, rot)
    local mats = constants.SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

return M
