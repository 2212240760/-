# Android Creature-Catcher（3D简模、离线单机）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在安卓离线环境交付一个“收集养成驱动 + 站桩轻量实时战斗 + 战斗中抓捕 + 深度据点经营 + 章节解锁”的抓宠单机游戏，并具备可扩展到 300+ 宠物的内容管线。

**Architecture:** Godot 4.x 项目，核心系统以数据驱动（JSON）+ 运行时注册表（DataRegistry）组织；战斗/抓捕/养成/据点/章节推进拆成独立域服务，通过明确定义的数据结构与事件总线交互；保存系统全离线（JSON 存档），不依赖网络。

**Tech Stack:** Godot 4.x（GDScript）、JSON 数据表、Godot headless 脚本测试（自建轻量断言框架）、Android 导出模板（本地开发机配置）。

---

## File/Folder Structure（计划落地结构）

> 说明：这里用 Godot 的 `res://` 资源路径表达；仓库内实际路径对应 `/workspace` 下的同名目录。

- `project.godot`
- `src/`
  - `app/`（入口、场景切换、全局单例）
  - `domain/`（纯数据结构：宠物/技能/特性/掉落/章节）
  - `systems/`
    - `data/`（DataRegistry、校验器）
    - `save/`（存档读写、版本迁移）
    - `battle/`（战斗状态机、技能执行、AI）
    - `capture/`（抓捕公式、抗捕层数、捕捉道具）
    - `progress/`（章节/区域解锁、任务板）
    - `base/`（据点建造、产线、岗位/助手）
    - `inventory/`（物品、配方、掉落与合成）
  - `ui/`（UI 逻辑脚本）
- `scenes/`
  - `main_menu/`
  - `overworld/`
  - `battle/`
  - `base/`
- `data/`
  - `schema/`（JSON schema/约定说明）
  - `pets/`
  - `skills/`
  - `traits/`
  - `items/`
  - `recipes/`
  - `chapters/`
- `tests/`
  - `runner/`
  - `unit/`
  - `fixtures/`

---

## Milestones（建议按里程碑交付）

1. **Vertical Slice（可玩闭环）**：1 区域 + 10 宠 + 8 技能 + 10 物品 + 3 建筑 + 1 Boss + 存档
2. **规模化内容管线**：CSV/表格导出 → JSON → 校验 → 资源分包策略（移动端）
3. **深度据点经营**：助手岗位、产线链路、布局/相邻加成（轻量）、研究解锁
4. **章节扩展与平衡**：章节模板化、生态池与掉落池、难度曲线、Boss 机制库
5. **安卓发布准备**：性能/内存、包体控制、存档安全、崩溃恢复、离线兼容

下面任务会优先把里程碑 1 做到可运行可扩展，并为后续里程碑留好接口与数据结构。

---

### Task 1: 初始化工程骨架与测试跑通（Godot + headless tests）

**Files:**
- Create: `src/app/autoloads.gd`
- Create: `tests/runner/asserts.gd`
- Create: `tests/runner/run_tests.gd`
- Create: `tests/unit/test_asserts.gd`

- [ ] **Step 1: 创建最小断言库**

```gdscript
# tests/runner/asserts.gd
extends RefCounted

static func eq(a, b, msg := ""):
	if a != b:
		var suffix := "" if msg == "" else " | " + msg
		push_error("ASSERT_EQ failed: %s != %s%s" % [str(a), str(b), suffix])
		return false
	return true

static func ok(cond, msg := ""):
	if not cond:
		var suffix := "" if msg == "" else " | " + msg
		push_error("ASSERT_OK failed%s" % suffix)
		return false
	return true
```

- [ ] **Step 2: 创建测试 Runner（收集并运行测试脚本）**

```gdscript
# tests/runner/run_tests.gd
extends SceneTree

const Asserts = preload("res://tests/runner/asserts.gd")

func _initialize():
	var failures := 0
	failures += _run(preload("res://tests/unit/test_asserts.gd"))
	if failures > 0:
		printerr("TESTS_FAILED=%d" % failures)
		quit(1)
	else:
		print("TESTS_PASSED")
		quit(0)

func _run(test_script):
	var t = test_script.new()
	if t.has_method("run"):
		return int(not t.run())
	return 1
```

