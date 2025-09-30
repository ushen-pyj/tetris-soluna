local ltask = require "ltask"
local pd_algo = require "src.ai.pierre_dellacherie"
local shapes = require "src.core.constants".SHAPES

local S = {}

local last_decision_time = 0
local MIN_DECISION_INTERVAL = 0.5  -- 最小决策间隔（秒）

-- 调试模式
local DEBUG = true
local decision_count = 0

-- 构建动作序列
local function build_actions(current_rot, current_col, best_rot, best_col)
    local actions = {}
    
    -- 旋转
    if best_rot ~= current_rot then
        local rot_steps = (best_rot - current_rot) % 4
        for i = 1, rot_steps do
            table.insert(actions, {"rotate"})
        end
    end
    
    -- 移动
    local dc = best_col - current_col
    if dc ~= 0 then
        local step = dc > 0 and 1 or -1
        for i = 1, math.abs(dc) do
            table.insert(actions, {"move", step})
        end
    end
    
    -- 硬降落
    table.insert(actions, {"hard_drop"})
    
    return actions
end

function S.debug_best(best, grid, cur, shapes)
    if DEBUG and pd_algo.DEBUG_EVAL then
        local output = {}
        table.insert(output, string.format("\n=== Pierre Dellacherie 决策 #%d ===", decision_count))
        table.insert(output, string.format("方块类型: %s (type=%s)", tostring(cur.kind), type(cur.kind)))
        
        -- 打印当前棋盘列高度
        local cols = #grid[1]
        local rows = #grid
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
        table.insert(output, "当前列高度: " .. table.concat(heights, " "))
        
        -- 对比第1列和最佳选择
        if best and best.details then
            -- 尝试获取第1列的评分（如果不是最佳选择）
            if best.col ~= 1 then
                local col1_score, col1_details = pd_algo.evaluate_move(grid, shapes, cur.kind, best.rot, 1)
                if col1_score and col1_details then
                    table.insert(output, string.format("\n第1列被拒绝! 评分=%.3f (最佳=%.3f, 差距=%.3f)", 
                        col1_score, best.score, best.score - col1_score))
                    table.insert(output, "  第1列特征值和得分:")
                    local w = pd_algo.WEIGHTS
                    local d1 = col1_details
                    table.insert(output, string.format("    着陆高度: %.2f × %.2f = %.2f", 
                        d1.landing_height or 0, w.landing_height, (d1.landing_height or 0) * w.landing_height))
                    table.insert(output, string.format("    消除方块: %d × %.2f = %.2f", 
                        d1.eroded_cells or 0, w.eroded_cells, (d1.eroded_cells or 0) * w.eroded_cells))
                    table.insert(output, string.format("    行变换: %d × %.2f = %.2f", 
                        d1.row_transitions or 0, w.row_transitions, (d1.row_transitions or 0) * w.row_transitions))
                    table.insert(output, string.format("    列变换: %d × %.2f = %.2f", 
                        d1.col_transitions or 0, w.col_transitions, (d1.col_transitions or 0) * w.col_transitions))
                    table.insert(output, string.format("    空洞数: %d × %.2f = %.2f", 
                        d1.holes or 0, w.holes, (d1.holes or 0) * w.holes))
                    table.insert(output, string.format("    井深度: %.2f × %.2f = %.2f", 
                        d1.wells or 0, w.wells, (d1.wells or 0) * w.wells))
                    table.insert(output, string.format("    高度标准差: %.2f × %.2f = %.2f", 
                        d1.height_stddev or 0, w.height_stddev, (d1.height_stddev or 0) * w.height_stddev))
                end
            end
            
            local d = best.details
            table.insert(output, string.format("\n[最佳选择] 列=%d, 旋转=%d, 评分=%.3f", best.col, best.rot, best.score))
            table.insert(output, "  特征值和得分:")
            local w = pd_algo.WEIGHTS
            table.insert(output, string.format("    着陆高度: %.2f × %.2f = %.2f", 
                d.landing_height or 0, w.landing_height, (d.landing_height or 0) * w.landing_height))
            table.insert(output, string.format("    消除方块: %d × %.2f = %.2f", 
                d.eroded_cells or 0, w.eroded_cells, (d.eroded_cells or 0) * w.eroded_cells))
            table.insert(output, string.format("    行变换: %d × %.2f = %.2f", 
                d.row_transitions or 0, w.row_transitions, (d.row_transitions or 0) * w.row_transitions))
            table.insert(output, string.format("    列变换: %d × %.2f = %.2f", 
                d.col_transitions or 0, w.col_transitions, (d.col_transitions or 0) * w.col_transitions))
            table.insert(output, string.format("    空洞数: %d × %.2f = %.2f", 
                d.holes or 0, w.holes, (d.holes or 0) * w.holes))
            table.insert(output, string.format("    井深度: %.2f × %.2f = %.2f", 
                d.wells or 0, w.wells, (d.wells or 0) * w.wells))
            table.insert(output, string.format("    高度标准差: %.2f × %.2f = %.2f", 
                d.height_stddev or 0, w.height_stddev, (d.height_stddev or 0) * w.height_stddev))
        end
        table.insert(output, "======================================")
        ltask.log.info(table.concat(output, "\n"))
    end
end

function S.decide(snapshot)
    -- snapshot: { grid, cur, next_kind, ... }
    if not snapshot or not snapshot.grid or not snapshot.cur then
        return {}
    end
    
    -- 检查是否需要延迟
    local current_time = os.clock()
    local elapsed = current_time - last_decision_time
    
    if elapsed < MIN_DECISION_INTERVAL then
        return {}
    end
    
    -- 更新决策时间
    last_decision_time = current_time
    decision_count = decision_count + 1
    
    local grid = snapshot.grid
    local cur = snapshot.cur
    
    -- 使用Pierre Dellacherie算法搜索最佳落子
    local best = pd_algo.search_best_move(grid, shapes, cur.kind, cur.rot, cur.c)
 
    local ok, res = xpcall(S.debug_best, debug.traceback, best, grid, cur, shapes)
    if not ok then
        ltask.log.info("debug_best error: " .. tostring(res))
    end
    
    -- 构建动作序列
    local actions = build_actions(cur.rot, cur.c, best.rot, best.col)
    return actions
end

function S.quit()
    ltask.quit()
end

local function warp_handlers(t)
    for k, v in pairs(t) do
        if type(v) == "function" then
            t[k] = function(...)
                local ok, res = xpcall(v, debug.traceback, ...)
                if not ok then
                    ltask.log.error("error: " .. tostring(res))
                end
                return res
            end
        end
    end
    return t
end

return warp_handlers(S)