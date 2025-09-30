local renderer = require "src.ui.renderer"
local animation = require "src.utils.animation"
local quad = require "soluna.material.quad"
local constants = require "src.core.constants"
local colors = require "src.core.colors"
local globals = require "src.core.globals"

local M = {}

local current_time = 0

local main_thread_animation = nil
local dual_animations = {
    player1 = nil,
    player2 = nil
}

local function update_single_animation(anim, name)
    if anim and anim.active then
        
        if anim.start_time == 0 then
            anim.start_time = current_time
        end
        
        local elapsed = current_time - anim.start_time
        
        if elapsed >= anim.duration then
            anim.progress = 1.0
            anim.active = false
            if anim.on_complete then
                anim.on_complete()
            end
            return nil
        else
            anim.progress = anim.easing(elapsed / anim.duration)
            return anim
        end
    end
    return anim
end

function M.update_animations(delta_time)
    current_time = current_time + delta_time
    if main_thread_animation then
        main_thread_animation = update_single_animation(main_thread_animation, "单人")
    end
    if dual_animations.player1 then
        dual_animations.player1 = update_single_animation(dual_animations.player1, "玩家1")
    end
    if dual_animations.player2 then
        dual_animations.player2 = update_single_animation(dual_animations.player2, "玩家2")
    end
end

function M.get_current_time()
    return current_time
end

function M.start_main_thread_animation(anim_data)
    main_thread_animation = anim_data
end

function M.sync_animation_from_snapshot(snapshot)
    if globals.game_mode == constants.GAME_MODES.SINGLE or globals.game_mode == constants.GAME_MODES.AUTO then
        local snapshot_animation = snapshot.current_animation
        if snapshot_animation and snapshot_animation.active then
            if not main_thread_animation or main_thread_animation ~= snapshot_animation then
                main_thread_animation = snapshot_animation
            end
        elseif not snapshot_animation and main_thread_animation then
            main_thread_animation = nil
        end
    else
        local p1_animation = snapshot.player1.current_animation
        local p2_animation = snapshot.player2.current_animation
        if p1_animation and p1_animation.active then
            if not dual_animations.player1 or dual_animations.player1 ~= p1_animation then
                dual_animations.player1 = p1_animation
            end
        elseif not p1_animation and dual_animations.player1 then
            dual_animations.player1 = nil
        end
        if p2_animation and p2_animation.active then
            if not dual_animations.player2 or dual_animations.player2 ~= p2_animation then
                dual_animations.player2 = p2_animation
            end
        elseif not p2_animation and dual_animations.player2 then
            dual_animations.player2 = nil
        end
    end
end

function M.is_animating()
    return main_thread_animation ~= nil and main_thread_animation.active
end


function M.render_fixed_pieces_animated(batch, board_x, board_y, grid, player_id)
    local current_animation
    
    if globals.game_mode == constants.GAME_MODES.SINGLE or globals.game_mode == constants.GAME_MODES.AUTO then
        current_animation = main_thread_animation
    else
        current_animation = (player_id == 1) and dual_animations.player1 or dual_animations.player2
    end
    
    -- 先渲染正常网格
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
    
    -- 然后在上层独立渲染消除动画
    if current_animation and current_animation.active then
        for i, block in ipairs(current_animation.blocks or {}) do
            M.render_animated_block(batch, block.row, block.col, block.color, current_animation, block)
        end
    end
    
    batch:layer()
end

function M.render_animated_block(batch, row, col, color_kind, anim, block_data)
    local x = (col-1) * constants.CELL_SIZE
    local y = (row-1) * constants.CELL_SIZE
    local base_color = constants.COLORS[color_kind]
    local progress = anim.progress or 0
    
    if anim.type == "line_clear" then
        local glow_intensity = math.sin(progress * math.pi * 12) * 0.8 + 0.2
        local glow_color = M.blend_colors(base_color, colors.WHITE, glow_intensity)
        
        local slide_offset = (1 - progress) * constants.CELL_SIZE * 4
        local alpha = 1 - (progress * progress)
        
        local final_color = M.set_color_alpha(glow_color, alpha)
        
        batch:add(quad.quad(constants.CELL_SIZE-2, constants.CELL_SIZE-2, final_color), 
                 x+1-slide_offset, y+1)
                 
    elseif anim.type == "glow" then
        local glow_intensity = (math.sin(progress * math.pi * 4) + 1) * 0.5
        local glow_color = M.blend_colors(base_color, colors.WHITE, glow_intensity * 0.8)
        
        batch:add(quad.quad(constants.CELL_SIZE-4, constants.CELL_SIZE-4, glow_color), x+2, y+2)
        
    elseif anim.type == "slide_left" then
        local slide_distance = progress * constants.CELL_SIZE * 3
        local alpha = 1 - progress
        
        local final_color = M.set_color_alpha(base_color, alpha)
        batch:add(quad.quad(constants.CELL_SIZE-4, constants.CELL_SIZE-4, final_color), 
                 x+2-slide_distance, y+2)
    end
end

function M.blend_colors(color1, color2, ratio)
    ratio = math.max(0, math.min(1, ratio))
    
    local r1 = (color1 >> 16) & 0xFF
    local g1 = (color1 >> 8) & 0xFF
    local b1 = color1 & 0xFF
    local a1 = (color1 >> 24) & 0xFF
    
    local r2 = (color2 >> 16) & 0xFF
    local g2 = (color2 >> 8) & 0xFF
    local b2 = color2 & 0xFF
    local a2 = (color2 >> 24) & 0xFF
    
    local r = math.floor(r1 + (r2 - r1) * ratio)
    local g = math.floor(g1 + (g2 - g1) * ratio)
    local b = math.floor(b1 + (b2 - b1) * ratio)
    local a = math.floor(a1 + (a2 - a1) * ratio)
    
    return (a << 24) | (r << 16) | (g << 8) | b
end

function M.set_color_alpha(color, alpha)
    alpha = math.floor(math.max(0, math.min(255, alpha * 255)))
    return (color & 0x00FFFFFF) | (alpha << 24)
end




return M
