class_name GameMenuTitle
extends Control

func _ready():
	setup_options_menu()

@export  var options_menu: GameMenuOptions
@onready var options_menu_button: Button = $ButtonGroup/OPTIONS
#region
# -----------------------------------------------------------------------------
func setup_options_menu():
	# Connect signals
	options_menu_button.connect(
		"toggled",
		func(value):
			update_options_menu()
	)
	
	# Update component status based on button default state
	update_options_menu()

func update_options_menu():
	#if options_menu_button.button_pressed:
		#open_options_menu()
	#else:
		#close_options_menu()
	pass
	
func open_options_menu():
	options_menu.visible = true

func close_options_menu():
	options_menu.visible = false

# -----------------------------------------------------------------------------
#endregion

@onready var button_group: VBoxContainer = $ButtonGroup
#region
# -----------------------------------------------------------------------------
func _set_toggle(toggled_on: bool, closure: Callable):
	if toggled_on:
		# Lock other buttons for prevent inputs
		_lock_buttons()
	else:
		# Unlock other buttons for prevent inputs
		_unlock_buttons()
	
	closure.call(toggled_on)

func _lock_buttons():
	for child in button_group.get_children():
		var button = child as Button
		button.disabled = true

func _unlock_buttons():
	for child in button_group.get_children():
		var button = child as Button
		button.disabled = false

# -----------------------------------------------------------------------------
#endregion
