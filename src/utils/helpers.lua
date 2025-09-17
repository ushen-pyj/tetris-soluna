-- 辅助工具函数

local M = {}

-- 深度复制表
function M.deep_copy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for key, value in next, orig, nil do
            copy[M.deep_copy(key)] = M.deep_copy(value)
        end
        setmetatable(copy, M.deep_copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 限制数值在指定范围内
function M.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- 线性插值
function M.lerp(a, b, t)
    return a + (b - a) * t
end

-- 检查点是否在矩形内
function M.point_in_rect(x, y, rect_x, rect_y, rect_w, rect_h)
    return x >= rect_x and x < rect_x + rect_w and y >= rect_y and y < rect_y + rect_h
end

-- 格式化分数显示
function M.format_score(score)
    if score >= 1000000 then
        return string.format("%.1fM", score / 1000000)
    elseif score >= 1000 then
        return string.format("%.1fK", score / 1000)
    else
        return tostring(score)
    end
end

return M
