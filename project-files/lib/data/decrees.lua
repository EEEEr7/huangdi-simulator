-- lib/data/decrees.lua
-- 诏令十六条：开科/征兵/赈灾/修河/巡狩/大赦/赏军/查贪/
-- 封禅/兴学/屯田/铸钱/市易/禁奢/练兵/和籴。
-- 字段：{ id, name(≤6字), hint(≤16字), cost = { gold, grain }, effect = { ... } }
-- cost 为支出，effect 为增量；hint 写净变化。

return {
  { id = "keju", name = "开科取士", hint = "银-25 才+3 威+2",
    cost = { gold = 25 }, effect = { cai = 3, wei = 2 } },

  { id = "conscript", name = "征兵", hint = "银-15 兵+6 军+2",
    cost = { gold = 15 }, effect = { troops = 6, jun = 2 } },

  { id = "relief", name = "赈灾", hint = "粮-30 民+6 吏-1",
    cost = { grain = 30 }, effect = { min = 6, corr = -1 } },

  { id = "river", name = "修河", hint = "银-30 民+3 吏+2",
    cost = { gold = 30 }, effect = { min = 3, corr = 2 } },

  { id = "tour", name = "巡狩", hint = "银-20 威+3 健-3",
    cost = { gold = 20 }, effect = { wei = 3, health = -3 } },

  { id = "amnesty", name = "大赦", hint = "银-10 德+4 民+3 吏-4",
    cost = { gold = 10 }, effect = { de = 4, min = 3, corr = -4 } },

  { id = "reward_army", name = "赏军", hint = "银-25 军+5 威+1 民-1",
    cost = { gold = 25 }, effect = { jun = 5, wei = 1, min = -1 } },

  { id = "anti_corruption", name = "查贪", hint = "银-10 吏+5 威+1 民-2",
    cost = { gold = 10 }, effect = { corr = 5, wei = 1, min = -2 } },

  { id = "fengshan", name = "封禅", hint = "银-50 威+6 德-2 民-3",
    cost = { gold = 50 }, effect = { wei = 6, de = -2, min = -3 } },

  { id = "school", name = "兴学", hint = "银-15 才+3 技+2 民-1",
    cost = { gold = 15 }, effect = { cai = 3, tech = 2, min = -1 } },

  { id = "tuntian", name = "屯田", hint = "银-10 粮+40 军-1",
    cost = { gold = 10 }, effect = { grain = 40, jun = -1 } },

  { id = "mint", name = "铸钱", hint = "银+30 民-3",
    cost = { gold = 10 }, effect = { gold = 40, min = -3 } },

  { id = "market", name = "市易", hint = "银-5 技+2 吏-1",
    cost = { gold = 20 }, effect = { gold = 15, tech = 2, corr = -1 } },

  { id = "luxury_ban", name = "禁奢", hint = "银-5 民+3 吏+1",
    cost = { gold = 5 }, effect = { min = 3, corr = 1 } },

  { id = "drill", name = "练兵", hint = "银-20 兵+4 军+4",
    cost = { gold = 20 }, effect = { troops = 4, jun = 4 } },

  { id = "grain_buy", name = "和籴", hint = "银-30 粮+45 民-2",
    cost = { gold = 30 }, effect = { grain = 45, min = -2 } },
}
