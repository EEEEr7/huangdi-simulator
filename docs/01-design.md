# 皇帝成长计划 · 设计契约（v1）

横屏 800×480 墨屏 XTApp。所有逻辑纯 Lua（`lib/`，禁止 ctx），所有绘制在 `screens/`。

## 1. 存档状态（ctx.state 的 key：`game`）

```lua
game = {
  year = 1, month = 1, age = 16, era = "承平",      -- 在位年/月/年龄/年号
  difficulty = 1,                                    -- 1 宽仁 2 中庸 3 严苛
  stats = { wang = 50, min = 50, jun = 50, wei = 50, cai = 50, de = 50 },
  res = { gold = 120, grain = 200, troops = 20, pop = 1000, corr = 50, tech = 30 },
  health = 90,                                       -- 0..100
  harem = { { name = "皇后", favor = 60, son = 0, wife = true } }, -- son = 已生皇子数
  heirs = { },                                       -- { name, age, intel, mother, crown = bool }
  court = { { name = "张居正", dept = "礼", loyalty = 70, skill = 60 } },
  edicts = { },                                      -- 本年已用诏令 id
  flags = { keju_year = 1 },                         -- 剧情/系统标记
  log = { },                                         -- 最近 12 条文本（本纪摘要）
  rng = 12345,                                       -- 线性同余种子，保证可重放
  ended = nil,                                       -- { id = "victory|collapse|...", text = "..." }
  phase = "court",                                   -- court|decree|summary|harem|court_list|war|over
  queue = { },                                       -- 本月待处理折子 {event_id, ...}
  pending = nil,                                     -- 当前折子/结局详情
  month_effects = { },                               -- 本月变化，summary 用
}
```

## 2. 数值口径

- 六维 stat、corr、tech、health：0..100（超出裁剪）。“左文右武”任一归零即亡国。
- 税银（万贯）＝ `round(pop * 0.012 * corr/100 * taxRate)`，taxRate 用整数千分比 900/1000/1150。
- 粮草消耗（万石）＝ `troops * 1.6`；收入 `grain_in = floor(pop * 0.05 * min/100)`，九月/十月秋收额外 `floor(pop * 0.15 * min/100)`。国库为负时民心动摇、军队哗变。
- 每月 `health -= 1 + age/20`；health < 60 时每月 +1（太医调养）；临幸 -2，巡狩 +3，大赦 +2。年龄 ≥ 55 后每年额外 -6 且健康上限降为 90。
- 事件效果用整数增量（`{ wang = 3, min = -5, gold = 20 }`），由 `G.apply(state, effects)` 统一裁剪。
- 概率用千分比整数，`RNG.chance(state, 300)` 表示 30%。

## 3. API（lib/game.lua，T1 实现）

```lua
G.new(opts) -> state          -- opts = { difficulty = 1, era = "承平" }
G.apply(state, effects)       -- 应用增量并裁剪，返回变化表
G.statline(state) -> table    -- { {"国势", 55}, {"民心", 40}, ... } 给 UI
G.draw_issues(state) -> {}    -- 抽本月 1~2 折子（写入 queue）
G.resolve_issue(state, event, choiceIndex)  -- 应用选项结果，返回 { text, effects, tags }
G.start_month(state)          -- 结算上月，进入 court 阶段
G.next_month(state)           -- month+1，跨年处理（age+1，年度结算，可能亡国）
G.decree_list(state) -> {}    -- { { id, name, hint, cost }, ... }
G.apply_decree(state, id) -> { ok, text }
G.harem_picks(state) -> {}    -- 选秀候选（3 人）
G.take_consort(state, i)
G.visit(state, i)             -- 临幸：favor/健康/子嗣判定
G.crown(state, heirIndex)
G.open_keju(state) -> {name, dept, skill, loyalty}
G.appoint(state, candidate)
G.dismiss(state, index)
G.war(state, target) -> { text, win }  -- 征伐
G.peace(state)                -- 和亲/岁币
G.check_end(state) -> ended|nil
G.save_view(state) -> view    -- 供 screens 消费的只读快照
```

## 4. 事件数据（lib/data/events.lua）

```lua
{ id = "flood_01", tag = "天灾", weight = 20, min_year = 1,
  title = "黄河决口", text = "……",
  choices = {
    { label = "发赈", hint = "银 -30 民 +6", effect = { gold = -30, min = 6 } },
    { label = "不报", hint = "民 -8 吏 -4", effect = { min = -8, corr = -4 } },
  } }
```

- 至少 40 条事件：天灾/人祸/边患/朝争/后宫/祥瑞/奇案/变法；按 tag 均衡，`weight` 控制稀有度。
- 至少 16 条诏令：开科、征兵、赈灾、修河、巡狩、大赦、赏军、查贪、封禅、兴学、屯田、铸钱、市易、禁奢、练兵、和籴。
- 文本全部中文竖排？不，横排。每屏折子正文 ≤ 2 行 24 字/行。

## 5. 界面（ui.lua 与 screens/*.lua，T2 实现）

```
┌ 顶栏 40px ────────────────────────────────────┐
│ 承平 3 年 · 五月    精力 ▓▓▓░ 健康 82   国势 55 │
├ 左 236px ──────┬ 右 564px ─────────────────────┤
│ 立绘 176×220   │ 标签页：朝会 / 诏令 / 后宫 / 臣僚 / 军国 │
│ 姓名·年号      │ 内容区（折子卡、名单、表单）        │
│ 六维横条       │                                  │
├ 底栏 32px ─────────────────────────────────────┤
│ ▲▼ 选择  ◀▶ 切换  OK 确认  BACK 返回            │
└────────────────────────────────────────────────┘
```

- 顶栏 40，左栏 236，右栏 564，底栏 32；内容安全边 8px。
- 字体：顶栏 medium，正文 medium，标题 large；行高 20/24/30。
- 选中项：2px 黑框 + 左侧 4×20 实心方块；禁用项 40% 灰阶（用 1px 点线框表示）。
- 列表每页 5 行（行高 28）；超过用 ▲▼ 翻滚。
- 弹窗：居中 520×260，2px 边框，标题栏 28px 反白。
- 所有图标 key 见 art/BRIEF.md，缺失时 UI 只用文字，不报错。

## 6. 工程分工

- T1：lib/**（game, rng, events 数据，data/*.lua, tests/lib_*.lua）；禁止引用 ctx。
- T2：ui.lua、screens/**、app/theme.lua（纯绘制，不写游戏规则）。
- Lead：index.lua（路由/输入/循环）、app/store.lua（存档）、app/assets.lua（图加载）、docs、预览 QA、打包。
- 文件 ≤ 400 行；中文文案集中在 lib/data/texts.lua（T1 维护）。
