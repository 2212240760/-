extends RefCounted

class_name DataError

var path: String
var code: String
var message: String

func _init(p: String, c: String, m: String):
	path = p
	code = c
	message = m
