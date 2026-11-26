# UI 契约（v1）

## 模块边界

- `ui.lua`（T2）：绘制原语 + 顶栏/底栏/面板/弹窗/列表/横条/按钮；**不写规则**。
- `screens/<name>.lua`（T2）：每个界面一个模块，导出 `{ draw(ctx, g, V) }`。
- `index.lua`（Lead）：路由、输入、月循环；把游戏快照喂给 screens。
- `app/assets.lua`（Lead）：图片加载与绘制。

## 屏幕契约

```lua
local S = {}
function S.draw(ctx, g, V)
  local hits = {}
  -- 用 U、A 绘制；每画一个可点/可选区域就 push 一条 hit
  hits[#hits+1] = { x = 8, y = 48, w = 220, h = 28, cmd = "tab", arg = "court" }
  return hits
end
return S
```

- `V`（view，只读快照）：
```lua
V = { screen = "court", tab = "court", cursor = 1, index = 1, sub = "list",
      gs = <game state 快照>, text = { ... }, toast = { text = "", kind = "ok" },
      help = "▲▼ 选择  ◀▶ 页签  OK 确认  BACK 返回", debug = false,
      A = <app/assets.lua 注入>, U = <ui.lua 注入> }
```
- 屏幕通过这些依赖注入拿资源与界面：`V.A.portrait(ctx,g,key,x,y,w,h)`、`V.U.hline(g,...)`。**screens 不 require 任何模块**（除 ui.lua 本身可 require），保证离线可测。
- `hit.cmd` 只能是：`tab`(arg=页签名) / `select`(arg=序号) / `ok` / `back` / `action`(arg=动作名+参数)。
- 键盘：router 负责把 up/down/left/right/ok/back 转成 `action`，screens 不处理按键。
- 触摸：router 在点击坐标命中第一个 hit 的矩形时，派发对应 cmd。
- 屏幕必须画满 800×480：背景 `g:clear(0)` 或白底；缺失资源时降级为文字。

## 坐标系统（横屏 800×480）

- 顶栏 y 0..40；左栏 x 8..236；右栏 x 244..792；底栏 y 448..480。
- 内容区行起点 y=48，行高 28；正文行高 24；标题 large。
- 弹窗居中：x=140..660，y=110..370；标题栏高 28。
- 选中：外框 2px + 左标记（4×20 实心）+ 反白标题。
- 六维条：标签 4 字 + 条 96×8 + 数值 3 位。

## app/assets.lua API（Lead 实现，T2 直接调用）

```lua
A.has(ctx, key) -> bool
A.portrait(ctx, g, key, x, y, w, h)  -- 等比 contain，白底居中，缺失则画空框
A.scene(ctx, g, key, x, y, w, h)     -- 等比 cover 居中裁切
A.icon(ctx, g, key, x, y, s)         -- 方图
A.gray_scene(ctx, g, key, x, y, w, h) -- 4 阶静态图（会触发一次灰阶刷新，只用于标题/结局）
```

- 资源 key 见 `art/BRIEF.md`，全部小写、≤23 字节。
- `A.portrait` 的 key 约定：`p_emp`、`p_emp_old`、`p_empress`、`p_consort1..3`、`p_heir`、`p_princess`、`p_min_wen`、`p_min_wu`、`p_eunuch`、`p_enemy`、`p_rebel`、`p_envoy`。
- 场景：`s_court`、`s_war`、`s_flood`、`s_famine`、`s_keju`、`s_banquet`、`s_plague`、`s_prosper`、`s_collapse`、`s_treasury`、`s_harem`、`s_hunt`。
- 图标：`i_wang`、`i_min`、`i_jun`、`i_wei`、`i_cai`、`i_de`、`i_gold`、`i_grain`、`i_army`。
- 标题：`t_throne`（4 阶，384×240）。

## 屏幕清单与职责

| screen | 内容 |
| --- | --- |
| title | 标题、开始/继续/设置、年号与难度选择 |
| court | 本月折子（1~2 张卡）、选项、结果弹窗 |
| decree | 诏令 16 条列表（带花费与效果提示），每月 1 条 |
| harem | 后妃列表、选秀、临幸、子嗣、立储 |
| court_list | 臣僚名录、科举取士、任命/罢免/赏赐/查办 |
| war | 军国：征伐目标、胜算、和亲岁币、边防 |
| summary | 月末结算（变化表）、进入下月 |
| ending | 结局（4 阶大图 + 本纪 + 重开） |
| help | 操作说明、难度、年号、关于 |

## 视觉规范

- 只用黑（0）白（255）与网点；不引入中间灰绘制，线条 2px。
- 中文字体：顶栏/正文 medium，标题 large；英文数字 medium。
- 每屏最多 1 个焦点区；选中态清晰（反白或粗框）。
- 动效克制：翻页不淡入，直接重绘；结果弹窗一次性出现。
