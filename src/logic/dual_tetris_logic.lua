local ltask = require "ltask"
local constants = require "src.core.constants"
local game_config = require "src.config.game_config"

local S = {}

local GRID_COLS, GRID_ROWS
local SHAPES

-- 创建新网格
local function new_grid()
    local g = {}
    for r = 1, GRID_ROWS do
        local row = {}
        for c = 1, GRID_COLS do row[c] = false end
        g[r] = row
    end
    return g
end

-- 随机生成下一个形状
local rng = math.random
local bag = {"I","O","T","S","Z","J","L"}
local function next_shape()
    return bag[rng(1,#bag)]
end

-- 双人游戏状态
local state = {
    player1 = {
        grid = nil,
        cur = { kind = nil, rot = 1, r = 1, c = 4 },
        score = 0,
        lines_cleared = 0,
        game_over = false,
        next_kind = nil,
    },
    player2 = {
        grid = nil,
        cur = { kind = nil, rot = 1, r = 1, c = 4 },
        score = 0,
        lines_cleared = 0,
        game_over = false,
        next_kind = nil,
    },
    -- 共享状态
    drop_interval = game_config.DROP_INTERVAL,
    level = 1,
    total_lines_cleared = 0, -- 用于计算共享关卡
}

-- 获取形状矩阵
local function shape_matrix(kind, rot)
    local mats = SHAPES[kind]
    return mats[(rot-1) % #mats + 1]
end

-- 检查是否可以放置
local function can_place(player, kind, rot, r, c)
    local m = shape_matrix(kind, rot)
    for i=1,4 do
        for j=1,4 do
            if m[i][j] == 1 then
                local rr = r + i - 1
                local cc = c + j - 1
                if rr < 1 or rr > GRID_ROWS or cc < 1 or cc > GRID_COLS then
                    return false
                end
                if player.grid[rr][cc] then return false end
            end
        end
    end
    return true
end

-- 锁定当前方块
local function lock_piece(player)
    local m = shape_matrix(player.cur.kind, player.cur.rot)
    for i=1,4 do for j=1,4 do if m[i][j]==1 then
        local rr = player.cur.r + i - 1
        local cc = player.cur.c + j - 1
        player.grid[rr][cc] = player.cur.kind
    end end end
end

-- 清除满行
local function clear_lines(player)
    local new_rows = {}
    local cleared = 0
    for r = GRID_ROWS, 1, -1 do
        local full = true
        for c = 1, GRID_COLS do
            if not player.grid[r][c] then full = false break end
        end
        if full then
            cleared = cleared + 1
        else
            new_rows[#new_rows+1] = player.grid[r]
        end
    end
    
    -- 重建网格
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
    
    -- 更新分数
    if cleared > 0 then
        local gain = game_config.SCORE_BASE * cleared * (game_config.SCORE_MULTIPLIER ^ (cleared - 1))
        player.score = player.score + gain
        player.lines_cleared = player.lines_cleared + cleared
        
        -- 更新总行数和共享关卡
        state.total_lines_cleared = state.total_lines_cleared + cleared
        local new_level = math.floor(state.total_lines_cleared / 20) + 1  -- 双人模式需要更多行数升级
        if new_level > state.level then
            state.level = new_level
            state.drop_interval = math.max(0.1, game_config.DROP_INTERVAL - (state.level - 1) * game_config.LEVEL_SPEED_INCREASE)
        end
    end
    
    return cleared
end

-- 生成新方块
local function spawn(player)
    player.cur.kind = player.next_kind or next_shape()
    player.next_kind = next_shape()
    player.cur.rot = 1
    player.cur.r = 1
    player.cur.c = 4
    if not can_place(player, player.cur.kind, player.cur.rot, player.cur.r, player.cur.c) then
        player.game_over = true
    end
end

-- 检查是否需要新方块
local function new_piece_if_needed(player)
    if not can_place(player, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) then
        lock_piece(player)
        clear_lines(player)
        spawn(player)
    else
        player.cur.r = player.cur.r + 1
    end
end

-- 旋转实现
local function rotate_impl(player)
    local nr = player.cur.rot + 1
    if can_place(player, player.cur.kind, nr, player.cur.r, player.cur.c) then
        player.cur.rot = nr
        return
    end
    -- 尝试墙踢
    if can_place(player, player.cur.kind, nr, player.cur.r, player.cur.c-1) then 
        player.cur.rot = nr 
        player.cur.c = player.cur.c - 1
        return 
    end
    if can_place(player, player.cur.kind, nr, player.cur.r, player.cur.c+1) then 
        player.cur.rot = nr 
        player.cur.c = player.cur.c + 1
        return 
    end
end

-- 硬降实现
local function hard_drop_impl(player)
    while can_place(player, player.cur.kind, player.cur.rot, player.cur.r+1, player.cur.c) do
        player.cur.r = player.cur.r + 1
    end
    lock_piece(player)
    clear_lines(player)
    spawn(player)
end

local running = false

-- 定时器调度
local function schedule_tick()
    if not running then return end
    if not state.player1.game_over then
        new_piece_if_needed(state.player1)
    end
    if not state.player2.game_over then
        new_piece_if_needed(state.player2)
    end
    ltask.timeout(math.floor(state.drop_interval * 60), schedule_tick)
end

-- 服务接口
function S.init(config)
    GRID_COLS = config.GRID_COLS
    GRID_ROWS = config.GRID_ROWS
    SHAPES = config.SHAPES
    
    -- 初始化双方状态
    state.player1.grid = new_grid()
    state.player1.score = 0
    state.player1.lines_cleared = 0
    state.player1.game_over = false
    state.player1.next_kind = next_shape()
    
    state.player2.grid = new_grid()
    state.player2.score = 0
    state.player2.lines_cleared = 0
    state.player2.game_over = false
    state.player2.next_kind = next_shape()
    
    -- 初始化共享状态
    state.level = 1
    state.total_lines_cleared = 0
    state.drop_interval = config.DROP_INTERVAL or game_config.DROP_INTERVAL
    
    spawn(state.player1)
    spawn(state.player2)
    running = true
    schedule_tick()
end

function S.reset()
    -- 重置双方状态
    state.player1.grid = new_grid()
    state.player1.score = 0
    state.player1.lines_cleared = 0
    state.player1.game_over = false
    state.player1.cur.rot = 1
    state.player1.cur.r = 1
    state.player1.cur.c = 4
    
    state.player2.grid = new_grid()
    state.player2.score = 0
    state.player2.lines_cleared = 0
    state.player2.game_over = false
    state.player2.cur.rot = 1
    state.player2.cur.r = 1
    state.player2.cur.c = 4
    
    -- 重置共享状态
    state.level = 1
    state.total_lines_cleared = 0
    state.drop_interval = game_config.DROP_INTERVAL
    
    spawn(state.player1)
    spawn(state.player2)
end

-- 玩家移动
function S.move(player_id, dx, dy)
    local player = (player_id == 1) and state.player1 or state.player2
    if player.game_over then return false end
    local nr, nc = player.cur.r + (dy or 0), player.cur.c + (dx or 0)
    if can_place(player, player.cur.kind, player.cur.rot, nr, nc) then
        player.cur.r, player.cur.c = nr, nc
        return true
    end
    return false
end

function S.soft_drop_step(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    if player.game_over then return end
    new_piece_if_needed(player)
end

function S.rotate(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    if player.game_over then return end
    rotate_impl(player)
end

function S.hard_drop(player_id)
    local player = (player_id == 1) and state.player1 or state.player2
    if player.game_over then return end
    hard_drop_impl(player)
end

function S.snapshot()
    return state
end

function S.quit()
    running = false
end

return S
