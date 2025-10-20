class_name Player extends Entity

var char_name : String

func init_knockback(amount, force, sender):
	if not grabbed:
		super.init_knockback(amount, force, sender)
