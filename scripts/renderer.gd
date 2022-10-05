class_name Renderer extends Node2D

var ctx
var UI

var ground
var groundSpeed
var coinsLabel
var bankLabel
var debugLabel
var helpLabel
var scoreCoins
var scoreBank
var platformWidth

var images
var back
var backGradient
var keysPicked
var keysTotal
var cameraX2a

func _init(thisImages):
	ctx = VisualServer.canvas_item_create()
	VisualServer.canvas_item_set_z_index(ctx, 25)
	VisualServer.canvas_item_set_parent(ctx, Game.gameBox.get_canvas_item())
	VisualServer.canvas_item_set_transform(ctx, Transform2D.translated(Vector2(Game.WIDTH / 2.0, 0)))
	
	UI = Game.gameBox.get_node('UI/Control')
	coinsLabel = UI.get_node('coins')
	bankLabel = UI.get_node('money')
	debugLabel = UI.get_node('debug')
	helpLabel = UI.get_node('help')
	
	keysPicked = UI.get_node('keysPicked')
	keysTotal = UI.get_node('keysTotal')
	
	keysPicked.rect_size.x = Game.prop.key.picked * 58
	keysPicked.rect_position.x = Game.viewPort[0] - Game.prop.key.picked * 58 - 40
	
	keysTotal.rect_size.x = Game.prop.key.total * 58
	keysTotal.rect_position.x = Game.viewPort[0] - Game.prop.key.total * 58 - 40
	
	back = Game.gameBox.get_node('back')
	ground = Game.node2d.get_node('ground')
	groundSpeed  = Game.tower.cols * 116
	
	images = thisImages
	
	for item in images:
		images[item].w = images[item].src.get_width()
		images[item].h = images[item].src.get_height()
	
	scoreCoins = 0
	scoreBank = 0
	
	if(!Game.prop.debug.isEnable):
		debugLabel.visible = false
	
	if(Game.tower.flat):
		#VisualServer.set_default_clear_color(Color(Game.tower.color.wall))
		Game.gameBox.color = Game.tower.color.wall
		back.visible = false
		ground.texture = images.floor.src
		platformWidth = Game.COL_WIDTH
		Game.prop.ladder.w = 190
	else:
		#VisualServer.set_default_clear_color(Game.darken(Game.skyColor, 20)) # bg color
		Game.gameBox.color = Game.tower.color.sky if Game.tower.color.has('sky') else '#007177'
		back.visible = true
		ground.texture = images.ground.src
		platformWidth = 2 * Game.tower.oR * tan((360 / Game.tower.cols) * PI / 360)
		Game.prop.ladder.w = 140

func render (dt):
	Game.player.rx = Game.normalizex(Game.myLerp(Game.player.x, Game.player.dx, dt))
	Game.player.ry = Game.myLerp(Game.player.y, Game.player.dy, dt)
	Game.camera.rx = Game.normalizex(Game.myLerp(Game.camera.x, Game.camera.dx, dt))
	Game.camera.ry = Game.myLerp(Game.camera.y, Game.camera.dy, dt)
	
	Game.player.ry = max(0, Game.player.ry) # dont let sub-frame interpolation take the player below the horizon
	Game.camera.ry = max(0, Game.camera.ry) # dont let sub-frame interpolation take the camera below the horizon
	
	VisualServer.canvas_item_clear(ctx)
	
	cameraX2a = Game.x2a(Game.camera.rx)
	
	# simply render the furthest items first,
	# then the nearer items render over the top of them
	if(Game.tower.flat):
		renderTower()
	else:
		renderSky()
		renderBack()
		renderTower()
		
	renderFront()
	renderGround()
	renderPlayer()
	renderScore()

func renderSky ():
	var x  = Game.normalize(702 * Game.camera.x / Game.tower.w, 0, 702)
	var y  = Game.normalize(Game.HEIGHT * Game.camera.y / Game.tower.h, 0, Game.HEIGHT)
	var nx = Game.WIDTH - x
	var ny = Game.HEIGHT - y
	back.rect_position.x = -nx
	back.rect_position.y = -ny

