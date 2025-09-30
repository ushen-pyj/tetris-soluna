
-- Pierre Dellacherie One-Piece Controller
-- 这是俄罗斯方块AI领域的经典算法之一
-- 
-- 📚 参考论文和资料：
--
-- 1. **原始算法来源**：
--    - Pierre Dellacherie (法国程序员) 在2003年提出的启发式评估函数
--    - 被广泛应用于俄罗斯方块AI竞赛和研究中
--
-- 2. **经典文献**：
--    - "Building Controllers for Tetris" 
--      by Thierry Schelcher and Sébastien Collette (University of Liège)
--    - Colin Fahey's Tetris AI Research (2003-2006)
--      经典网页：colinw.fahey.googlepages.com/tetris (已失效，可用Web Archive查看)
--      https://web.archive.org/web/20070815000000*/colinw.fahey.googlepages.com/tetris
--
-- 3. **中文参考资料**：
--    - 《算法的乐趣（第2版）》第22章 - 俄罗斯方块游戏的AI算法
--      作者：王晓华、吕杰  机械工业出版社，2018
--    - CSDN博客：基于Pierre Dellacherie的俄罗斯方块AI实现
--      https://blog.csdn.net/u014604753/article/details/129582774
--    - SegmentFault：鹅罗斯方块 Pierre Dellacherie算法实现
--      https://segmentfault.com/a/1190000040460501
--
-- 4. **GitHub实现参考**：
--    - https://github.com/esrrhs/tetris (优化版实现)
--    - https://github.com/dionyziz/canvas-tetris (JavaScript实现)
--
-- 5. **学术论文**：
--    - 许子明, 吕杰. "基于Pierre Dellacherie算法的俄罗斯方块游戏的实现"
--      科学技术创新, 2018(05):89-90
--
-- 📊 该算法使用6个特征来评估棋盘状态：
-- 1. Landing Height: 方块着陆的高度
-- 2. Eroded Piece Cells: 消除的方块单元数
-- 3. Row Transitions: 行变换数（从有到无，或从无到有）
-- 4. Column Transitions: 列变换数
-- 5. Holes: 空洞数量
-- 6. Wells: 井的深度总和
--
-- ⚠️  本实现新增第7个特征：
-- 7. Height Stddev: 列高度标准差（惩罚高度不平衡）

local M = {}
local BaseTetrisLogic = require "src.logic.base_tetris_logic"

-- 调试控制：打印每个 evaluate 结果
M.DEBUG_EVAL = false              -- 设为 true 开启逐摆放调试输出
M.DEBUG_FILTER_KIND = "I"         -- 可设为 "I" 等，仅打印该种方块；nil 表示不过滤

-- 优化后的权重（基于El-Tetris，并针对边界列问题调整）
M.WEIGHTS = {
    landing_height = -4.500158825082766,
    eroded_cells = 3.4181268101392694,
    row_transitions = -3.2178882868487753,
    col_transitions = -9.348695305445199,
    holes = -7.899265427351652,
    wells = -3.3855972247263626,
    -- 新增：列高度标准差（惩罚高度不平衡）
    -- 大幅增加权重，强制填平空列
    height_stddev = -10.0,  -- 从-2.0增加到-10.0
}

-- 计算方块着陆的高度
-- landing_height = 方块重心的行号（从底部算起）
local function calculate_landing_height(grid, kind, rot, final_row, final_col, SHAPES)
    local m = BaseTetrisLogic.shape_matrix(kind, rot)
    local rows = #grid
    local sum_r = 0
    local count = 0
    
    for i = 1, 4 do
        for j = 1, 4 do
            if m[i][j] == 1 then
                local rr = final_row + i - 1
                if rr >= 1 and rr <= rows then
                    sum_r = sum_r + (rows - rr + 1)  -- 从底部算起的高度
                    count = count + 1
                end
            end
        end
    end
    
    return count > 0 and (sum_r / count) or 0
end

-- 计算消除的方块单元数（Eroded Piece Cells）
-- eroded_cells = 消除的行数 × 本方块在被消除行中的方块数
local function calculate_eroded_cells(grid_before, grid_after, kind, rot, final_row, final_col, SHAPES)
    local m = BaseTetrisLogic.shape_matrix(kind, rot)
    local rows = #grid_before
    
    -- 找出哪些行被消除了
    local cleared_rows = {}
    for r = 1, rows do
        local before_full = true
        for c = 1, #grid_before[1] do
            if not grid_before[r][c] then
                before_full = false
                break
            end
        end
        
        if before_full then
            table.insert(cleared_rows, r)
        end
    end
    
    if #cleared_rows == 0 then
        return 0
    end
    
    -- 计算本方块在被消除行中的单元数
    local piece_cells_in_cleared = 0
    for _, row in ipairs(cleared_rows) do
        for i = 1, 4 do
            for j = 1, 4 do
                if m[i][j] == 1 then
                    local rr = final_row + i - 1
                    if rr == row then
                        piece_cells_in_cleared = piece_cells_in_cleared + 1
                    end
                end
            end
        end
    end
    
    return #cleared_rows * piece_cells_in_cleared