- [ ] **Step 3: 写一个最小单元测试确保 Runner 可用**

```gdscript
# tests/unit/test_asserts.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")

func run() -> bool:
	var ok := true
	ok = ok and Asserts.eq(1, 1)
	ok = ok and Asserts.ok(true)
	return ok
```

- [ ] **Step 4: 运行 headless 测试（本地开发机）**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: 输出 `TESTS_PASSED` 且进程退出码为 0

- [ ] **Step 5: 提交（可选）**

```bash
git add tests src
git commit -m "chore: add headless test runner"
```

---

### Task 2: 数据驱动核心（DataRegistry + schema 约定 + 校验）

**Files:**
- Create: `src/systems/data/data_registry.gd`
- Create: `src/systems/data/data_errors.gd`
- Create: `src/systems/data/validators.gd`
- Create: `data/schema/conventions.md`
- Create: `data/pets/sample_species.json`
- Test: `tests/unit/test_data_registry.gd`

- [ ] **Step 1: 定义数据错误结构**

```gdscript
# src/systems/data/data_errors.gd
extends RefCounted

class_name DataError

var path: String
var code: String
var message: String

func _init(p: String, c: String, m: String):
	path = p
	code = c
	message = m
```

- [ ] **Step 2: 实现 DataRegistry（加载 JSON，返回字典）**

```gdscript
# src/systems/data/data_registry.gd
extends RefCounted

class_name DataRegistry

const DataError = preload("res://src/systems/data/data_errors.gd")

var _cache := {}

func load_json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_cache[path] = {"_error": "open_failed", "_path": path}
		return _cache[path]
	var text := f.get_as_text()
	var parsed := JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY and typeof(parsed) != TYPE_ARRAY:
		_cache[path] = {"_error": "parse_failed", "_path": path}
		return _cache[path]
	_cache[path] = parsed
	return parsed
```

- [ ] **Step 3: 增加基础校验器（必填字段/类型）**

```gdscript
# src/systems/data/validators.gd
extends RefCounted

const DataError = preload("res://src/systems/data/data_errors.gd")

static func require_keys(obj: Dictionary, keys: Array[String], path: String) -> Array:
	var errors := []
	for k in keys:
		if not obj.has(k):
			errors.append(DataError.new(path, "missing_key", "missing key: %s" % k))
	return errors

static func require_type(obj: Dictionary, key: String, t: int, path: String) -> Array:
	var errors := []
	if obj.has(key) and typeof(obj[key]) != t:
		errors.append(DataError.new(path, "type_mismatch", "key %s expected %s" % [key, str(t)]))
	return errors
```

- [ ] **Step 4: 添加一个宠物物种样例数据（先跑通管线）**

```json
// data/pets/sample_species.json
{
  "id": "slime_001",
  "name": "软泥团",
  "rarity": "common",
  "elements": ["water"],
  "base_stats": { "hp": 30, "atk": 8, "def": 6, "spd": 7 },
  "learnset": ["splash", "bubble"],
  "possible_traits": ["sticky", "calm"]
}
```

- [ ] **Step 5: 写 DataRegistry 单测（读取样例，校验必填字段）**

```gdscript
# tests/unit/test_data_registry.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const DataRegistry = preload("res://src/systems/data/data_registry.gd")
const Validators = preload("res://src/systems/data/validators.gd")

func run() -> bool:
	var reg := DataRegistry.new()
	var d := reg.load_json("res://data/pets/sample_species.json")
	var ok := true
	ok = ok and Asserts.eq(d["id"], "slime_001")
	var errors := []
	errors.append_array(Validators.require_keys(d, ["id","name","rarity","elements","base_stats"], "sample_species"))
	ok = ok and Asserts.eq(errors.size(), 0)
	return ok
```

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

---

### Task 3: 运行时宠物实体（PetInstance）与图鉴/收集状态

**Files:**
- Create: `src/domain/pet_species.gd`
- Create: `src/domain/pet_instance.gd`
- Create: `src/systems/progress/codex.gd`
- Test: `tests/unit/test_codex.gd`

