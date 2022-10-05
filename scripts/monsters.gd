class_name Monsters extends Node

var all

func _init(level):
	all = createMonsters(level.map)

func update (dt):
	var thisAll = all
	var mx = thisAll.size()
	
	for n in range(mx):
		thisAll[n].update(dt)

func createMonsters (source):
	var type
	var monster: Monster
	var thisAll = []
	
	for row in range(Game.tower.rows):
		for col in range(Game.tower.cols):
			type = int(source[row][col])
			
			if (type > 0):
				type -= 1
				monster = Monster.new(row, col, Game.prop.monsters[type])
				thisAll.append(monster)
				Game.tower.map[row][col].monster = monster
			else:
				Game.tower.map[row][col].monster = false

	return thisAll