end

-- 计算行变换数（Row Transitions）
-- 行变换：在同一行中，从有方块到无方块，或从无方块到有方块的次数
-- 边界也算作"有方块"
local function calculate_row_transitions(grid)
    local rows = #grid
    local cols = #grid[1]
    local transitions = 0
    
    for r = 1, rows do
        local last = true  -- 左边界视为有方块
        for c = 1, cols do
            local current = grid[r][c] and true or false
            if current ~= last then
                transitions = transitions + 1
            end
            last = current
        end
        -- 右边界
        if not last then
            transitions = transitions + 1
        end
    end
    
    return transitions
end

-- 计算列变换数（Column Transitions）
-- 列变换：在同一列中，从有方块到无方块，或从无方块到有方块的次数
-- 标准定义：底部边界算"有方块"，顶部边界算"无方块"
local function calculate_col_transitions(grid)
    local rows = #grid
    local cols = #grid[1]
    local transitions = 0
    
    for c = 1, cols do
        local last = true  -- 底部边界视为"有方块"
        
        -- 从下往上扫描
        for r = rows, 1, -1 do
            local current = grid[r][c] and true or false
            if current ~= last then
                transitions = transitions + 1
            end
            last = current
        end
        
        -- 顶部边界视为"无方块"
        -- 如果最上面一行是有方块，需要加一个transition
        if last then
            transitions = transitions + 1
        end
    end
    
    return transitions
end

-- 计算空洞数（Holes）
-- 空洞：在某列中，方块下方的空格
local function calculate_holes(grid)
    local rows = #grid
    local cols = #grid[1]
    local holes = 0
    
    for c = 1, cols do
        local block_seen = false
        for r = 1, rows do
            if grid[r][c] then
                block_seen = true
            elseif block_seen then
                holes = holes + 1
            end
        end
    end
    
    return holes
end

-- 计算列高度的标准差（新增特征，解决边界列问题）
-- 标准差越大，说明各列高度差异越大
local function calculate_height_stddev(grid)
    local rows = #grid
    local cols = #grid[1]
    
    -- 计算每列高度
    local heights = {}
    for c = 1, cols do
        heights[c] = 0
        for r = 1, rows do
            if grid[r][c] then
                heights[c] = rows - r + 1
                break
            end
        end
    end
    
    -- 计算平均高度
    local sum = 0
    for c = 1, cols do
        sum = sum + heights[c]
    end
    local mean = sum / cols
    
    -- 计算方差
    local variance = 0
    for c = 1, cols do
        local diff = heights[c] - mean
        variance = variance + diff * diff
    end
    variance = variance / cols
    
    -- 返回标准差
    return math.sqrt(variance)
end

-- 计算井深度总和（Well Sums）
-- 井：连续的被左右**方块**包围的空格（墙壁不算包围！）
-- 深度采用求和公式：1+2+3+...+depth
local function calculate_wells(grid)
    local rows = #grid
    local cols = #grid[1]
    local wells_sum = 0
    
    for c = 1, cols do
        -- 从下往上扫描每一列
        local r = rows
        while r >= 1 do
            -- 如果当前格子是空的
            if not grid[r][c] then
                -- 检查左右是否被**方块**包围（注意：墙壁不算！）
                local has_left = c > 1
                local has_right = c < cols
                local left_blocked = has_left and (grid[r][c-1] and true or false)
                local right_blocked = has_right and (grid[r][c+1] and true or false)
                
                -- 只有被两个实际方块包围才算井
                if has_left and has_right and left_blocked and right_blocked then
                    -- 找到一个井的起点，计算连续的深度
                    local depth = 0
                    local rr = r
                    while rr >= 1 and not grid[rr][c] do
                        local left_ok = grid[rr][c-1] and true or false
                        local right_ok = grid[rr][c+1] and true or false
                        if left_ok and right_ok then
                            depth = depth + 1
                            rr = rr - 1
                        else
                            break
                        end
                    end
                    -- 使用求和公式：1+2+...+depth = depth*(depth+1)/2
                    if depth > 0 then
                        wells_sum = wells_sum + depth * (depth + 1) / 2
                    end
                    -- 跳过已经计算过的井
                    r = rr
                else
                    r = r - 1
                end
            else
                r = r - 1
            end
        end
    end
    
    return wells_sum
end

-- 移除封装：调用处直接使用 BaseTetrisLogic.shape_matrix

function M.clone_grid(grid)
    local g = {}
    for r = 1, #grid do
        local row = {}
        for c = 1, #grid[1] do
            row[c] = grid[r][c]
        end
        g[r] = row
    end
    return g
end