- [ ] **Step 1: 定义 PetSpecies（从 Dictionary 构建）**

```gdscript
# src/domain/pet_species.gd
extends RefCounted

class_name PetSpecies

var id: String
var name: String
var rarity: String
var elements: Array
var base_stats: Dictionary
var learnset: Array
var possible_traits: Array

static func from_dict(d: Dictionary) -> PetSpecies:
	var s := PetSpecies.new()
	s.id = d.get("id", "")
	s.name = d.get("name", "")
	s.rarity = d.get("rarity", "")
	s.elements = d.get("elements", [])
	s.base_stats = d.get("base_stats", {})
	s.learnset = d.get("learnset", [])
	s.possible_traits = d.get("possible_traits", [])
	return s
```

- [ ] **Step 2: 定义 PetInstance（等级、当前HP、已装配技能、特性）**

```gdscript
# src/domain/pet_instance.gd
extends RefCounted

class_name PetInstance

var species_id: String
var level := 1
var exp := 0
var trait_ids: Array[String] = []
var equipped_skills: Array[String] = []
var current_hp := 1

func to_save_dict() -> Dictionary:
	return {
		"species_id": species_id,
		"level": level,
		"exp": exp,
		"trait_ids": trait_ids,
		"equipped_skills": equipped_skills,
		"current_hp": current_hp
	}

static func from_save_dict(d: Dictionary) -> PetInstance:
	var p := PetInstance.new()
	p.species_id = d.get("species_id", "")
	p.level = int(d.get("level", 1))
	p.exp = int(d.get("exp", 0))
	p.trait_ids = d.get("trait_ids", [])
	p.equipped_skills = d.get("equipped_skills", [])
	p.current_hp = int(d.get("current_hp", 1))
	return p
```

- [ ] **Step 3: 实现 Codex（发现/捕获计数/首次捕获奖励钩子）**

```gdscript
# src/systems/progress/codex.gd
extends RefCounted

class_name Codex

var discovered := {}
var captured := {}

func mark_discovered(species_id: String) -> void:
	discovered[species_id] = true

func mark_captured(species_id: String) -> void:
	mark_discovered(species_id)
	captured[species_id] = int(captured.get(species_id, 0)) + 1

func captured_count(species_id: String) -> int:
	return int(captured.get(species_id, 0))
```

- [ ] **Step 4: 写 Codex 单测**

```gdscript
# tests/unit/test_codex.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const Codex = preload("res://src/systems/progress/codex.gd")

func run() -> bool:
	var c := Codex.new()
	c.mark_captured("slime_001")
	var ok := true
	ok = ok and Asserts.ok(c.discovered.has("slime_001"))
	ok = ok and Asserts.eq(c.captured_count("slime_001"), 1)
	return ok
```

- [ ] **Step 5: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

---

### Task 4: 战斗域最小可玩（站桩实时：冷却、能量、换宠、AI）

**Files:**
- Create: `src/systems/battle/battle_types.gd`
- Create: `src/systems/battle/battle_controller.gd`
- Create: `src/systems/battle/ai_simple.gd`
- Create: `data/skills/sample_skills.json`
- Test: `tests/unit/test_battle_cooldowns.gd`

- [ ] **Step 1: 定义战斗内 Combatant（只含必要字段）**

```gdscript
# src/systems/battle/battle_types.gd
extends RefCounted

class_name Combatant

var pet
var hp := 1
var max_hp := 1
var energy := 0
var cooldowns := {}
var status := {}
```

- [ ] **Step 2: 定义技能样例数据（cast_time=0 的站桩技能，只有冷却与伤害）**

```json
// data/skills/sample_skills.json
[
  { "id": "bubble", "name": "泡泡", "cooldown": 2.0, "energy_cost": 0, "power": 6 },
  { "id": "tackle", "name": "撞击", "cooldown": 1.0, "energy_cost": 0, "power": 4 }
]
```

- [ ] **Step 3: 实现 BattleController 的“时间推进 + 冷却递减 + 释放技能”**

