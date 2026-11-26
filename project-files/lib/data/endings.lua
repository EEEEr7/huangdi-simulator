-- lib/data/endings.lua
-- 结局：rank 1 最上，5 最下；scene 取屏幕白名单。
-- 含盛世/中兴/守成/偏安/暴亡/亡国/禅让/被废/寿终正寝九种。

return {
  { id = "shengshi", name = "盛世", rank = 1, scene = "s_prosper",
    text = "御宇三十年，仓廪充溢，刑措不用。四夷遣使入贡，道不拾遗。史臣书曰：三代以下，未之有也。" },

  { id = "zhongxing", name = "中兴", rank = 2, scene = "s_prosper",
    text = "承大乱之后，厉精图治。十年之间，府库复实，边防复固。海内称之曰中兴之主。" },

  { id = "chanzang", name = "禅让", rank = 2, scene = "s_court",
    text = "以天命有归，下诏禅位。从容出宫，居于别馆。史臣谓其知进退，不失为令主。" },

  { id = "shoucheng", name = "守成", rank = 3, scene = "s_court",
    text = "谨守祖宗成法，不轻改作。在位既久，国无大患，亦无大功。后世谓之守成之主。" },

  { id = "shouzhong", name = "寿终正寝", rank = 3, scene = "s_court",
    text = "享国既久，寿逾古稀。一日不豫，崩于正寝。遗诏薄葬，百姓思之。" },

  { id = "pianan", name = "偏安", rank = 4, scene = "s_court",
    text = "疆土日蹙，仅保一隅。虽无亡国之祸，然威令不出都门，史臣惜之。" },

  { id = "baowang", name = "暴亡", rank = 5, scene = "s_collapse",
    text = "春秋方盛，忽崩于寝殿。或言丹药，或言内变。储位未定，人心惶惶。" },

  { id = "wangguo", name = "亡国", rank = 5, scene = "s_collapse",
    text = "兵临城下，宗庙不守。帝自去冠冕，素车出降。社稷遂绝，海内易主。" },

  { id = "beifei", name = "被废", rank = 5, scene = "s_collapse",
    text = "权臣矫诏，太后下废立之命。幽居别宫，不复预闻国政。春秋祭祀亦不及焉。" },
}
