class_name LevelGenerator extends Node

var levelVar = [
	[
		'··X··',
		'·····',
		'····X',
		'·····',
		'XX···'
	],
	[
		'·HXXX',
		'·H···',
		'·H···',
		'·H···',
		'XX···'
	],
	[
		'·····',
		'·····',
		'·····',
		'·····',
		'·····'
	],
	[
		'·····',
		'·····',
		'XXXXX',
		'·····',
		'·····'
	]
]

func _ready():
	pass 

func getLevel():
	var result = '\n\n\n'
	var map = []
	var varSize = levelVar.size() - 1
	
	var offset = 5
	var rowCount = Game.randomInt(0, 30)
	for row in range(rowCount):
		for _col in range(4):
			var lVar = levelVar[Game.randomInt(0, varSize)]
			for i in range(5):
				if(map.size() <= i+offset*row): map.append('')
				map[i+offset*row] += lVar[i]
	
	for x in map:
		result += '\n' + x
	#print(result)
	return result