```gdscript
# src/systems/battle/battle_controller.gd
extends RefCounted

class_name BattleController

var skill_defs := {}

func tick(combatant: Combatant, delta: float) -> void:
	for k in combatant.cooldowns.keys():
		combatant.cooldowns[k] = maxf(0.0, float(combatant.cooldowns[k]) - delta)

func can_cast(combatant: Combatant, skill_id: String) -> bool:
	return float(combatant.cooldowns.get(skill_id, 0.0)) <= 0.0

func cast(attacker: Combatant, defender: Combatant, skill_id: String) -> void:
	var s := skill_defs[skill_id]
	attacker.cooldowns[skill_id] = float(s["cooldown"])
	defender.hp = max(0, defender.hp - int(s["power"]))
```

- [ ] **Step 4: 写一个冷却单测（2 秒 CD 的技能在 2 秒后可再放）**

```gdscript
# tests/unit/test_battle_cooldowns.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const BattleController = preload("res://src/systems/battle/battle_controller.gd")
const Combatant = preload("res://src/systems/battle/battle_types.gd")

func run() -> bool:
	var bc := BattleController.new()
	bc.skill_defs = {"bubble": {"cooldown": 2.0, "power": 1}}
	var a := Combatant.new()
	var d := Combatant.new()
	a.cooldowns = {}
	d.hp = 10
	bc.cast(a, d, "bubble")
	var ok := true
	ok = ok and Asserts.ok(not bc.can_cast(a, "bubble"))
	bc.tick(a, 2.0)
	ok = ok and Asserts.ok(bc.can_cast(a, "bubble"))
	return ok
```

- [ ] **Step 5: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

---

### Task 5: 抓捕域最小可玩（战斗中抓：窗口、抗捕层数、道具强度）

**Files:**
- Create: `src/systems/capture/capture_system.gd`
- Create: `src/systems/capture/capture_types.gd`
- Create: `data/items/sample_capture_items.json`
- Test: `tests/unit/test_capture_math.gd`

- [ ] **Step 1: 定义捕捉上下文（目标状态、抗捕层数）**

```gdscript
# src/systems/capture/capture_types.gd
extends RefCounted

class_name CaptureContext

var hp_ratio := 1.0
var in_window := false
var resist_stacks := 0
var rarity := "common"
```

- [ ] **Step 2: 实现捕捉公式（可测、可调参）**

```gdscript
# src/systems/capture/capture_system.gd
extends RefCounted

class_name CaptureSystem

func chance(ball_power: float, ctx: CaptureContext) -> float:
	var hp_bonus := lerpf(0.6, 1.2, clampf(1.0 - ctx.hp_ratio, 0.0, 1.0))
	var window_bonus := 1.5 if ctx.in_window else 1.0
	var rarity_mul := 1.0
	if ctx.rarity == "rare":
		rarity_mul = 0.7
	elif ctx.rarity == "epic":
		rarity_mul = 0.5
	elif ctx.rarity == "legend":
		rarity_mul = 0.3
	var resist_mul := pow(0.85, float(ctx.resist_stacks))
	return clampf(ball_power * hp_bonus * window_bonus * rarity_mul * resist_mul, 0.01, 0.95)
```

- [ ] **Step 3: 添加捕捉道具样例（power）**

```json
// data/items/sample_capture_items.json
[
  { "id": "ball_basic", "name": "基础捕捉球", "power": 0.35 },
  { "id": "ball_pro", "name": "强化捕捉球", "power": 0.55 }
]
```

- [ ] **Step 4: 写捕捉数学单测（窗口开启时概率上升；抗捕层数上升时概率下降）**

```gdscript
# tests/unit/test_capture_math.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const CaptureSystem = preload("res://src/systems/capture/capture_system.gd")
const CaptureContext = preload("res://src/systems/capture/capture_types.gd")

func run() -> bool:
	var cs := CaptureSystem.new()
	var ctx := CaptureContext.new()
	ctx.hp_ratio = 0.2
	ctx.in_window = false
	ctx.resist_stacks = 0
	var a := cs.chance(0.35, ctx)
	ctx.in_window = true
	var b := cs.chance(0.35, ctx)
	ctx.in_window = true
	ctx.resist_stacks = 3
	var c := cs.chance(0.35, ctx)
	var ok := true
	ok = ok and Asserts.ok(b > a)
	ok = ok and Asserts.ok(c < b)
	return ok
```

