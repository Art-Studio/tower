class_name myCamera extends Node

var x
var y
var dx
var dy
var miny
var maxy
var rx
var ry

func _init():
	x    = Game.player.x
	y    = Game.player.y
	dx   = 0
	dy   = 0
	miny = 0
	maxy = Game.tower.h

func update():
	x  = Game.player.x
	y  = Game.player.y
	dx = Game.player.dx
	dy = Game.player.dy
