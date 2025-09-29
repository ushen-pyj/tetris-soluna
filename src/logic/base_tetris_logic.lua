local game_config = require "src.config.game_config"

local BaseTetrisLogic = {}

local GRID_COLS, GRID_ROWS
local SHAPES

local rng = math.random
local bag = {"I","O","T","S","Z","J","L"}

function BaseTetrisLogic.new_grid()
    local g = {}
    for r = 1, GRID_ROWS do
        local row = {}
        for c = 1, GRID_COLS do row[c] = false end
        g[r] = row
    end
    return g
end

function BaseTetrisLogic.next_shape()
    return bag[rng(1, #bag)]
end

function BaseTetrisLogic.new_player_state()
    return {
        grid = BaseTetrisLogic.new_grid(),
        cur = { kind = nil, rot = 1, r = 1, c = 4 },
        score = 0,
        lines_cleared = 0,
        game_over = false,
        next_kind = nil,
    }
end

function BaseTetrisLogic.shape_matrix(kind, rot)
    local mats = SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

function BaseTetrisLogic.can_place(grid, kind, rot, r, c)
    local m = BaseTetrisLogic.shape_matrix(kind, rot)
    for i=1,4 do
        for j=1,4 do
            if m[i][j] == 1 then
                local rr = r + i - 1
                local cc = c + j - 1
                if cc < 1 or cc > GRID_COLS then
                    return false
                end
                if rr > GRID_ROWS then
                    return false
                end
                -- 允许在棋盘上方（rr < 1）作为可放置区域
                if rr >= 1 then
                    if grid[rr][cc] then return false end
                end
            end
        end
    end
    return true
end

function BaseTetrisLogic.lock_piece(player)
    local m = BaseTetrisLogic.shape_matrix(player.cur.kind, player.cur.rot)
    for i=1,4 do 
        for j=1,4 do 
            if m[i][j]==1 then
                local rr = player.cur.r + i - 1
                local cc = player.cur.c + j - 1
                if rr >= 1 and rr <= GRID_ROWS and cc >= 1 and cc <= GRID_COLS then
                    player.grid[rr][cc] = player.cur.kind
                end
            end 
        end 
    end
end

function BaseTetrisLogic.clear_lines(player)
    local new_rows = {}
    local cleared = 0

    for r = GRID_ROWS, 1, -1 do
        local full = true
        for c = 1, GRID_COLS do
            if not player.grid[r][c] then 
                full = false 
                break 
            end
        end
        if full then
            cleared = cleared + 1
        else
            new_rows[#new_rows+1] = player.grid[r]
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
    player.grid = rebuilt

    if cleared > 0 then
        local gain = game_config.SCORE_BASE * cleared * (game_config.SCORE_MULTIPLIER ^ (cleared - 1))
        player.score = player.score + gain
        player.lines_cleared = player.lines_cleared + cleared
    end

    return cleared
end

function BaseTetrisLogic.spawn(player)
    player.cur.kind = player.next_kind or BaseTetrisLogic.next_shape()
    player.next_kind = BaseTetrisLogic.next_shape()
    player.cur.rot = 1
    -- 让方块的最上边实心行对齐到第1行，避免看起来从第2行开始
    do
        local m = BaseTetrisLogic.shape_matrix(player.cur.kind, player.cur.rot)
        local top_i = 4
        for i = 1, 4 do
            local occupied = false
            for j = 1, 4 do
                if m[i][j] == 1 then
                    occupied = true
                    break
                end
            end
            if occupied then
                top_i = i
                break
            end
        end
        -- 计算初始r，使 top_i 对应的实际棋盘行 = 0（第一行之上）
        player.cur.r = 1 - top_i
    end
    player.cur.c = 4
    if not BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, player.cur.r, player.cur.c) then
        player.game_over = true
    end
end

function BaseTetrisLogic.new_piece_if_needed(player)
    if not BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) then
        BaseTetrisLogic.lock_piece(player)
        local cleared = BaseTetrisLogic.clear_lines(player)
        BaseTetrisLogic.spawn(player)
        return cleared
    else
        player.cur.r = player.cur.r + 1
        return 0
    end
end

function BaseTetrisLogic.rotate(player)
    if player.game_over then return false end

    local nr = player.cur.rot + 1

    if BaseTetrisLogic.can_place(player.grid, player.cur.kind, nr, player.cur.r, player.cur.c) then
        player.cur.rot = nr
        return true
    end

    if BaseTetrisLogic.can_place(player.grid, player.cur.kind, nr, player.cur.r, player.cur.c-1) then 
        player.cur.rot = nr 
        player.cur.c = player.cur.c - 1
        return true
    end

    if BaseTetrisLogic.can_place(player.grid, player.cur.kind, nr, player.cur.r, player.cur.c+1) then 
        player.cur.rot = nr 
        player.cur.c = player.cur.c + 1
        return true
    end

    return false
end

function BaseTetrisLogic.hard_drop(player)
    if player.game_over then return 0 end

    while BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) do
        player.cur.r = player.cur.r + 1
    end

    BaseTetrisLogic.lock_piece(player)
    local cleared = BaseTetrisLogic.clear_lines(player)
    BaseTetrisLogic.spawn(player)
    return cleared
end

function BaseTetrisLogic.move(player, dx, dy)
    if player.game_over then return false end

    local nr, nc = player.cur.r + (dy or 0), player.cur.c + (dx or 0)
    if BaseTetrisLogic.can_place(player.grid, player.cur.kind, player.cur.rot, nr, nc) then
        player.cur.r, player.cur.c = nr, nc
        return true
    end
    return false
end

function BaseTetrisLogic.reset_player(player)
    player.grid = BaseTetrisLogic.new_grid()
    player.score = 0
    player.lines_cleared = 0
    player.game_over = false
    player.cur.rot = 1
    player.cur.r = 1
    player.cur.c = 4
    player.next_kind = BaseTetrisLogic.next_shape()
    BaseTetrisLogic.spawn(player)
end

function BaseTetrisLogic.init(config)
    GRID_COLS = config.GRID_COLS
    GRID_ROWS = config.GRID_ROWS
    SHAPES = config.SHAPES
end

function BaseTetrisLogic.get_config()
    return {
        GRID_COLS = GRID_COLS,
        GRID_ROWS = GRID_ROWS,
        SHAPES = SHAPES
    }
end

return BaseTetrisLogic
