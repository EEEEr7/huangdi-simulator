# 皇帝成长计划 · 横屏墨屏模拟器

XTEINK X4（X4-Classic / X4-Pro）横屏 800×480 皇帝养成模拟器，XTApp Lua API 2.26。
一月一回合，批红折子、下诏施政、后宫选秀、臣僚任免、军国征伐，六十岁后仍可续，维零或身死即结局。

## 玩法

- 朝会：每月 1–2 道折子，三道选项各有代价（银/粮/民心/国势/吏治…）
- 诏令：16 道常诏，每月限一道，立即生效
- 后宫：选秀添人、临幸（耗健康、加恩宠、判子嗣）、立储
- 臣僚：开科取士、任命/罢免/赏赐/查抄
- 军国：征伐（胜算按兵力/兵力/才略/科技算）、和亲、戍边
- 月末结算：税银、粮草、秋收（九十月加倍）、六维变化
- 结局：9 种（国势/民心/军心/威望/才略/德行任一归零，或健康归零，或寿终）

## 操作

- X4-Classic：上下选择、左右切页签、OK 确认、BACK 返回
- X4-Pro：触屏点按全部按钮/选项/页签；BACK 返回

## 目录

- `project-files/`：可导入 Studio 的工程（manifest.json、index.lua、ui.lua、app/、screens/、lib/、assets/）
- `art/`：素材提示词与生图产物（`raw/` 原图不入库，`out/` 为抖动预览）
- `tests/`：数据与月循环自检（`lua tests/run.lua`）
- `docs/`：设计、UI 契约

## 构建

```bash
# 测试
lua tests/run.lua

# Studio 导入包
python ../tools/pack_studio_projects.py --out ./dist --only huangdi-simulator

# 设备包
node "D:/workspace/_cmp_xtapp_20261027/pack.mjs" project-files dist/<name>.xtapp
```

## 素材

豆包 Seedream 生成，按工作区 `../docs/ink-screen-doubao-xic-rules.md` 墨屏规范转换为 XIC：
亮度加权 → Floyd–Steinberg 抖动（强度 0.65、阈值 128）→ 2 阶或 4 阶。
