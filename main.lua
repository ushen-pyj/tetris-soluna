local quad = require "soluna.material.quad"

local args = ...
local batch = args.batch

-- 配置
local GRID_COLS = 10
local GRID_ROWS = 20
local CELL = 28
local BOARD_X = math.floor((args.width - GRID_COLS * CELL) / 2)
local BOARD_Y = math.floor((args.height - GRID_ROWS * CELL) / 2)

-- 形状定义（I O T S Z J L）旋转态
local SHAPES = {
    I = {
        {{0,1,0,0},{0,1,0,0},{0,1,0,0},{0,1,0,0}},
        {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}},
    },
    O = {
        {{0,0,0,0},{0,1,1,0},{0,1,1,0},{0,0,0,0}},
    },
    T = {
        {{0,0,0,0},{1,1,1,0},{0,1,0,0},{0,0,0,0}},
        {{0,1,0,0},{1,1,0,0},{0,1,0,0},{0,0,0,0}},
        {{0,1,0,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,1,0},{0,1,0,0},{0,0,0,0}},
    },
    S = {
        {{0,0,0,0},{0,1,1,0},{1,1,0,0},{0,0,0,0}},
        {{1,0,0,0},{1,1,0,0},{0,1,0,0},{0,0,0,0}},
    },
    Z = {
        {{0,0,0,0},{1,1,0,0},{0,1,1,0},{0,0,0,0}},
        {{0,1,0,0},{1,1,0,0},{1,0,0,0},{0,0,0,0}},
    },
    J = {
        {{0,0,0,0},{1,1,1,0},{0,0,1,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,0,0},{1,1,0,0},{0,0,0,0}},
        {{1,0,0,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,1,0},{0,1,0,0},{0,1,0,0},{0,0,0,0}},
    },
    L = {
        {{0,0,0,0},{1,1,1,0},{1,0,0,0},{0,0,0,0}},
        {{1,1,0,0},{0,1,0,0},{0,1,0,0},{0,0,0,0}},
        {{0,0,1,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,0,0},{0,1,1,0},{0,0,0,0}},
    },
}

local COLORS = {
    I = 0x17bebb,
    O = 0xfad000,
    T = 0x9b5de5,
    S = 0x00c2a8,
    Z = 0xff595e,
    J = 0x277da1,
    L = 0xf9844a,
    G = 0x1f1f1f, -- grid
}

local function new_grid()
    local g = {}
    for r=1,GRID_ROWS do
        local row = {}
        for c=1,GRID_COLS do row[c] = false end
        g[r] = row
    end
    return g
end

local grid = new_grid()

local rng = math.random
local bag = {"I","O","T","S","Z","J","L"}
local function next_shape()
    return bag[rng(1,#bag)]
end

local cur = {kind=nil, rot=1, r=1, c=4}
local drop_timer = 0
local drop_interval = 0.6
local score = 0
local game_over = false

local function shape_matrix(kind, rot)
    local mats = SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

local function can_place(kind, rot, r, c)
    local m = shape_matrix(kind, rot)
    for i=1,4 do
        for j=1,4 do
            if m[i][j] == 1 then
                local rr = r + i - 1
                local cc = c + j - 1
                if rr < 1 or rr > GRID_ROWS or cc < 1 or cc > GRID_COLS then
                    return false
                end
                if grid[rr][cc] then return false end
            end
        end
    end
    return true
end

local function lock_piece()
    local m = shape_matrix(cur.kind, cur.rot)
    for i=1,4 do for j=1,4 do if m[i][j]==1 then
        local rr = cur.r + i - 1
        local cc = cur.c + j - 1
        grid[rr][cc] = cur.kind
    end end end
end

local function spawn()
    cur.kind = next_shape()
    cur.rot = 1
    cur.r = 1
    cur.c = 4
    if not can_place(cur.kind, cur.rot, cur.r, cur.c) then
        game_over = true
    end
end

local function clear_lines()
    local cleared = 0
    for r=GRID_ROWS,1,-1 do
        local full = true
        for c=1,GRID_COLS do if not grid[r][c] then full=false break end end
        if full then
            table.remove(grid, r)
            table.insert(grid, 1, (function()
                local row = {}
                for c=1,GRID_COLS do row[c]=false end
                return row
            end)())
            cleared = cleared + 1
        end
    end
    if cleared == 1 then score = score + 100
    elseif cleared == 2 then score = score + 300
    elseif cleared == 3 then score = score + 500
    elseif cleared >= 4 then score = score + 800 end
end

local function hard_drop()
    while can_place(cur.kind, cur.rot, cur.r+1, cur.c) do
        cur.r = cur.r + 1
    end
    lock_piece()
    clear_lines()
    spawn()
end

local function move(dx, dy)
    local nr, nc = cur.r + dy, cur.c + dx
    if can_place(cur.kind, cur.rot, nr, nc) then
        cur.r, cur.c = nr, nc
        return true
    end
end

local function rotate()
    local nr = cur.rot + 1
    if can_place(cur.kind, nr, cur.r, cur.c) then
        cur.rot = nr
        return
    end
    -- 简单踢墙
    if can_place(cur.kind, nr, cur.r, cur.c-1) then cur.rot = nr return end
    if can_place(cur.kind, nr, cur.r, cur.c+1) then cur.rot = nr return end
end

local function new_piece_if_needed()
    if not can_place(cur.kind, cur.rot, cur.r+1, cur.c) then
        lock_piece()
        clear_lines()
        spawn()
    else
        cur.r = cur.r + 1
    end
end

spawn()

local callback = {}

function callback.mouse_button(btn, down)
    if down and game_over then
        grid = new_grid()
        score = 0
        game_over = false
        spawn()
    end
end

function callback.char(code)
    if game_over then return end
    if code == 0x20 then -- space 硬降
        hard_drop()
        return
    end
    -- 方向键在当前引擎不会作为 char 事件派发，改用字符键
    -- 支持两套：WASD 与 IJKL
    -- 统一转小写处理
    if code >= 65 and code <= 90 then -- 'A'..'Z'
        code = code + 32
    end
    if code == string.byte('a') or code == string.byte('j') then
        move(-1, 0)
    elseif code == string.byte('d') or code == string.byte('l') then
        move(1, 0)
    elseif code == string.byte('s') or code == string.byte('k') then
        new_piece_if_needed()
    elseif code == string.byte('w') or code == string.byte('i') then
        rotate()
    end
end

function callback.frame(count)
    batch:layer(BOARD_X, BOARD_Y)
        -- 背景
        for r=1,GRID_ROWS do
            for c=1,GRID_COLS do
                local x = (c-1) * CELL
                local y = (r-1) * CELL
                batch:add(quad.quad(CELL-2, CELL-2, COLORS.G), x+1, y+1)
            end
        end

        -- 固定块
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

        -- 当前下落块
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

    -- 下落节奏
    if not game_over then
        drop_timer = drop_timer + 1/60
        if drop_timer >= drop_interval then
            drop_timer = drop_timer - drop_interval
            new_piece_if_needed()
        end
    end
end

return callback


