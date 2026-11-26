-- lib/data/events.lua
-- 事件库：八类 tag 各五条，共四十条。
-- 字段依 docs/01-design.md §4；effect 仅用整数增量。
-- tag：天灾 / 人祸 / 边患 / 朝争 / 后宫 / 祥瑞 / 奇案 / 变法

return {
  -- ── 天灾 ──
  { id = "flood_01", tag = "天灾", weight = 22, min_year = 1,
    title = "黄河决口", scene = "s_flood",
    text = "河决白马津，漂没郡县十余。流民塞道，漕运中绝，有司请发常平仓。",
    choices = {
      { label = "发赈", hint = "银-30 民+6", effect = { gold = -30, min = 6 } },
      { label = "堵口", hint = "银-45 国+4 民-2", effect = { gold = -45, wang = 4, min = -2 } },
      { label = "不报", hint = "民-8 吏-4", effect = { min = -8, corr = -4 } },
    } },

  { id = "flood_02", tag = "天灾", weight = 16, min_year = 2,
    title = "淮水泛溢", scene = "s_flood",
    text = "淮水溢，泗州城没于水。岁修堤银多为官吏所蚀，至是始败。",
    choices = {
      { label = "修堤", hint = "银-35 吏+2 民+3", effect = { gold = -35, corr = 2, min = 3 } },
      { label = "赈恤", hint = "粮-25 民+4", effect = { grain = -25, min = 4 } },
      { label = "严查", hint = "吏+5 民-2 威+2", effect = { corr = 5, min = -2, wei = 2 } },
    } },

  { id = "drought_01", tag = "天灾", weight = 20, min_year = 1,
    title = "赤地千里", scene = "s_famine",
    text = "自春不雨，至秋无禾。赤地千里，斗米千钱，饥民载道。",
    choices = {
      { label = "开仓", hint = "粮-40 民+6", effect = { grain = -40, min = 6 } },
      { label = "缓征", hint = "银-20 民+3 吏-1", effect = { gold = -20, min = 3, corr = -1 } },
      { label = "祷雨", hint = "银-8 威+3 民-3", effect = { gold = -8, wei = 3, min = -3 } },
    } },

  { id = "locust_01", tag = "天灾", weight = 14, min_year = 2,
    title = "蝗蔽天日", scene = "s_famine",
    text = "飞蝗自东南来，蔽天日，所过禾稼一空。百姓击鼓逐之，不能止。",
    choices = {
      { label = "捕蝗", hint = "银-15 粮-10 民+4", effect = { gold = -15, grain = -10, min = 4 } },
      { label = "免赋", hint = "银-25 民+5", effect = { gold = -25, min = 5 } },
      { label = "讳灾", hint = "民-7 吏-3", effect = { min = -7, corr = -3 } },
    } },

  { id = "quake_01", tag = "天灾", weight = 10, min_year = 3,
    title = "京师地动", scene = "s_collapse",
    text = "京师地震，宫殿摇动，太庙鸱吻堕。民舍倾者数百，讹言四起。",
    choices = {
      { label = "罪己", hint = "德+4 威-2 民+3", effect = { de = 4, wei = -2, min = 3 } },
      { label = "修省", hint = "银-20 吏+3 民+2", effect = { gold = -20, corr = 3, min = 2 } },
      { label = "禁讹", hint = "民-4 吏-2 威+2", effect = { min = -4, corr = -2, wei = 2 } },
    } },

  -- ── 人祸 ──
  { id = "corrupt_01", tag = "人祸", weight = 18, min_year = 1,
    title = "漕运亏空", scene = "s_treasury",
    text = "漕粮至京，亏耗三成。仓吏称沿途漂没，舟子言船上了无湿痕。",
    choices = {
      { label = "密查", hint = "吏+5 银-10 民-1", effect = { corr = 5, gold = -10, min = -1 } },
      { label = "追赔", hint = "银+25 吏+2 民-3", effect = { gold = 25, corr = 2, min = -3 } },
      { label = "不问", hint = "吏-5 民-2", effect = { corr = -5, min = -2 } },
    } },

  { id = "corrupt_02", tag = "人祸", weight = 14, min_year = 2,
    title = "盐引之弊", scene = "s_treasury",
    text = "盐商贿结运司，旧引未销，新引复出。官盐壅滞，私盐充斥，课银岁减。",
    choices = {
      { label = "清引", hint = "吏+4 银+15 民-2", effect = { corr = 4, gold = 15, min = -2 } },
      { label = "弛禁", hint = "银-5 民+3 吏-3", effect = { gold = -5, min = 3, corr = -3 } },
      { label = "查办", hint = "吏+6 威+2 银-10", effect = { corr = 6, wei = 2, gold = -10 } },
    } },

  { id = "injustice_01", tag = "人祸", weight = 15, min_year = 1,
    title = "冤狱待决", scene = "s_court",
    text = "县民某坐杀人系狱，已具狱待决。其母击登闻鼓，称子冤，词甚哀。",
    choices = {
      { label = "重审", hint = "吏+4 民+3 银-6", effect = { corr = 4, min = 3, gold = -6 } },
      { label = "维持", hint = "威+2 民-4 德-2", effect = { wei = 2, min = -4, de = -2 } },
      { label = "特赦", hint = "德+3 民+2 吏-2", effect = { de = 3, min = 2, corr = -2 } },
    } },

  { id = "injustice_02", tag = "人祸", weight = 12, min_year = 3,
    title = "株连数百", scene = "s_court",
    text = "有司治逆案，牵连数百家。狱吏锻炼成狱，士民侧目，道路以目。",
    choices = {
      { label = "平反", hint = "德+5 威-2 民+4", effect = { de = 5, wei = -2, min = 4 } },
      { label = "穷治", hint = "威+4 民-6 德-3", effect = { wei = 4, min = -6, de = -3 } },
      { label = "限狱", hint = "吏+3 民+1 银-8", effect = { corr = 3, min = 1, gold = -8 } },
    } },

  { id = "revolt_01", tag = "人祸", weight = 10, min_year = 2,
    title = "流民啸聚", scene = "s_collapse",
    text = "饥民数千啸聚山谷，掠富室，县兵不能制。或言其首乃前罢官吏。",
    choices = {
      { label = "招抚", hint = "银-25 粮-15 民+5", effect = { gold = -25, grain = -15, min = 5 } },
      { label = "进剿", hint = "兵-4 银-15 民-2", effect = { troops = -4, gold = -15, min = -2 } },
      { label = "赈济", hint = "粮-35 民+6 吏-1", effect = { grain = -35, min = 6, corr = -1 } },
    } },

  -- ── 边患 ──
  { id = "raid_01", tag = "边患", weight = 20, min_year = 1,
    title = "胡骑犯边", scene = "s_war",
    text = "北狄三万骑入寇，破边堡二，掠人畜万计。烽火昼夜不绝，京师戒严。",
    choices = {
      { label = "亲征", hint = "兵-6 威+5 银-30", effect = { troops = -6, wei = 5, gold = -30 } },
      { label = "遣将", hint = "银-35 兵-3 军+3", effect = { gold = -35, troops = -3, jun = 3 } },
      { label = "固守", hint = "威-3 民-2 银-10", effect = { wei = -3, min = -2, gold = -10 } },
    } },

  { id = "raid_02", tag = "边患", weight = 14, min_year = 3,
    title = "倭寇掠海", scene = "s_war",
    text = "倭船十余泊于海口，焚掠渔村，商旅断绝。卫所兵老弱，望风而溃。",
    choices = {
      { label = "练兵", hint = "银-25 兵+3 军+3", effect = { gold = -25, troops = 3, jun = 3 } },
      { label = "海禁", hint = "银-10 民-3 吏+1", effect = { gold = -10, min = -3, corr = 1 } },
      { label = "抚谕", hint = "德+2 民+1 威-2", effect = { de = 2, min = 1, wei = -2 } },
    } },

  { id = "raid_03", tag = "边患", weight = 12, min_year = 2,
    title = "羌人叩关", scene = "s_war",
    text = "西羌以互市失平，引众叩关，边将请战。朝议汹汹，或主战，或主市。",
    choices = {
      { label = "出战", hint = "兵-4 威+4 银-20", effect = { troops = -4, wei = 4, gold = -20 } },
      { label = "开市", hint = "银+10 民-1 威-2", effect = { gold = 10, min = -1, wei = -2 } },
      { label = "闭关", hint = "威+2 银-8 民-2", effect = { wei = 2, gold = -8, min = -2 } },
    } },

  { id = "marriage_01", tag = "边患", weight = 10, min_year = 2,
    title = "和亲之议", scene = "s_harem",
    text = "北狄请和亲，欲得宗女。朝臣或言汉唐故事，或言以女易安，非国体。",
    choices = {
      { label = "许婚", hint = "威-4 民+3 银-10", effect = { wei = -4, min = 3, gold = -10 } },
      { label = "却之", hint = "威+3 兵-2 银-15", effect = { wei = 3, troops = -2, gold = -15 } },
      { label = "增币", hint = "银-30 民-2 威-2", effect = { gold = -30, min = -2, wei = -2 } },
    } },

  { id = "tribute_01", tag = "边患", weight = 10, min_year = 3,
    title = "岁币之请", scene = "s_treasury",
    text = "北朝遣使索岁币，称若不与，秋高马肥，当会猎于塞下。",
    choices = {
      { label = "输币", hint = "银-40 威-3 军-2", effect = { gold = -40, wei = -3, jun = -2 } },
      { label = "拒之", hint = "威+4 兵-3 银-20", effect = { wei = 4, troops = -3, gold = -20 } },
      { label = "缓议", hint = "银-10 威-1 吏+1", effect = { gold = -10, wei = -1, corr = 1 } },
    } },

  -- ── 朝争 ──
  { id = "faction_01", tag = "朝争", weight = 16, min_year = 1,
    title = "两党相攻", scene = "s_court",
    text = "朝中两党相攻，互讦贪墨。章疏盈几，各引朋辈，政事为之壅滞。",
    choices = {
      { label = "两罢", hint = "吏+2 威+2 才-1", effect = { corr = 2, wei = 2, cai = -1 } },
      { label = "用一党", hint = "才+3 吏-3 威-2", effect = { cai = 3, corr = -3, wei = -2 } },
      { label = "留中", hint = "威-2 民-2 才-1", effect = { wei = -2, min = -2, cai = -1 } },
    } },

  { id = "faction_02", tag = "朝争", weight = 13, min_year = 2,
    title = "台谏交章", scene = "s_court",
    text = "台谏交章论宰相过失，宰相称病乞归。两宫各遣人问，人情汹汹。",
    choices = {
      { label = "罢相", hint = "威+3 才-2 吏+1", effect = { wei = 3, cai = -2, corr = 1 } },
      { label = "留相", hint = "才+2 吏-2 民-1", effect = { cai = 2, corr = -2, min = -1 } },
      { label = "调停", hint = "德+2 才+1 威-1", effect = { de = 2, cai = 1, wei = -1 } },
    } },

  { id = "remonstrance_01", tag = "朝争", weight = 14, min_year = 1,
    title = "直臣犯颜", scene = "s_court",
    text = "谏官当廷驳诏，谓陛下此举与民争利。举朝屏息，候上意。",
    choices = {
      { label = "纳谏", hint = "德+4 民+3 威-1", effect = { de = 4, min = 3, wei = -1 } },
      { label = "贬谪", hint = "威+2 德-3 吏-2", effect = { wei = 2, de = -3, corr = -2 } },
      { label = "罚俸", hint = "吏-1 德-2 威+1", effect = { corr = -1, de = -2, wei = 1 } },
    } },

  { id = "remonstrance_02", tag = "朝争", weight = 12, min_year = 2,
    title = "谏止巡幸", scene = "s_hunt",
    text = "上将幸西苑校猎，谏臣言边警未息，府库空虚，不宜游豫。",
    choices = {
      { label = "罢行", hint = "德+3 民+2 威-2", effect = { de = 3, min = 2, wei = -2 } },
      { label = "减从", hint = "威+2 银-15 德-1", effect = { wei = 2, gold = -15, de = -1 } },
      { label = "如期", hint = "威+3 民-3 银-25", effect = { wei = 3, min = -3, gold = -25 } },
    } },

  { id = "strongman_01", tag = "朝争", weight = 11, min_year = 3,
    title = "权臣擅政", scene = "s_court",
    text = "首辅久任，门生故吏遍天下。奏疏先谒其第，后达御前。",
    choices = {
      { label = "收权", hint = "威+4 才-2 吏-1", effect = { wei = 4, cai = -2, corr = -1 } },
      { label = "倚任", hint = "才+3 威-3 吏+1", effect = { cai = 3, wei = -3, corr = 1 } },
      { label = "察党", hint = "吏+4 威+1 民-1", effect = { corr = 4, wei = 1, min = -1 } },
    } },
  -- ── 后宫 ──
  { id = "empress_01", tag = "后宫", weight = 14, min_year = 1,
    title = "中宫虚位", scene = "s_harem",
    text = "中宫久虚，礼官请立后。贵妃有宠，家世亦盛；淑妃端谨，为太后所喜。",
    choices = {
      { label = "立贵女", hint = "威+3 民-2 银-15", effect = { wei = 3, min = -2, gold = -15 } },
      { label = "立淑妃", hint = "德+3 民+2 威-1", effect = { de = 3, min = 2, wei = -1 } },
      { label = "缓立", hint = "威-2 吏-1 才+1", effect = { wei = -2, corr = -1, cai = 1 } },
    } },

  { id = "empress_02", tag = "后宫", weight = 9, min_year = 2,
    title = "废后之议", scene = "s_harem",
    text = "皇后失欢于上，有司窥旨，风闻废立。中宫闭门自省，外廷窃议。",
    choices = {
      { label = "废后", hint = "威+2 德-4 民-2", effect = { wei = 2, de = -4, min = -2 } },
      { label = "保全", hint = "德+4 民+2 威-2", effect = { de = 4, min = 2, wei = -2 } },
      { label = "自省", hint = "德+2 才-1 威-1", effect = { de = 2, cai = -1, wei = -1 } },
    } },

  { id = "favor_01", tag = "后宫", weight = 13, min_year = 1,
    title = "宠妃求封", scene = "s_harem",
    text = "宠妃求封其父为侯，上未有以应。外戚请托之书，已盈于案。",
    choices = {
      { label = "许封", hint = "威+2 吏-3 银-10", effect = { wei = 2, corr = -3, gold = -10 } },
      { label = "不许", hint = "德+2 吏+1 威-1", effect = { de = 2, corr = 1, wei = -1 } },
      { label = "赐金", hint = "银-20 威+1 民-1", effect = { gold = -20, wei = 1, min = -1 } },
    } },

  { id = "favor_02", tag = "后宫", weight = 12, min_year = 2,
    title = "椒房争宠", scene = "s_harem",
    text = "两妃争宠，各结内侍，传播流言。宫闱不宁，外议籍籍。",
    choices = {
      { label = "并斥", hint = "德+2 民+1 威-2", effect = { de = 2, min = 1, wei = -2 } },
      { label = "偏宠", hint = "才-1 威+2 民-2", effect = { cai = -1, wei = 2, min = -2 } },
      { label = "整宫", hint = "吏+2 威+1 健-3", effect = { corr = 2, wei = 1, health = -3 } },
    } },

  { id = "heir_01", tag = "后宫", weight = 11, min_year = 3,
    title = "皇嗣未广", scene = "s_harem",
    text = "上春秋渐高，皇嗣未广。礼官请广纳嫔御，以延国本。",
    choices = {
      { label = "选秀", hint = "银-20 威+1 健-3", effect = { gold = -20, wei = 1, health = -3 } },
      { label = "养宗子", hint = "德-1 威-2 民+1", effect = { de = -1, wei = -2, min = 1 } },
      { label = "缓议", hint = "威-2 吏+1 健+1", effect = { wei = -2, corr = 1, health = 1 } },
    } },

  -- ── 祥瑞 ──
  { id = "omen_01", tag = "祥瑞", weight = 16, min_year = 1,
    title = "甘露降庭", scene = "s_prosper",
    text = "甘露降于宫柏，凝如珠。礼官称瑞，请告宗庙、布告天下。",
    choices = {
      { label = "告庙", hint = "威+3 银-10 民+1", effect = { wei = 3, gold = -10, min = 1 } },
      { label = "不贺", hint = "德+2 才+1 威-1", effect = { de = 2, cai = 1, wei = -1 } },
      { label = "受贺", hint = "威+2 吏-2 民-1", effect = { wei = 2, corr = -2, min = -1 } },
    } },

  { id = "omen_02", tag = "祥瑞", weight = 12, min_year = 2,
    title = "白鹿出林", scene = "s_hunt",
    text = "猎于南山，获白鹿。或言王者仁德则白鹿见，请宣付史馆。",
    choices = {
      { label = "宣付", hint = "威+3 银-5 民+1", effect = { wei = 3, gold = -5, min = 1 } },
      { label = "放归", hint = "德+2 才+1 威-1", effect = { de = 2, cai = 1, wei = -1 } },
      { label = "赏猎户", hint = "银-8 民+2 威-1", effect = { gold = -8, min = 2, wei = -1 } },
    } },

  { id = "omen_03", tag = "祥瑞", weight = 8, min_year = 3,
    title = "黄河水清", scene = "s_prosper",
    text = "黄河水清三日，两岸父老以为圣朝之应。有司请建碑纪瑞。",
    choices = {
      { label = "建碑", hint = "银-18 威+3 民+1", effect = { gold = -18, wei = 3, min = 1 } },
      { label = "罢之", hint = "德+2 民+1 威-1", effect = { de = 2, min = 1, wei = -1 } },
      { label = "免赋", hint = "银-22 民+4 威+1", effect = { gold = -22, min = 4, wei = 1 } },
    } },

  { id = "treasure_01", tag = "祥瑞", weight = 11, min_year = 1,
    title = "西域献玉", scene = "s_treasury",
    text = "西域贾人献美玉，价当万金。内府请收，以备郊祀之器。",
    choices = {
      { label = "收之", hint = "银-25 威+2 民-1", effect = { gold = -25, wei = 2, min = -1 } },
      { label = "却之", hint = "德+3 威-1 吏+1", effect = { de = 3, wei = -1, corr = 1 } },
      { label = "鬻玉", hint = "银+30 兵+2 威-2", effect = { gold = 30, troops = 2, wei = -2 } },
    } },

  { id = "treasure_02", tag = "祥瑞", weight = 10, min_year = 2,
    title = "番邦贡马", scene = "s_court",
    text = "北番贡良马二百，使者请开边市。马皆神骏，而所求甚奢。",
    choices = {
      { label = "受马开市", hint = "银-15 兵+2 威-1", effect = { gold = -15, troops = 2, wei = -1 } },
      { label = "却马闭关", hint = "威+2 兵-1 民-1", effect = { wei = 2, troops = -1, min = -1 } },
      { label = "半纳", hint = "银+10 兵+1 威-1", effect = { gold = 10, troops = 1, wei = -1 } },
    } },

  -- ── 奇案 ──
  { id = "mystery_01", tag = "奇案", weight = 13, min_year = 1,
    title = "内库失宝", scene = "s_treasury",
    text = "内库失金器数事，锁钥如故，守者互推。或言前朝旧物，不宜深究。",
    choices = {
      { label = "密查", hint = "吏+4 银-8 民+1", effect = { corr = 4, gold = -8, min = 1 } },
      { label = "严讯", hint = "吏-2 民-3 威+2", effect = { corr = -2, min = -3, wei = 2 } },
      { label = "不问", hint = "吏-4 民-1", effect = { corr = -4, min = -1 } },
    } },

  { id = "mystery_02", tag = "奇案", weight = 10, min_year = 2,
    title = "驿路失踪", scene = "s_court",
    text = "赴任官道经驿路，人马俱失。驿卒言夜闻马蹄，晓视唯余空鞍。",
    choices = {
      { label = "遣使查", hint = "银-12 吏+3 民+1", effect = { gold = -12, corr = 3, min = 1 } },
      { label = "悬赏", hint = "银-20 民+2 威+1", effect = { gold = -20, min = 2, wei = 1 } },
      { label = "讳之", hint = "威-2 吏-2 民-1", effect = { wei = -2, corr = -2, min = -1 } },
    } },

  { id = "mystery_03", tag = "奇案", weight = 11, min_year = 2,
    title = "科场关节", scene = "s_keju",
    text = "会试榜发，落第者喧于贡院，称榜上多显宦子弟，有鬻题之弊。",
    choices = {
      { label = "覆试", hint = "才+3 吏+3 银-10", effect = { cai = 3, corr = 3, gold = -10 } },
      { label = "黜主司", hint = "吏+2 威+2 才-1", effect = { corr = 2, wei = 2, cai = -1 } },
      { label = "弹压", hint = "民-3 威+1 吏-2", effect = { min = -3, wei = 1, corr = -2 } },
    } },

  { id = "occult_01", tag = "奇案", weight = 9, min_year = 3,
    title = "方士献丹", scene = "s_court",
    text = "方士献金丹，言服之可延年。太医院言金石酷烈，恐伤圣体。",
    choices = {
      { label = "试丹", hint = "健+3 德-2 民-1", effect = { health = 3, de = -2, min = -1 } },
      { label = "斥之", hint = "德+2 吏+1 威-1", effect = { de = 2, corr = 1, wei = -1 } },
      { label = "逐出", hint = "民+1 吏+1 威-1", effect = { min = 1, corr = 1, wei = -1 } },
    } },

  { id = "occult_02", tag = "奇案", weight = 8, min_year = 3,
    title = "术士惑众", scene = "s_collapse",
    text = "有术士以符水疗病，聚众数千，自称受命于天。州县不能禁。",
    choices = {
      { label = "捕治", hint = "民-2 威+2 吏+1", effect = { min = -2, wei = 2, corr = 1 } },
      { label = "招为方士", hint = "威-2 才-1 民+1", effect = { wei = -2, cai = -1, min = 1 } },
      { label = "遣散", hint = "银-8 民+2 吏+1", effect = { gold = -8, min = 2, corr = 1 } },
    } },

  -- ── 变法 ──
  { id = "reform_01", tag = "变法", weight = 14, min_year = 1,
    title = "新法之议", scene = "s_court",
    text = "有大臣陈新法十事：清丈田亩，均平赋役。豪右哗然，言其扰民。",
    choices = {
      { label = "推行", hint = "银+20 吏+3 民-3", effect = { gold = 20, corr = 3, min = -3 } },
      { label = "试行", hint = "吏+2 才+2 银-10", effect = { corr = 2, cai = 2, gold = -10 } },
      { label = "罢议", hint = "才-2 民+1 威-1", effect = { cai = -2, min = 1, wei = -1 } },
    } },

  { id = "reform_02", tag = "变法", weight = 10, min_year = 2,
    title = "考成之法", scene = "s_court",
    text = "请立考成法，以钱粮完欠黜陟有司。州县苦于催科，言其病民。",
    choices = {
      { label = "立之", hint = "吏+4 银+10 民-2", effect = { corr = 4, gold = 10, min = -2 } },
      { label = "宽期", hint = "吏+2 民+1 银-5", effect = { corr = 2, min = 1, gold = -5 } },
      { label = "不行", hint = "吏-2 才-1 民+1", effect = { corr = -2, cai = -1, min = 1 } },
    } },

  { id = "salt_01", tag = "变法", weight = 12, min_year = 1,
    title = "盐铁官营", scene = "s_treasury",
    text = "有司请榷盐铁，尽收其利。盐商大贾联名诉于阙下，言夺民之业。",
    choices = {
      { label = "官营", hint = "银+30 民-4 吏-1", effect = { gold = 30, min = -4, corr = -1 } },
      { label = "公私并", hint = "银+15 吏+1 民-1", effect = { gold = 15, corr = 1, min = -1 } },
      { label = "仍旧", hint = "银-5 民+2 威-1", effect = { gold = -5, min = 2, wei = -1 } },
    } },

  { id = "salt_02", tag = "变法", weight = 9, min_year = 2,
    title = "铁冶弛禁", scene = "s_treasury",
    text = "铁冶久禁，矿徒聚而为盗。有议弛禁，听民采铸，岁输其课。",
    choices = {
      { label = "弛禁", hint = "银+18 技+2 吏-2", effect = { gold = 18, tech = 2, corr = -2 } },
      { label = "严禁", hint = "威+2 民-3 银-8", effect = { wei = 2, min = -3, gold = -8 } },
      { label = "官督民采", hint = "银+10 吏+1 民-1", effect = { gold = 10, corr = 1, min = -1 } },
    } },

  { id = "tax_01", tag = "变法", weight = 11, min_year = 3,
    title = "税制更张", scene = "s_treasury",
    text = "旧税杂出，胥吏因缘为奸。有请并为一则，计亩征银，以省扰累。",
    choices = {
      { label = "并税", hint = "吏+3 银+15 民-2", effect = { corr = 3, gold = 15, min = -2 } },
      { label = "缓行", hint = "民+2 银-10 吏-1", effect = { min = 2, gold = -10, corr = -1 } },
      { label = "加征", hint = "银+25 民-6 威-1", effect = { gold = 25, min = -6, wei = -1 } },
    } },
}
