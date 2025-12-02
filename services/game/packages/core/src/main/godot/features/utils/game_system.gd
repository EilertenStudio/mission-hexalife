class_name GameSystem
extends Object



static func log(node: Node, ...args: Array):
	# Rebuild context path
	#var path = ""
	#var parent = node.get_parent()
	#while parent:
		#if parent.is_class("Node2D"):
			#path = parent.name+"|"+path
		#parent = parent.get_parent()
	#path += "/"+node.name.to_pascal_case()
	
	#var clazz = node.get_class()
	var name = node.name.to_pascal_case()
	
	print_rich("%s %s" % [
		#"[color=#215dbf][b][%s][/b][/color]" % clazz,
		"[b][%s][/b]" % name,
		"%s" % args,
	])