- [ ] **Step 5: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

---

### Task 6: 存档域（离线、可迁移、版本化）

**Files:**
- Create: `src/systems/save/save_game.gd`
- Create: `src/systems/save/save_io.gd`
- Create: `src/systems/save/save_migrations.gd`
- Test: `tests/unit/test_save_roundtrip.gd`

- [ ] **Step 1: 定义 SaveGame（版本号 + 核心状态）**

```gdscript
# src/systems/save/save_game.gd
extends RefCounted

class_name SaveGame

const VERSION := 1

var player_party := []
var codex := {"discovered": {}, "captured": {}}
var inventory := {}
var base_state := {}
var progress := {"chapter_id": "chapter_01", "unlocked_regions": ["region_01"]}

func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"player_party": player_party,
		"codex": codex,
		"inventory": inventory,
		"base_state": base_state,
		"progress": progress
	}

static func from_dict(d: Dictionary) -> SaveGame:
	var s := SaveGame.new()
	s.player_party = d.get("player_party", [])
	s.codex = d.get("codex", s.codex)
	s.inventory = d.get("inventory", {})
	s.base_state = d.get("base_state", {})
	s.progress = d.get("progress", s.progress)
	return s
```

- [ ] **Step 2: 实现 SaveIO（写入 user://，读出并 parse）**

```gdscript
# src/systems/save/save_io.gd
extends RefCounted

const SaveGame = preload("res://src/systems/save/save_game.gd")

class_name SaveIO

func write(save: SaveGame, slot := "slot1") -> bool:
	var path := "user://%s.save.json" % slot
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(save.to_dict()))
	return true

func read(slot := "slot1") -> Dictionary:
	var path := "user://%s.save.json" % slot
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"_error": "open_failed"}
	var parsed := JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_error": "parse_failed"}
	return parsed
```

- [ ] **Step 3: 写存档往返单测（dict -> json -> dict）**

```gdscript
# tests/unit/test_save_roundtrip.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const SaveGame = preload("res://src/systems/save/save_game.gd")

func run() -> bool:
	var s := SaveGame.new()
	s.progress["chapter_id"] = "chapter_02"
	var text := JSON.stringify(s.to_dict())
	var back := JSON.parse_string(text)
	var ok := true
	ok = ok and Asserts.eq(back["progress"]["chapter_id"], "chapter_02")
	ok = ok and Asserts.eq(int(back["version"]), 1)
	return ok
```

- [ ] **Step 4: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

- [ ] **Step 5: 提交（可选）**

```bash
git add src tests
git commit -m "feat: add versioned offline save data"
```

---

### Task 7: 据点经营域（深度经营最小闭环：建筑/岗位/产线/配方）

**Files:**
- Create: `src/systems/base/base_types.gd`
- Create: `src/systems/base/base_manager.gd`
- Create: `src/systems/base/jobs.gd`
- Create: `src/systems/inventory/recipes.gd`
- Create: `data/recipes/sample_recipes.json`
- Test: `tests/unit/test_base_production.gd`

- [ ] **Step 1: 定义建筑与岗位（数据化 id + 等级 + 槽位）**

```gdscript
# src/systems/base/base_types.gd
extends RefCounted

class_name BuildingInstance

var building_id := ""
var level := 1
var assigned_helpers := []

func efficiency() -> float:
	return 1.0 + 0.1 * float(assigned_helpers.size()) + 0.2 * float(level - 1)
```

- [ ] **Step 2: 定义生产 Job（输入/输出/耗时）**

```gdscript
# src/systems/base/jobs.gd
extends RefCounted

class_name ProductionJob

var recipe_id := ""
var remaining := 0.0
var building_slot := ""
```

- [ ] **Step 3: 实现 BaseManager（推进时间、完成产出）**

