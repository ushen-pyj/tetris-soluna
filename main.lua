local quad = require "soluna.material.quad"
local ltask = require "ltask"
local cfg = require "config.game"

local args = ...
local batch = args.batch

-- 配置
local GRID_COLS = cfg.GRID_COLS
local GRID_ROWS = cfg.GRID_ROWS
local CELL = cfg.CELL
local BOARD_X = math.floor((args.width - GRID_COLS * CELL) / 2)
local BOARD_Y = math.floor((args.height - GRID_ROWS * CELL) / 2)

local COLORS = cfg.COLORS
local SHAPES = cfg.SHAPES

local function shape_matrix(kind, rot)
    local mats = SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

local logic_addr
local snapshot

local function ensure_logic()
    if not logic_addr then
        logic_addr = ltask.uniqueservice "service.tetris_logic"
        ltask.call(logic_addr, "init", cfg)
    end
end

local callback = {}

function callback.mouse_button(btn, down)
    ensure_logic()
    if down and snapshot and snapshot.game_over then
        ltask.call(logic_addr, "reset")
    end
end

function callback.char(code)
    ensure_logic()
    if not snapshot or snapshot.game_over then return end
    if code == 0x20 then
        ltask.call(logic_addr, "hard_drop")
        return
    end
    if code >= 65 and code <= 90 then
        code = code + 32
    end
    if code == string.byte('a') or code == string.byte('j') then
        ltask.call(logic_addr, "move", -1, 0)
    elseif code == string.byte('d') or code == string.byte('l') then
        ltask.call(logic_addr, "move", 1, 0)
    elseif code == string.byte('s') or code == string.byte('k') then
        ltask.call(logic_addr, "soft_drop_step")
    elseif code == string.byte('w') or code == string.byte('i') then
        ltask.call(logic_addr, "rotate")
    end
end

function callback.frame(count)
    ensure_logic()
    snapshot = ltask.call(logic_addr, "snapshot")

    local grid = snapshot.grid
    local cur = snapshot.cur
    local game_over = snapshot.game_over
    local next_kind = snapshot.next_kind
    local score = snapshot.score

    batch:layer(BOARD_X, BOARD_Y)
        for r=1,GRID_ROWS do
            for c=1,GRID_COLS do
                local x = (c-1) * CELL
                local y = (r-1) * CELL
                batch:add(quad.quad(CELL-2, CELL-2, COLORS.G), x+1, y+1)
            end
        end

        for r=1,GRID_ROWS do
            for c=1,GRID_COLS do
                local k = grid[r][c]
                if k then
                    local col = COLORS[k]
                    local x = (c-1) * CELL
                    local y = (r-1) * CELL
                    batch:add(quad.quad(CELL-4, CELL-4, col), x+2, y+2)
                end
            end
        end

        if not game_over then
            local m = shape_matrix(cur.kind, cur.rot)
            local col = COLORS[cur.kind]
            for i=1,4 do for j=1,4 do if m[i][j]==1 then
                local r = cur.r + i - 1
                local c = cur.c + j - 1
                local x = (c-1) * CELL
                local y = (r-1) * CELL
                batch:add(quad.quad(CELL-4, CELL-4, col), x+2, y+2)
            end end end
        end
    batch:layer()

    -- 右侧面板：预览下一块 + 分数
    local side_x = BOARD_X + GRID_COLS * CELL + 24
    local side_y = BOARD_Y
    batch:layer(0, 0)
        -- 预览标题框（简单用方块拼）
        if next_kind then
            local preview_cell = math.floor(CELL * 0.8)
            local px = side_x
            local py = side_y
            -- 背板
            for rr=0,3 do
                for cc=0,3 do
                    batch:add(quad.quad(preview_cell-2, preview_cell-2, 0x2a2a2a), px + cc*preview_cell + 1, py + rr*preview_cell + 1)
                end
            end
            local pm = shape_matrix(next_kind, 1)
            local pcol = COLORS[next_kind]
            for i=1,4 do for j=1,4 do if pm[i][j]==1 then
                local x = px + (j-1) * preview_cell
                local y = py + (i-1) * preview_cell
                batch:add(quad.quad(preview_cell-4, preview_cell-4, pcol), x+2, y+2)
            end end end
            side_y = py + 4*preview_cell + 24
        end

        -- 分数：用固定宽度条形显示（每一位用十个格组成的数码管简化为长度条叠加）
        do
            local bar_w = CELL * 3
            local bar_h = CELL - 8
            local sx = side_x
            local sy = side_y
            batch:add(quad.quad(bar_w, bar_h, 0x444444), sx, sy)
            local maxw = bar_w - 6
            local ratio = math.min(1, (score % 1000) / 1000)
            local fillw = math.floor(maxw * ratio)
            batch:add(quad.quad(fillw, bar_h-6, 0xf0c808), sx+3, sy+3)
            -- 分数格子提示（千分位循环，不依赖文字材质）
        end
    batch:layer()
end

return callback


