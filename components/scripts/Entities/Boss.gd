class_name Boss extends Enemy

var boss_name
@warning_ignore("unused_signal")
signal set_health_bar_to_gui(vit)

var spawning = true # variabile a true finché non finisce l'animazione di spawning, altrimenti false
var dying = false # variabile a false finché il boss è in vita, poi a true per l'animazione di death
