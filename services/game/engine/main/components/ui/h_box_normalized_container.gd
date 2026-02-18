@tool
class_name HBoxNormalizedContainer
extends HBoxContainer

@export_tool_button("Update Item Gap", "ItemList") 
var in_item_gap_update = do_items_gap_update

#func _set(property: StringName, value: Variant) -> bool:
	#Log.event(self, "Property changed (%s = %s)" % [property, value])
	#match property:
		#'anchors_preset', 'size':
			#do_items_gap_update()
	#return false

#func _notification(what: int) -> void:
	#Log.event(self, "Notification recieved (%s)" % [what])
	#match what:
		#NOTIFICATION_RESIZED:
			#do_items_gap_update()

func do_items_gap_update():
	var container_size = self.size.x
	
	var item_count = get_child_count()
	var item_last_size = 0
	var item_delta = 0
	
	for item in get_children():
		#item_count += 1
		item_delta += item.size.x
		#item_last_size = item.size.x
	
	#var gap = (container_size / clamp(item_count - 1, 0, item_count)) - ((item_delta / 2) - item_last_size)
	#var gap = (container_size / item_count)
	var gap = (container_size / item_count) - (item_delta / item_count / 2)
	
	
	Log.debug(self, "Update items gap (item_count: %s) (size: %s) (gap: %s)" % [item_count, container_size, gap])
	self.add_theme_constant_override("separation", gap)
	pass
