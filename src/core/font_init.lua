-- 字体初始化模块
local M = {}

-- 尝试加载系统字体的函数
local function try_load_system_fonts()
    local font_system = require "soluna.font.system"
    local font = require "soluna.font"
    
    -- 尝试加载常见的系统字体
    local font_names = {"Arial", "SimSun", "Microsoft YaHei", "DejaVu Sans", "Liberation Sans", "Tahoma", "Verdana", ""}
    
    for _, font_name in ipairs(font_names) do
        local ok, font_data = pcall(font_system.ttfdata, font_name)
        if ok and font_data and #font_data > 0 then
            print("尝试导入字体:", font_name == "" and "默认字体" or font_name, "数据大小:", #font_data)
            local import_ok = pcall(font.import, font_data)
            if import_ok then
                print("成功加载字体:", font_name == "" and "默认字体" or font_name)
                
                -- 尝试获取字体ID来验证加载
                local name_ok, font_id = pcall(font.name, font_name)
                if name_ok and font_id then
                    print("字体ID:", font_id)
                else
                    print("无法获取字体ID")
                end
                
                return true
            else
                print("字体导入失败:", font_name)
            end
        else
            print("无法获取字体数据:", font_name)
        end
    end
    
    print("警告: 无法加载任何系统字体")
    return false
end

-- 初始化字体系统
function M.init()
    local ok, err = pcall(try_load_system_fonts)
    if not ok then
        print("字体初始化失败:", err)
        return false
    end
    return true
end

return M