-- 移除封装：调用处直接使用 BaseTetrisLogic.can_place

-- 移除封装：调用处直接包装 player 并调用 BaseTetrisLogic.lock_piece

-- 移除封装：调用处直接包装 player 并调用 BaseTetrisLogic.clear_lines

-- 评估一个落子位置
-- 返回评分和详细信息
function M.evaluate_move(grid, SHAPES, kind, rot, col)
    local rows = #grid
    
    -- 找到形状的顶部
    local m = BaseTetrisLogic.shape_matrix(kind, rot)
    local top_i = 4
    for i = 1, 4 do
        local occ = false
        for j = 1, 4 do
            if m[i][j] == 1 then
                occ = true
                break
            end
        end
        if occ then
            top_i = i
            break
        end
    end
    
    -- 从顶部开始下落
    local r = 1 - top_i
    if not BaseTetrisLogic.can_place(grid, kind, rot, r, col) then
        -- 调试：记录不可放置的位置
        if M.DEBUG_EVAL and (not M.DEBUG_FILTER_KIND or M.DEBUG_FILTER_KIND == kind) then
            print(string.format("[EVAL] kind=%s rot=%d col=%d -> INVALID", tostring(kind), rot, col))
        end
        return nil  -- 无法放置
    end
    
    -- 模拟下落到底部
    while BaseTetrisLogic.can_place(grid, kind, rot, r + 1, col) do
        r = r + 1
    end
    
    -- 计算着陆高度
    local landing_height = calculate_landing_height(grid, kind, rot, r, col, SHAPES)
    
    -- 锁定方块（在副本上）
    local grid_before = M.clone_grid(grid)
    do
        local player = { grid = grid_before, cur = { kind = kind, rot = rot, r = r, c = col } }
        BaseTetrisLogic.lock_piece(player)
    end
    
    -- 清除行
    local grid_after, lines_cleared
    do
        local player = { grid = grid_before, score = 0, lines_cleared = 0 }
        local cleared = BaseTetrisLogic.clear_lines(player)
        grid_after, lines_cleared = player.grid, cleared
    end
    
    -- 计算各项特征
    local eroded_cells = calculate_eroded_cells(grid_before, grid_after, kind, rot, r, col, SHAPES)
    local row_transitions = calculate_row_transitions(grid_after)
    local col_transitions = calculate_col_transitions(grid_after)
    local holes = calculate_holes(grid_after)
    local wells = calculate_wells(grid_after)
    local height_stddev = calculate_height_stddev(grid_after)
    
    -- 计算总评分
    local score = M.WEIGHTS.landing_height * landing_height
        + M.WEIGHTS.eroded_cells * eroded_cells
        + M.WEIGHTS.row_transitions * row_transitions
        + M.WEIGHTS.col_transitions * col_transitions
        + M.WEIGHTS.holes * holes
        + M.WEIGHTS.wells * wells
        + M.WEIGHTS.height_stddev * height_stddev
    
    local details = {
        row = r,
        col = col,
        landing_height = landing_height,
        eroded_cells = eroded_cells,
        row_transitions = row_transitions,
        col_transitions = col_transitions,
        holes = holes,
        wells = wells,
        height_stddev = height_stddev,
        lines_cleared = lines_cleared,
    }

    -- 调试：打印每个可放置位置的评分与特征
    if M.DEBUG_EVAL and (not M.DEBUG_FILTER_KIND or M.DEBUG_FILTER_KIND == kind) then
        print(string.format(
            "[EVAL] kind=%s rot=%d col=%d score=%.3f | lines=%d eroded=%d landing=%.2f rowT=%d colT=%d holes=%d wells=%.2f hstd=%.2f",
            tostring(kind), rot, col, score,
            details.lines_cleared or 0,
            details.eroded_cells or 0,
            details.landing_height or 0,
            details.row_transitions or 0,
            details.col_transitions or 0,
            details.holes or 0,
            details.wells or 0,
            details.height_stddev or 0
        ))
        for row = 1, #grid_after do
            local line = string.format("第%2d行: ", row)
            for col = 1, #grid_after[1] do
                line = line .. (grid_after[row][col] and "1" or ".")
            end
            print(line)
        end
    end

    return score, details
end

-- 搜索最佳落子位置
function M.search_best_move(grid, SHAPES, kind, current_rot, current_col)
    local cols = #grid[1]
    local best = {
        score = -math.huge,
        rot = current_rot,
        col = current_col,
        details = nil
    }
    
    -- 遍历所有可能的旋转和列
    for rot = 1, 4 do
        for c = -4, cols + 4 do
            local score, details = M.evaluate_move(grid, SHAPES, kind, rot, c)
            -- 注意：evaluate_move 已在 DEBUG 模式下打印了有效和无效结果
            if score and score > best.score then
                best.score = score
                best.rot = rot
                best.col = c
                best.details = details
            end
        end
    end
    
    return best
end

return M
