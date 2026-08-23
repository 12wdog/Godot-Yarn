@abstract
class_name Module
extends Node

static func has_module(node: Node, module_script: Script) -> Module:
	for child in node.get_children():
		if child is not Module: 
			continue
		
		var script = child.get_script()
		
		while script:
			if script == module_script:
				return child
			
			if script == Module:
				break
			
			script = script.get_base_script()
	
	return null
