# 数据约定（JSON）

## 通用规则

- 所有数据文件使用 UTF-8 编码的合法 JSON（不允许 `//` 或 `/* */` 注释）。
- 文件内的顶层结构只能是 Object（Dictionary）或 Array。
- 约定 `id` 为稳定主键（String），用于跨表引用与存档引用；一旦发布尽量不改。
- 约定 `name` 为展示名（String），可本地化；不可作为引用键。
- 引用其他实体时使用对方的 `id`（String）或 `id` 数组。

## 类型约定

- 数值：使用 JSON number（在 Godot 中会解析为 int/float，读入后由校验器约束具体类型）。
- 枚举：使用 String（例如 `rarity`）。
- 集合：使用 Array（例如 `elements`、`learnset`）。
- 结构：使用 Object（例如 `base_stats`）。

## 运行时校验

- 运行时优先使用 `src/systems/data/validators.gd` 进行轻量校验：
  - 必填字段（missing_key）
  - 字段类型（type_mismatch）
- 校验失败以 `DataError`（`src/systems/data/data_errors.gd`）数组返回，调用方决定是否中止或降级。

