-- 动画系统模块（精简版）
-- 只保留必要的动画类型和缓动函数

local M = {}

-- 动画类型枚举
M.ANIM_TYPES = {
    FADE_OUT = "fade_out",
    SLIDE_LEFT = "slide_left", 
    SCALE_UP = "scale_up",
    GLOW = "glow",
    LINE_CLEAR = "line_clear"
}

-- 缓动函数
M.EASING = {
    LINEAR = function(t) return t end,
    EASE_OUT = function(t) return 1 - (1 - t) * (1 - t) end,
    EASE_IN = function(t) return t * t end,
    EASE_IN_OUT = function(t) return t < 0.5 and 2 * t * t or 1 - 2 * (1 - t) * (1 - t) end,
    BOUNCE_OUT = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            return n1 * (t - 1.5 / d1) * (t - 1.5 / d1) + 0.75
        elseif t < 2.5 / d1 then
            return n1 * (t - 2.25 / d1) * (t - 2.25 / d1) + 0.9375
        else
            return n1 * (t - 2.625 / d1) * (t - 2.625 / d1) + 0.984375
        end
    end
}

return M