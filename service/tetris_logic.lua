local ltask = require "ltask"

local S = {}

local cfg

local GRID_COLS, GRID_ROWS
local SHAPES

local function new_grid()
    local g = {}
    for r = 1, GRID_ROWS do
        local row = {}
        for c = 1, GRID_COLS do row[c] = false end
        g[r] = row
    end
    return g
end

local rng = math.random
local bag = {"I","O","T","S","Z","J","L"}
local function next_shape()
    return bag[rng(1,#bag)]
end

local state = {
    grid = nil,
    cur = { kind = nil, rot = 1, r = 1, c = 4 },
    drop_interval = 0.6,
    score = 0,
    game_over = false,
    next_kind = nil,
}

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
                if state.grid[rr][cc] then return false end
            end
        end
    end
    return true
end

local function lock_piece()
    local m = shape_matrix(state.cur.kind, state.cur.rot)
    for i=1,4 do for j=1,4 do if m[i][j]==1 then
        local rr = state.cur.r + i - 1
        local cc = state.cur.c + j - 1
        state.grid[rr][cc] = state.cur.kind
    end end end
end

local function clear_lines()
    local new_rows = {}
    local cleared = 0
    for r = GRID_ROWS, 1, -1 do
        local full = true
        for c = 1, GRID_COLS do
            if not state.grid[r][c] then full = false break end
        end
        if full then
            cleared = cleared + 1
        else
            new_rows[#new_rows+1] = state.grid[r]
        end
    end
    for i = 1, cleared do
        local row = {}
        for c = 1, GRID_COLS do row[c] = false end
        new_rows[#new_rows+1] = row
    end
    local rebuilt = {}
    for i = #new_rows, 1, -1 do
        rebuilt[#rebuilt+1] = new_rows[i]
    end
    state.grid = rebuilt
    if cleared > 0 then
        local gain = 100 * cleared * (2 ^ (cleared - 1))
        state.score = state.score + gain
    end
end

local function spawn()
    state.cur.kind = state.next_kind or next_shape()
    state.next_kind = next_shape()
    state.cur.rot = 1
    state.cur.r = 1
    state.cur.c = 4
    if not can_place(state.cur.kind, state.cur.rot, state.cur.r, state.cur.c) then
        state.game_over = true
    end
end

local function new_piece_if_needed()
    if not can_place(state.cur.kind, state.cur.rot, state.cur.r+1, state.cur.c) then
        lock_piece()
        clear_lines()
        spawn()
    else
        state.cur.r = state.cur.r + 1
    end
end

local function rotate_impl()
    local nr = state.cur.rot + 1
    if can_place(state.cur.kind, nr, state.cur.r, state.cur.c) then
        state.cur.rot = nr
        return
    end
    if can_place(state.cur.kind, nr, state.cur.r, state.cur.c-1) then state.cur.rot = nr return end
    if can_place(state.cur.kind, nr, state.cur.r, state.cur.c+1) then state.cur.rot = nr return end
end

local function hard_drop_impl()
    while can_place(state.cur.kind, state.cur.rot, state.cur.r+1, state.cur.c) do
        state.cur.r = state.cur.r + 1
    end
    lock_piece()
    clear_lines()
    spawn()
end

local running = false

local function schedule_tick()
    if not running then return end
    if not state.game_over then
        new_piece_if_needed()
    end
    ltask.timeout(math.floor(state.drop_interval * 60), schedule_tick)
end

function S.init(config)
    cfg = config
    GRID_COLS = cfg.GRID_COLS
    GRID_ROWS = cfg.GRID_ROWS
    SHAPES = cfg.SHAPES
    state.grid = new_grid()
    state.score = 0
    state.game_over = false
    state.drop_interval = 0.6
    state.next_kind = next_shape()
    spawn()
    running = true
    schedule_tick()
end

function S.reset()
    state.grid = new_grid()
    state.score = 0
    state.game_over = false
    state.cur.rot = 1
    state.cur.r = 1
    state.cur.c = 4
    spawn()
end

function S.move(dx, dy)
    if state.game_over then return false end
    local nr, nc = state.cur.r + (dy or 0), state.cur.c + (dx or 0)
    if can_place(state.cur.kind, state.cur.rot, nr, nc) then
        state.cur.r, state.cur.c = nr, nc
        return true
    end
    return false
end

function S.soft_drop_step()
    if state.game_over then return end
    new_piece_if_needed()
end

function S.rotate()
    if state.game_over then return end
    rotate_impl()
end

function S.hard_drop()
    if state.game_over then return end
    hard_drop_impl()
end

function S.snapshot()
    return state
end

function S.quit()
    running = false
end

return S