func renderGround ():
	var x      = groundSpeed * 2 * (Game.camera.rx / Game.tower.w)
	var y      = Game.ty(0) - 6
	
	ground.rect_position.y = y
	
	if (x > groundSpeed):
		ground.rect_position.x = -x + groundSpeed
	else:
		ground.rect_position.x = -x

func renderTower ():
	var y
	var top = max(Game.ty(Game.tower.h), 0)
	var bottom = min(Game.ty(0), Game.HEIGHT)
	var offset = 0
	var offsets = [0.25, 0.75]
	var lineColor = Color(0, 0, 0, 0.2)
	
	if(!Game.tower.flat):
		addRect(-Game.tower.iR + Game.offset[0] - 4, 0, Game.tower.iR * 2 + 8, bottom - top, lineColor)
	
	var cols = Game.tower.cols
	if(Game.tower.flat):
		cols = int(Game.viewPort[0] / Game.COL_WIDTH) + 2
	
	var normalize = Game.normalize(Game.WIDTH * Game.camera.rx / Game.WIDTH, 0, Game.COL_WIDTH)
	for n in cols:
		var x = n * Game.COL_WIDTH + Game.COL_WIDTH
		
		if(Game.tower.flat):
			x = x + normalize - Game.COL_WIDTH 
			x = Game.offset[0] + Game.viewCenter[0] - x
			addRect(x, 0, 140, bottom - top, Color(0, 0, 0, 0.05))
		else:
			var a = Game.normalizeAngle180(Game.x2a(x) - cameraX2a)
			
			if (Game.between(a, -90, 90)):
				var aRange = min(1, abs(a / 90))
				var w = min(134, Game.COL_WIDTH - aRange * Game.COL_WIDTH)
				var fillColor = Game.darken(Game.tower.color.wall, aRange * 30)
				
				x = Game.tx(x - Game.COL_WIDTH / 2, Game.tower.iR) + Game.offset[0]
				addRect(x, 0, w, bottom - top, fillColor)
	
	for n in Game.tower.rows:
		y = Game.ty(n * Game.ROW_HEIGHT) + Game.ROW_HEIGHT / 2.0
		if (Game.between(y, -Game.ROW_HEIGHT, Game.HEIGHT + Game.ROW_HEIGHT)):
			if(!Game.tower.flat):
				addLine(-Game.tower.iR + Game.offset[0], y, Game.tower.iR + Game.offset[0], y, lineColor, 1.0)
			else:
				addLine(-Game.viewCenter[0], y, Game.viewPort[0], y, lineColor, 1.0)
			
			renderBricks(normalize, y, offsets[offset], lineColor)
		
		if(offset < offsets.size() - 1):
			offset = offset + 1
		else:
			offset = 0

func renderBricks (normalize, y, offset, color):
	var x
	var cols
	
	cols = Game.tower.cols
	if(Game.tower.flat):
		cols = int(Game.viewPort[0] / Game.COL_WIDTH) + 1
	
	for n in cols:
		x = (n + offset) * Game.COL_WIDTH
		
		if(Game.tower.flat):
			x = x + normalize
			x = Game.offset[0] + Game.viewCenter[0] + Game.COL_WIDTH / 2 - x
			addLine(x, y, x, y - Game.ROW_HEIGHT, color, 1.0)
		else:
			var a = Game.normalizeAngle180(Game.x2a(x) - cameraX2a)
			if (Game.between(a, -90, 90)):
				x = Game.tx(x, Game.tower.iR) + Game.offset[0]
				addLine(x, y, x, y - Game.ROW_HEIGHT, color, 1.0)

