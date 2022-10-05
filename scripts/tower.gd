class_name Tower extends Node

var levelName
var color
var rows
var cols
var iR
var oR
var w
var h
var flat
var map = []

var obj = {
	'platform': false,
	'ladder': false,
	'coin': false,
	'monster': false,
	'door': false,
	'key': false
}

func _init(level):
	# make 0 index the ground, increasing towards the sky
	var revertMap = []
	for i in level.map:
		revertMap.push_front(i)
	level.map = revertMap
	
	levelName = level.name
	flat      = level.flat
	color     = level.color
	rows      = level.map.size()
	cols      = level.map[0].length()
	
	if(flat):
		iR = Game.WIDTH / 2.0
	else:
		iR = Game.WIDTH / 3.4     # inner radius (walls)
		
	oR       = iR * 1.2           # outer radius (walls plus platforms)
	w        = cols * Game.COL_WIDTH
	h        = rows * Game.ROW_HEIGHT
	
	createMap(level.map)

func getCell(row, col):
	if (row < 0):
		obj.platform = true
		return obj
	elif (row >= rows):
		obj.platform = false
		return obj
	else:
		return map[row][Game.normalizeColumn(col)]

func createMap(source):
	
	for row in range( source.size() ):
		map.append([])
		for cell in source[row]:
			if(cell == 'K'):
				Game.prop.key.total += 1
			map[row].append({
				'platform': (cell == 'X'),
				'ladder':   (cell == 'H'),
				'coin':     (cell == 'o'),
				'door':     (cell == 'D'),
				'key':      (cell == 'K')
			})
