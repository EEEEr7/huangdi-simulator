# 美术清单与验收（v1）

全部黑白纯墨：**2 阶黑白**用于游戏内素材（线与网点），**4 阶灰**只用于标题与结局两张静态图（g:image gray=true 会闪一次全刷，不能用于频繁重绘的界面）。

## 生成流程（逐张）

1. 读 `D:\workspace\XTApp AI\docs\ink-screen-doubao-xic-rules.md`，从 24 条模板里选一条，替换 `{主体}`，末尾追加通用反向词；提示词里写「无文字」。
2. 写请求 JSON（`model: doubao-seedream-5-0-pro-260628`、`size: "1.5K"`、`watermark: false`），跑：
   `python C:\Users\Administrator\.cursor\skills\doubao-seedream-image\scripts\generate.py art\raw\<key> art\raw\<key>.json`
3. 原图存 `art/raw/<key>.png`（脚本会下到 art/raw/ 前缀目录）。
4. 转 XIC：
   `python tools\make_xic.py art\raw\<key>.png --size <WxH> --mode bw|gray4 --fit cover|contain --trim --out project-files\assets\<key>.xic --preview art\out\<key>.png`
5. 在最终像素尺寸看预览（`art/out/<key>.png`），不合格就重生成；不要只看彩色原图。

## 清单

### 立绘（160×200，bw，contain，trim）

| key | 主体 | 建议模板 |
| --- | --- | --- |
| p_emp | 少年皇帝，衮冕龙袍，正面半身 | 蚀刻/高反差人像 |
| p_emp_old | 晚年皇帝，须发花白，疲惫 | 蚀刻 |
| p_empress | 皇后，凤冠，端庄 | 蚀刻 |
| p_consort1 | 贵妃，华服，冷艳 | 蚀刻 |
| p_consort2 | 妃嫔，温婉，素簪 | 蚀刻 |
| p_consort3 | 宫女/秀女，青衫 | 蚀刻 |
| p_heir | 皇子，束发，少年 | 蚀刻 |
| p_princess | 公主，及笄 | 蚀刻 |
| p_min_wen | 文臣，乌纱补服，持笏 | 蚀刻 |
| p_min_wu | 武将，甲胄，按剑 | 蚀刻 |
| p_eunuch | 太监，圆领，低眉 | 蚀刻 |
| p_enemy | 敌酋，皮甲，狞目 | 高反差人像 |
| p_rebel | 乱民首领，破衣，举锄 | 剪影/木刻 |
| p_envoy | 外邦使节，异域冠帽 | 蚀刻 |

### 场景（384×144，bw，cover，trim）

| key | 内容 |
| --- | --- |
| s_court | 早朝金銮殿，群臣列班 |
| s_war | 边关雪战，旗甲 |
| s_flood | 黄水决堤，救民 |
| s_famine | 赤地千里，饥民 |
| s_keju | 贡院放榜，士子 |
| s_banquet | 宫宴灯火，鼓乐 |
| s_plague | 疫气罩城，医者 |
| s_prosper | 市井丰年，漕运 |
| s_collapse | 兵临城下，火光 |
| s_treasury | 户部银库，算盘 |
| s_harem | 后宫回廊，屏风 |
| s_hunt | 秋狝猎场，骏马 |

### 图标（24×24，bw，contain，trim）

`i_wang` 国势（山岳/城阙）、`i_min` 民心（谷穗）、`i_jun` 军心（戈）、`i_wei` 威望（鼎）、`i_cai` 才略（卷轴）、`i_de` 德行（竹）、`i_gold` 银两（元宝）、`i_grain` 粮草（仓）、`i_army` 兵力（甲兵小人）。要求：24px 下仍能辨认，轮廓闭合，线宽 2px，无字。

### 静态大图

| key | 尺寸 | 模式 | 内容 |
| --- | --- | --- | --- |
| t_throne | 384×240 | gray4 | 龙椅上的皇帝，正面，黑金气派 |
| e_end | 384×240 | gray4 | 空白诏书/日落城郭，用于结局背景 |
| app_icon_s | 88×88 | bw | 方印龙纹（已有占位，需替换为正式） |

## 验收清单（每张都查）

- [ ] 纯白背景（预览图四角为 255），无灰底、无渐变
- [ ] 主体居中、占画幅 65%~80%，四周留白
- [ ] 轮廓闭合、缩到最终像素后仍 ≥2px 粗
- [ ] 最终尺寸可读（在 art/out 里以 100% 看，不放大）
- [ ] 无文字、无角标、无签名（角标已用 --trim 裁掉）
- [ ] XIC 可被 png2xic --inspect 读出正确尺寸/灰阶

产出汇总：`art/out/contact-sheet.png`（所有素材 2 倍像素拼图，标注 key）+ `art/out/report.md`（每张：模板、提示词摘要、尺寸、模式、验收结果）。