func renderBack():
	var left  = Game.x2col(Game.camera.rx - Game.tower.w / 4)
	var right = Game.x2col(Game.camera.rx + Game.tower.w / 4)
	
	renderQuadrant(Game.normalizeColumn(left  - 3), left,  1)
	renderQuadrant(Game.normalizeColumn(right + 3), right, -1)

func renderFront():
	var left
	var right
	var center = Game.x2col(Game.camera.rx)
	
	if(Game.tower.flat):
		left = Game.x2col(Game.camera.rx - Game.viewCenter[0])
		right = Game.x2col(Game.camera.rx + Game.viewCenter[0])
	else:
		left = Game.x2col(Game.camera.rx - Game.tower.w / 4)
		right = Game.x2col(Game.camera.rx + Game.tower.w / 4)
	
	renderQuadrant(left, Game.normalizeColumn(center + 0), +1)
	renderQuadrant(right, Game.normalizeColumn(center - 1), -1)

func renderQuadrant (mn, mx, dir):
	var y
	var cell
	var rmin = max(0, Game.y2row(Game.camera.ry - Game.HORIZON) - 1)
	var rmax = min(Game.tower.rows - 1, rmin + (Game.HEIGHT / Game.ROW_HEIGHT + 1))
	var col    = mn
	
	while (col != mx):
		for r in range(rmin, rmax + 1):
			y = Game.ty(r * Game.ROW_HEIGHT)
			cell = Game.tower.getCell(r, col)
			
			if (cell.platform):
				renderPlatform(col, y)
			elif (cell.ladder):
				renderImage('ladder', col, y, Game.prop.ladder.w, Game.prop.ladder.h)
			elif (cell.coin && str(cell.coin) != 'picked'):
				renderImage('coins', col, y, Game.prop.coin.w, Game.prop.coin.h)
			elif (cell.key):
				renderImage('key', col, y, Game.prop.key.w, Game.prop.key.h)
			elif (cell.door):
				renderImage('door', col, y, Game.prop.door.w, Game.prop.door.h)
			
			if (cell.monster):
				renderMonster(y, cell.monster)
				
		col = Game.normalizeColumn(col + dir)

func renderPlatform (col, y):
	var x = Game.col2x(col + 0.5)
	var a = Game.normalizeAngle180(Game.x2a(x) - cameraX2a)
	var x0 = Game.tx(x, Game.tower.oR)
	var x1 = x0 - platformWidth / 2 + Game.offset[0]
	var x2 = x0 + platformWidth / 2 + Game.offset[0]
	
	var colorRange  = min(1, abs(a / 90))
	var fillColor   = Game.darken(Game.tower.color.platform, 40 * colorRange)
	var shadowColor = Game.darken(Game.tower.color.platform, 80 * colorRange)
	var greenColor  = Game.darken('#3c8b26', 20 * colorRange)
	
	x = x1 + 8
	y = y - Game.ROW_HEIGHT
	var w = x2 - x1 - 8
	var h = Game.ROW_HEIGHT
	var r = 10
	
	var base = [
		Vector2(x, y + r),         Vector2(x + r, y),         Vector2(x + w - r, y),
		Vector2(x + w, y + r),     Vector2(x + w, y + h - r), Vector2(x + w - r, y + h),
		Vector2(x + r, y + h),     Vector2(x, y + h - r),     Vector2(x, y + r)
	]
	
	var top = [
		Vector2(x, y + r),         Vector2(x + r, y),         Vector2(x + w - r, y),
		Vector2(x + w, y + r),     Vector2(x, y + r)
	]
	
	var shadow = [
		Vector2(x, y + h - r),     Vector2(x + w, y + h - r), Vector2(x + w - r, y + h),
		Vector2(x + r, y + h),     Vector2(x, y + h - r)
	]
	
	addPoly(base, [fillColor])
	addPoly(top, [greenColor])
	addPoly(shadow, [shadowColor])

