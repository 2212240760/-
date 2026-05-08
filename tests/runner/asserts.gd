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
