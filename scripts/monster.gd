class_name Monster extends Node

var row
var col
var x
var y
var dx
var dy
var w
var h
var nx
var ny
var type
var animation

var minrow
var maxrow
var miny
var maxy
var mincol
var maxcol
var minx
var maxx
var wrapx
var left
var up
var right
var down
var animationFrame
var animationCounter
var imageSrc

func _init(thisRow, thisCol, thisType):
	row  = thisRow
	col  = thisCol
	x    = Game.col2x(thisCol + 0.5)
	y    = Game.row2y(thisRow)
	dx   = 0
	dy   = 0
	w    = thisType.w
	h    = thisType.h
	nx   = thisType.nx * thisType.w
	ny   = thisType.ny * thisType.h
	type = thisType
	self[thisType.dir] = true
	animation = thisType.animation[thisType.dir]
	imageSrc = thisType.src
	
	if (thisType.vertical):
		minrow = thisRow
		maxrow = thisRow
		
		while ((minrow > 0) && !Game.tower.map[minrow - 1][thisCol].platform
		&& !Game.tower.map[minrow-1][thisCol].ladder):
			minrow -= 1
		
		while ((maxrow < Game.tower.rows-1) && !Game.tower.map[maxrow + 1][thisCol].platform
		&& !Game.tower.map[maxrow + 1][thisCol].ladder):
			maxrow += 1
		
		miny = Game.row2y(minrow)     + ny
		maxy = Game.row2y(maxrow + 1) + ny - h
	
	if (thisType.horizontal):
		mincol = thisCol
		maxcol = thisCol
		
		while ((mincol != Game.normalizeColumn(thisCol + 1))
		&& !Game.tower.getCell(thisRow, mincol - 1).platform
		&& !Game.tower.getCell(thisRow, mincol - 1).ladder
		&& Game.tower.getCell(thisRow - 1, mincol - 1).platform):
			mincol = Game.normalizeColumn(mincol - 1)
		
		while ((maxcol != Game.normalizeColumn(thisCol - 1))
		&& !Game.tower.getCell(thisRow, maxcol + 1).platform
		&& !Game.tower.getCell(thisRow, maxcol + 1).ladder
		&& Game.tower.getCell(thisRow - 1, maxcol + 1).platform):
			maxcol = Game.normalizeColumn(maxcol + 1)
		
		minx  = Game.col2x(mincol)     - nx
		maxx  = Game.col2x(maxcol + 1) - nx - w
		wrapx = minx > maxx

func update(dt):
	if (left):
		dx = -type.speed
	elif (right):
		dx = type.speed
	else:
		dx = 0
	
	if (up):
		dy = type.speed
	elif (down):
		dy = -type.speed
	else:
		dy = 0
	
	x  = Game.normalizex(x  + (dt * dx))
	y  = y + (dt * dy)
	
	if (up && (y > maxy)):
		y    = maxy
		up   = false
		down = true
		animation = type.animation.down
	elif (down && (y < miny)):
		y    = miny
		down = false
		up   = true
		animation = type.animation.up
	
	if (left && (x < minx) && (!wrapx || x > maxx)):
		x = minx
		left = false
		right = true
		animation = type.animation.right
	elif (right && (x > maxx) && (!wrapx || x < minx)):
		x = maxx
		right = false
		left = true
		animation = type.animation.left
	
	var thisRow = Game.y2row(y - ny)
	var thisCol = Game.x2col(x - nx)
	
	if ((thisRow != row) || (thisCol != col)):
		Game.tower.map[row][col].monster = null
		Game.tower.map[thisRow][thisCol].monster = self
		row = thisRow
		col = thisCol
	
	Game.animate(Game.FPS, self, false)
