-- 游戏颜色常量定义
-- 所有颜色值都使用十六进制格式

local M = {}

-- 基础颜色
M.WHITE = 0xFFFFFF        -- 白色
M.BLACK = 0x000000        -- 黑色
M.RED = 0xFF0000          -- 红色
M.GREEN = 0x00FF00        -- 绿色
M.BLUE = 0x0000FF         -- 蓝色
M.YELLOW = 0xFFFF00       -- 黄色
M.CYAN = 0x00FFFF         -- 青色
M.MAGENTA = 0xFF00FF      -- 洋红色

-- 游戏界面颜色
M.GAME_OVER_TEXT = 0xFF0000      -- 游戏结束文字（红色）
M.RESTART_TEXT = 0xFFFFFF        -- 重新开始文字（白色）
M.TITLE_TEXT = 0xFF00FF          -- 标题文字（洋红色）
M.BUTTON_BACKGROUND = 0x444444   -- 按钮背景（深灰色）
M.BUTTON_TEXT = 0xFFFFFF         -- 按钮文字（白色）
M.BUTTON_BORDER = 0xFFFFFF       -- 按钮边框（白色）
M.CONTROL_HINT = 0xFFFF00        -- 控制说明标题（黄色）
M.CONTROL_TEXT = 0xFFFFFF        -- 控制说明文字（白色）
M.CLICK_HINT = 0x00FFFF          -- 点击提示（青色）

-- 玩家界面颜色
M.PLAYER1_UI = 0x00FFFF          -- 玩家1界面元素（青色）
M.PLAYER2_UI = 0xFF00FF          -- 玩家2界面元素（洋红色）
M.PLAYER1_LABEL = 0x00FFFF       -- 玩家1标签（青色）
M.PLAYER2_LABEL = 0xFF00FF       -- 玩家2标签（洋红色）

-- 分数显示颜色
M.SCORE_TITLE = 0xFFFFFF         -- 分数标题（白色）
M.SCORE_VALUE = 0xFFFF00         -- 分数数值（黄色）
M.LEVEL_TITLE = 0xFFFFFF         -- 等级标题（白色）
M.LEVEL_VALUE = 0x00FF00         -- 等级数值（绿色）
M.LINES_TITLE = 0xFFFFFF         -- 行数标题（白色）
M.LINES_VALUE = 0x00FFFF         -- 行数数值（青色）

-- 共享信息颜色
M.SHARED_INFO = 0xFFFF00         -- 共享信息（黄色）

-- 控制说明颜色
M.CONTROL_HELP = 0x888888        -- 控制帮助文字（灰色）

-- 方块颜色（保持现有定义）
M.PIECE_I = 0x17bebb             -- I型方块（青色）
M.PIECE_O = 0xfad000             -- O型方块（黄色）
M.PIECE_T = 0x9b5de5             -- T型方块（紫色）
M.PIECE_S = 0x00c2a8             -- S型方块（青绿色）
M.PIECE_Z = 0xff595e             -- Z型方块（红色）
M.PIECE_J = 0x277da1             -- J型方块（蓝色）
M.PIECE_L = 0xf9844a             -- L型方块（橙色）
M.PIECE_GRID = 0x1f1f1f          -- 网格（灰色）

-- UI配置颜色
M.SCORE_BAR_BG = 0x444444        -- 分数条背景（深灰色）
M.SCORE_BAR_FILL = 0xf0c808      -- 分数条填充（金黄色）
M.PREVIEW_BACKGROUND = 0x2a2a2a  -- 预览区域背景（深灰色）

-- 默认颜色（带alpha通道）
M.DEFAULT_TEXT = 0xFFFFFFFF      -- 默认文字颜色（白色，带alpha）

-- Alpha通道相关常量
M.ALPHA_MASK = 0xFF000000        -- Alpha通道掩码（用于确保颜色有alpha通道）
M.NO_ALPHA_MASK = 0x00FFFFFF     -- 无alpha通道掩码（用于检查是否缺少alpha通道）

-- 动画特效颜色
M.CLEAR_ANIMATION = 0xFFFFFF     -- 消除动画颜色（白色）
M.GLOW_WHITE = 0xFFFFFF          -- 发光白色
M.FADE_BLACK = 0x000000          -- 淡化黑色

return M