func renderImage(name, col, y, dW, dH):
	var src  = images[name].src
	var imgW = images[name].w
	var imgH = images[name].h
	
	var x    = Game.col2x(col + 0.5)
	var a    = Game.normalizeAngle180(Game.x2a(x) - cameraX2a)
	var f    = floor(10 * min(1, abs(a / 90)))
	var d    = (12 - f) * 0.1
	var x0   = Game.tx(x, Game.tower.oR)
	var x1   = x0 - dW / 2 + Game.offset[0]
	
	if(name == 'door' && !Game.tower.flat):
		dW = dW - f * 12
		x0 = Game.tx(x, Game.tower.iR)
		x1 = x0 - dW / 2 + Game.offset[0]
	
	addImage(src, 0, 0, imgW, imgH, x1, y - dH, dW, dH, Color(d, d, d, 1))

func renderMonster (y, monster):
	var a = monster.animation
	var x = Game.tx(monster.x, Game.tower.oR) + monster.nx + Game.offset[0]
	y = Game.ty(monster.y) + monster.ny
	
	var w = monster.w
	var h = monster.h
	
	addImage(monster.imageSrc, a.x + (monster.animationFrame * a.w), a.y, a.w, a.h, x, y - h - 1, w, h)

func renderPlayer ():
	var thisX = Game.tx(Game.player.rx, Game.tower.iR) - Game.player.w / 1.5
	var thisY = Game.ty(Game.player.ry) - Game.player.h
	
	addImage(
		images.player.src,
		Game.player.animation.x + (Game.player.animationFrame * Game.player.animation.w),
		Game.player.animation.y,
		Game.player.animation.w,
		Game.player.animation.h,
		thisX + Game.offset[0], thisY,
		Game.player.w * 1.5, Game.player.h
	)

func renderScore ():
	var score = Game.prop.vars.score
	var bank = Game.prop.userVars.bank
	var nominal = 1
	
	if (score > scoreCoins): scoreCoins = scoreCoins + nominal
	else: scoreCoins = score
	
	#coinsLabel.text = '$' + str("%.2f" % scoreCoins)
	coinsLabel.text = str(scoreCoins)
	
	if (bank > scoreBank + 100): nominal = 100
	elif (bank > scoreBank + 10): nominal = 10
	elif (bank > scoreBank + 1): nominal = 1
	
	if (bank > scoreBank): scoreBank = scoreBank + nominal
	else: scoreBank = bank
	
	bankLabel.text = str(scoreBank)

func addLine(x, y, x1, y1, color, width):
	var from = Vector2(x, y)
	var to = Vector2(x1, y1)
	VisualServer.canvas_item_add_line (ctx, from, to, color, width, false)

func addStrokeRect(x, y, w, h, color, width):
	addLine(x, y, x + w, y, color, width)
	addLine(x + w, y, x + w, y + h, color, width)
	addLine(x + w, y + h, x, y + h, color, width)
	addLine(x, y + h, x, y, color, width)

func addRect(x, y, width, height, color):
	var rect2 = Rect2(Vector2(x, y), Vector2(width, height))
	VisualServer.canvas_item_add_rect (ctx, rect2, color)

func addPoly(arrVec2, arrColor):
	VisualServer.canvas_item_add_polygon(ctx, arrVec2, arrColor)

func addPolyLine(arrVec2, arrColor, width = 1.0):
	VisualServer.canvas_item_add_polyline(ctx, arrVec2, arrColor, width)

func addImage(
		image,
		sx, sy, sWidth, sHeight,
		dx, dy, dWidth, dHeight,
		color = Color(1, 1, 1, 1)
	):
	var rect2pos = Rect2(Vector2(dx, dy), Vector2(dWidth, dHeight))
	var rect2src = Rect2(Vector2(sx, sy), Vector2(sWidth, sHeight))
	
	if(ctx && typeof(image) > 15):
		VisualServer.canvas_item_add_texture_rect_region (
			ctx,
			rect2pos,
			image,
			rect2src,
			color
		)