```gdscript
# src/systems/base/base_manager.gd
extends RefCounted

const BuildingInstance = preload("res://src/systems/base/base_types.gd")
const ProductionJob = preload("res://src/systems/base/jobs.gd")

class_name BaseManager

var buildings := {}
var jobs: Array[ProductionJob] = []

func tick(delta: float) -> Array[String]:
	var completed := []
	for j in jobs:
		j.remaining = maxf(0.0, j.remaining - delta)
	for j in jobs.duplicate():
		if j.remaining <= 0.0:
			completed.append(j.recipe_id)
			jobs.erase(j)
	return completed
```

- [ ] **Step 4: 写据点产线单测（推进时间后 job 完成）**

```gdscript
# tests/unit/test_base_production.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const BaseManager = preload("res://src/systems/base/base_manager.gd")
const ProductionJob = preload("res://src/systems/base/jobs.gd")

func run() -> bool:
	var bm := BaseManager.new()
	var j := ProductionJob.new()
	j.recipe_id = "ball_basic"
	j.remaining = 5.0
	bm.jobs.append(j)
	var done := bm.tick(5.0)
	var ok := true
	ok = ok and Asserts.eq(done.size(), 1)
	ok = ok and Asserts.eq(done[0], "ball_basic")
	return ok
```

- [ ] **Step 5: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

---

### Task 8: 章节推进与内容模板（区域解锁门槛：Boss + 据点等级 + 收集率）

**Files:**
- Create: `src/systems/progress/chapter_manager.gd`
- Create: `data/chapters/chapter_01.json`
- Create: `data/chapters/chapter_02.json`
- Test: `tests/unit/test_chapter_gates.gd`

- [ ] **Step 1: 定义章节数据（id、解锁条件、生态池、奖励）**

```json
// data/chapters/chapter_02.json
{
  "id": "chapter_02",
  "requires": {
    "boss_defeated": "boss_01",
    "base_level": 3,
    "codex_captured_total": 10
  },
  "unlocks_regions": ["region_02"],
  "reward_recipes": ["ball_pro"]
}
```

- [ ] **Step 2: 实现 ChapterManager（判断是否可解锁）**

```gdscript
# src/systems/progress/chapter_manager.gd
extends RefCounted

class_name ChapterManager

func can_unlock(chapter: Dictionary, state: Dictionary) -> bool:
	var req := chapter.get("requires", {})
	if req.has("boss_defeated") and state.get("boss_defeated", "") != req["boss_defeated"]:
		return false
	if req.has("base_level") and int(state.get("base_level", 1)) < int(req["base_level"]):
		return false
	if req.has("codex_captured_total") and int(state.get("codex_captured_total", 0)) < int(req["codex_captured_total"]):
		return false
	return true
```

- [ ] **Step 3: 写解锁门槛单测**

```gdscript
# tests/unit/test_chapter_gates.gd
extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const ChapterManager = preload("res://src/systems/progress/chapter_manager.gd")

func run() -> bool:
	var cm := ChapterManager.new()
	var chapter := {
		"requires": {"boss_defeated": "boss_01", "base_level": 3, "codex_captured_total": 10}
	}
	var ok := true
	ok = ok and Asserts.ok(not cm.can_unlock(chapter, {"boss_defeated":"boss_01","base_level":2,"codex_captured_total":10}))
	ok = ok and Asserts.ok(cm.can_unlock(chapter, {"boss_defeated":"boss_01","base_level":3,"codex_captured_total":10}))
	return ok
```

- [ ] **Step 4: 运行测试**

Run: `godot --headless -s res://tests/runner/run_tests.gd`  
Expected: `TESTS_PASSED`

- [ ] **Step 5: 提交（可选）**

```bash
git add src data tests
git commit -m "feat: add chapter gating rules"
```

---

## Plan Self-Review（覆盖检查）

- 需求覆盖：数据驱动（Task 2）、收集/图鉴（Task 3）、站桩轻量实时战斗（Task 4）、战斗中抓捕（Task 5）、离线存档（Task 6）、深度据点经营的最小闭环骨架（Task 7）、章节解锁门槛（Task 8）。
- 缺口（留到后续里程碑）：真实场景与 UI 交互、技能/特性系统完整化、换宠全流程与敌方 AI 决策、掉落/合成完整闭环、资源分包与安卓性能专项、章节模板化生成工具、内容校验更强（schema）。

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-08-android-creature-catcher.md`. Two execution options:

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?

