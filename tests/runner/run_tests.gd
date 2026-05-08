extends SceneTree

func _initialize():
	var failures := 0
	for path in _collect_unit_tests("res://tests/unit"):
		failures += _run(load(path), path)

	if failures > 0:
		printerr("TESTS_FAILED=%d" % failures)
		quit(1)
	else:
		print("TESTS_PASSED")
		quit(0)

func _collect_unit_tests(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files

	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if dir.current_is_dir():
			continue
		if name.ends_with(".gd") and name.begins_with("test_"):
			files.append(dir_path.path_join(name))
	dir.list_dir_end()

	files.sort()
	return files

func _run(test_script: Script, label: String) -> int:
	if test_script == null:
		printerr("TEST_LOAD_FAILED=%s" % label)
		return 1

	var t = test_script.new()
	if t.has_method("run"):
		var result = t.run()
		if typeof(result) == TYPE_BOOL:
			return 0 if result else 1
		return 1

	return 1
