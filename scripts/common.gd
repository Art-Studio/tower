extends Node

#---------------------------
# CONSTANTS
#---------------------------
const FPS           = 30     # 'update' frame rate fixed at 60fps independent of rendering loop
const WIDTH         = 1440   # must have width multiple of 360...
const HEIGHT        = 1080   # ... and 4:3 w:h ratio
const HORIZON       = 220    # how much ground to show below the tower
const METER         = 70     # how many pixels represent 1 meter
const COL_WIDTH     = 210.0  # 2D column width
const ROW_HEIGHT    = 70.0   # 2D row height
# amount of row considered 'near' enough to surface to allow jumping onto that row (instead of bouncing off again)
const ROW_SURFACE   = ROW_HEIGHT
const GRAVITY       = 9.8    # (exagerated) gravity
const MAXDX         = 10     # player max horizontal speed (meters per second)
# player max vertical speed (meters per second) - ENSURES CANNOT FALL THROUGH PLATFORM SURFACE
const MAXDY         = 12
const CLIMBDY       = 6      # player climbing speed (meters per second)
const ACCEL         = 0.4    # player take to reach maxdx (horizontal acceleration)
const FRICTION      = 0.8    # player take to stop from maxdx (horizontal friction)
const IMPULSE       = 400    # player jump impulse
const FALLING_JUMP  = 30     # player allowed to jump after falling off a platform
# how far from ladder center (60%) is ladder's true collision boundary e.g.
# you fall off if you get more than 60% away from center of ladder
const LADDER_EDGE   = 0.6
# useful enum for declaring an abstract direction
const DIR = {
	'NONE': 0,
	'LEFT': 1,
	'RIGHT': 2,
	'UP': 3,
	'DOWN': 4
}

#---------------------------
# VARIABLES
#---------------------------

var tree
var gameBox
var node2d
var offset = [0, 0]
var viewPort = [0, 0]
var viewCenter = [0, 0]

var tower: Tower
var monsters: Monsters
var player: Player
var camera: myCamera
var renderer: Renderer

var langs = load('res://langs.tres')

var prop = {
	'debug': {
		'isEnable': false,
		'level': 9,
		'input': ''
	},
	
	'vars': {
		'gameStop': false,
		'lvsTotal': getNumOfLevels(),
		'score': 0
	},
	
	'userVars': {
		'lang': 'en',
		'levelNow': 1,
		'bank': 0
	},
	
	# IMAGES ============================================================ IMAGES
	'images': {
		'coins':  { 'src': preload('res://img/coin.png') },
		'ladder': { 'src': preload('res://img/ladder.png') },
		'player': { 'src': preload('res://img/hero.png') },
		'ground': { 'src': preload('res://img/ground.png') },
		'floor':  { 'src': preload('res://img/floor.png') },
		'door':   { 'src': preload('res://img/door.png') },
		'key':    { 'src': preload('res://img/key.png') }
	},
	
	# SOUNDS ============================================================ SOUNDS
	'audio': {
		'var': {
			'nodeFx': null,
			'nodeSteps': null,
			'nodeBg': null,
			'tmpName': null
		},
		'steps':   preload('res://audio/steps.ogg'),
		'coins':   preload('res://audio/coins.ogg'),
		'jump':    preload('res://audio/jump.ogg'),
		'hurt':    preload('res://audio/hurt.ogg'),
		'climb':   preload('res://audio/climb.ogg'),
		'fly':     preload('res://audio/fly.ogg'),
		'soundBg': [
			preload('res://audio/theme0.ogg'),
			preload('res://audio/theme1.ogg'),
			preload('res://audio/theme2.ogg'),
			preload('res://audio/theme3.ogg'),
			preload('res://audio/theme4.ogg'),
			preload('res://audio/theme5.ogg'),
			preload('res://audio/theme6.ogg'),
			preload('res://audio/theme7.ogg')
		]
	},
	
	# COINS ============================================================== COINS
	'coin':   { 'w': 62,  'h': 62  },
	
	# KEYS ================================================================ KEYS
	'key': {
		'w': 72,
		'h': 72,
		'picked': 0,
		'total': 0
	},
	
	# DOOR ================================================================ DOOR
	'door':   { 'w': 180, 'h': 180 },
	
	# LADDER ============================================================ LADDER
	'ladder': { 'w': 140, 'h': 70  },
	
	# PLAYER ============================================================ PLAYER
	'player': {
		'w': 100,    # player logical width
		'h': 140,    # player logical height
		'enterPos': 'bottom',
		# attributes of player stepping up, climb the stairs
		'stairStep':{
			'frames': 5,
			'w': COL_WIDTH * 0.2,
			'h': ROW_HEIGHT
		},
		'anim': {
				# animation - player running right
				'right': { 'x': 0,   'y': 0, 'w': 160, 'h': 160, 'frames': 6, 'fps': 12 },
				# animation - player standing still
				'stand': { 'x': 960, 'y': -4, 'w': 160, 'h': 160, 'frames': 4, 'fps': 4 },
				# animation - player running left
				'left': { 'x': 1600, 'y': 0, 'w': 160, 'h': 160, 'frames': 6, 'fps': 12 },
				# animation - player standing still with back to camera (on ladder but not moving)
				'back': { 'x': 2720, 'y': 0, 'w': 160, 'h': 160, 'frames': 1, 'fps': 1 },
				# animation - player climbing ladder
				'climb': { 'x': 2560, 'y': 0, 'w': 160, 'h': 160, 'frames': 4, 'fps': 8 },
				# animation - player hurt while running left
				'hurtL': { 'x': 3360, 'y': 0, 'w': 160, 'h': 160, 'frames': 1, 'fps': 1 },
				# animation - player hurt while running right
				'hurtR': { 'x': 3200, 'y': 0, 'w': 160, 'h': 160, 'frames': 1, 'fps': 1 }
		}
	},
	
	# MONSTERS ======================================================== MONSTERS
	'monsters': [
		{
			'name': "eye",
			'src': preload('res://img/eye.png'),
			'nx': -0.5,
			'ny': -0.5,
			'w': 1.5 * METER,
			'h': 1.5 * METER,
			'speed': 4 * METER,
			'dir': 'up',
			'vertical': true,
			'horizontal': false,
			'animation': {
				'up':   { 'x': 0, 'y': 0, 'w': 160, 'h': 160, 'frames': 8, 'fps': 16 },
				'down':  { 'x': 0, 'y': 0, 'w': 160, 'h': 160, 'frames': 8, 'fps': 16 }
			}
		},{
			'name': "FLY",
			'src': preload('res://img/fly.png'),
			'nx': -0.5,
			'ny': -0.5,
			'w': 1.5 * METER,
			'h': 1.0 * METER,
			'speed': 8 * METER,
			'dir': 'left',
			'vertical': false,
			'horizontal': true,
			'animation': {
				'left': { 'x': 0, 'y': 7, 'w': 185, 'h': 160, 'frames': 5, 'fps': 10 },
				'right': { 'x': 925, 'y': 7, 'w': 185, 'h': 160, 'frames': 5, 'fps': 10 }
			}
		},{
			'name': "CRAB",
			'src': preload('res://img/crab.png'),
			'nx': -0.5,
			'ny':  0.0,
			'w': 1.5 * METER,
			'h': 1.0 * METER,
			'speed': 4 * METER,
			'dir': 'right',
			'vertical': false,
			'horizontal': true,
			'animation': {
				'left': { 'x': 0, 'y': 1, 'w': 320, 'h': 160, 'frames': 8, 'fps': 16 },
				'right': { 'x': 0, 'y': 1, 'w': 320, 'h': 160, 'frames': 8, 'fps': 16 }
			}
		},{
			'name': "guard",
			'src': preload('res://img/guard.png'),
			'nx': -0.5,
			'ny':  0.0,
			'w': 1.5 * METER,
			'h': 1.0 * METER,
			'speed': 2 * METER,
			'dir': 'left',
			'vertical': false,
			'horizontal': true,
			'animation': {
				'left': { 'x': 0, 'y':  1, 'w': 185, 'h': 160, 'frames': 8, 'fps': 16 },
				'right': { 'x': 1480, 'y':  1, 'w': 185, 'h': 160, 'frames': 8, 'fps': 16 }
			}
		}
	]
}

#---------------------------
# GAME - SETUP/UPDATE/RENDER
#---------------------------
#var levelGenerator = LevelGenerator.new()

func run():
	var thisLevel = getLevel(str(prop.userVars.levelNow)) # загрузка ресурса
	setup(prop.images, thisLevel)
	
	prop.audio.var.nodeBg.stream = prop.audio.soundBg[randomInt(0, prop.audio.soundBg.size() - 1)]
	prop.audio.var.nodeBg.set_volume_db(-25)
	prop.audio.var.nodeBg.play()
	
	renderer.helpLabel.text = 'LEVEL ' + str(prop.userVars.levelNow)
	#renderer.helpLabel.text += ' - ' + langs.list[prop.userVars.lang].collectCoins
	
	resize()

func getNumOfLevels():
	var count = 0
	var dir = Directory.new()
	
	if dir.open('res://levels') == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				count += 1
			file_name = dir.get_next()
		
		dir.list_dir_end()
		return count

func getLevel(name):
	var obj = {
		'name': '',
		'flat': false,
		'color': {},
		'map': []
	}
	var res = load('res://levels/' + name + '.tres')
	
	obj.name  = res.name
	obj.flat  = res.flat
	obj.color = res.color
	
	var map = res.map # получаем карту в текстовом формате
	#var map = levelGenerator.getLevel()
	map = map.replace('\n\n', '') # удаляем двойные переносы строк
	map = map.split('\n') # получаем массив карты
	
	obj.map = map
	
	return obj

func changeLevel():
	var levels = prop.vars.lvsTotal
	
	if(prop.key.picked < prop.key.total && player.y > 100):
		renderer.helpLabel.text = langs.list[prop.userVars.lang].needKeys
		return
	else:
		prop.key.picked = 0
		prop.key.total = 0
	
	# change level number
	if(player.y > 100):
		prop.userVars.levelNow += 1
		prop.player.enterPos = 'bottom'
		prop.userVars.bank += prop.vars.score
	else:
		prop.userVars.levelNow -= 1
		prop.player.enterPos = 'up'
	
	if(prop.userVars.levelNow < 1):
		prop.userVars.levelNow = levels
		return
	elif(prop.userVars.levelNow > levels):
		prop.userVars.levelNow = 1
	
	prop.vars.score = 0
	
	prop.vars.gameStop = true # stop process
	
	# free objects
	VisualServer.free_rid(renderer.ctx)
	renderer.free()
	camera.free()
	tower.free()
	
	for monster in monsters.all:
		monster.free()
		
	monsters.free()
	player.queue_free()
	
	saveGame()
	
	prop.vars.gameStop = false # start process
	run() # start game

func setup(thisImages, thisLevel):
	tower = Tower.new(thisLevel)
	monsters = Monsters.new(thisLevel)
	player = Player.new()
	camera = myCamera.new()
	renderer = Renderer.new(thisImages)

func animate (fps, entity, animation):
	if(!animation):
		animation = entity.animation
	
	if(!entity.animationFrame):
		entity.animationFrame = 0
	
	if(!entity.animationCounter):
		entity.animationCounter = 0
	
	if (entity.animation != animation):
		entity.animation        = animation
		entity.animationFrame   = 0
		entity.animationCounter = 0
	elif (entity.animationCounter == round(fps / animation.fps)):
		entity.animationFrame   = Game.normalize(entity.animationFrame + 1, 0, entity.animation.frames)
		entity.animationCounter = 0
	else:
		entity.animationCounter += 1

func update(dt):
	player.update(dt)
	monsters.update(dt)
	camera.update()

func render(dt):
	renderer.render(dt)

func soundSteps(name, vol):
	if name != prop.audio.var.tmpName:
		prop.audio.var.nodeSteps.stream = prop.audio[name]
		prop.audio.var.nodeSteps.set_volume_db(vol)
		prop.audio.var.nodeSteps.play()
		prop.audio.var.tmpName = name
	else:
		if(!prop.audio.var.nodeSteps.is_playing()):
			prop.audio.var.tmpName = ''

func soundFx(name, vol):
	prop.audio.var.nodeFx.stream = prop.audio[name]
	prop.audio.var.nodeFx.set_volume_db(vol)
	prop.audio.var.nodeFx.play()

#---------------------------
# INPUTS
#---------------------------
var input = {
	'left': false,
	'right': false,
	'up': false,
	'down': false,
	'jump': false,
	'jumpAvailable': true
}

var swipe_tmp_position: = Vector2()
var swipe_start_position: = Vector2()

func _input(event):
	if event is InputEventKey:
		inputAction( str(event.is_pressed()) )
	
	if(event is InputEventScreenTouch):
		if event.pressed:
			if(event.index == 0):
				swipe_start_position = event.position
			else:
				swipeUpdate(swipe_tmp_position, true)
		else:
			if(event.index == 0):
				inputAction('done') # done swipe
	
	if(event is InputEventScreenDrag):
		if(event.index == 0):
			swipe_tmp_position = event.position
			swipeUpdate(event.position)

func swipeUpdate(position: Vector2, jump = false):
	var direction: Vector2 = (position - swipe_start_position).normalized()
	# Swipe angle is too steep
	if abs(direction.x) + abs(direction.y) >= 10: # max_diagonal_slope
		return

	if abs(direction.x) > abs(direction.y):
		inputAction(str(-sign(direction.x)) + ':0', jump)
	else:
		inputAction('0:' +  str(-sign(direction.y)), jump)

func inputAction(event, jump = false):
	if(prop.debug.isEnable):
		prop.debug.input = str(event, ' ', jump)
	
	if (Input.is_action_pressed("left") or event == '1:0'):
		input.left = true
	else:
		input.left = false
		
	if(Input.is_action_pressed("right") or event == '-1:0'):
		input.right = true
	else:
		input.right = false
	
	if(Input.is_action_pressed("up") or event == '0:1'):
		input.up = true
	else:
		input.up = false
	
	if(Input.is_action_pressed("down") or event == '0:-1'):
		input.down = true
	else:
		input.down = false
	
	if(Input.is_action_pressed("jump") or Input.is_action_just_released("jump") or jump):
		if(input.jumpAvailable):
			input.jump = true
		else:
			input.jump = false
		
		if(event == 'True'):
			input.jumpAvailable = false
		elif(event == 'False'):
			input.jumpAvailable = true

#---------------------------
# UTILITY METHODS
#---------------------------
func normalize(n, nMin, nMax):
	while (n < nMin):
		n += (nMax - nMin)
	while (n >= nMax):
		n -= (nMax - nMin)
	
	return n

func normalizeAngle180(angle):
	return normalize(angle, -180, 180)

func normalizeAngle360(angle):
	return normalize(angle, 0, 360)

func normalizex(x): # wrap x-coord around to stay within tower boundary
	return normalize(x, 0, tower.w)

func normalizeColumn(col): # wrap column  around to stay within tower boundary
	return normalize(col, 0, tower.cols)

func x2col(x): # convert x-coord to tower column index
	return floor(normalizex(x) / COL_WIDTH)

func y2row(y): # convert y-coord to tower row index
	return floor(y / ROW_HEIGHT)

func col2x(col): # convert tower column index to x-coord
	return col * COL_WIDTH

func row2y(row): # convert tower row index to y-coord
	return row * ROW_HEIGHT

func x2a(x): # convert x-coord to an angle around the tower
	return 360 * (normalizex(x) / tower.w)

func tx(x, r): # transform x-coord for rendering (and Flat or Round MODE)
	if(Game.tower.flat):
		x = normalizex(x-camera.rx)
		if (x > (Game.tower.w / 2.0)):
			x = - (Game.tower.w - x)
		return x
	else:
		return r * sin((normalizex(x-camera.rx) / tower.w) * 2 * PI)

func ty(y): # transform y-coord for rendering
	return HEIGHT - HORIZON - (y - camera.ry)

func nearColCenter(x,col,limit): # is x-coord "near" the center  of a tower column
	return limit > abs(x - col2x(col + 0.5)) / (COL_WIDTH / 2.0)

func nearRowSurface(y,row): # is y-coord "near" the surface of a tower row
	return y > (row2y(row+1) - ROW_SURFACE)

#---------------------------
# MATH METHODS
#---------------------------
func myLerp(n, dn, dt):
	return n + (dn * dt)

func bound(x, mn, mx):
	return int(max(mn, min(mx, x)))

func between(n, mn, mx):
	return ((n >= mn) && (n <= mx))

func brighten(hex, percent):
	var a = round(255 * percent / 100)
	var r = a + ('0x' + hex.substr(1, 2)).hex_to_int()
	var g = a + ('0x' + hex.substr(3, 2)).hex_to_int()
	var b = a + ('0x' + hex.substr(5, 2)).hex_to_int()
	
	if(r < 255):
		if(r < 1): r = 0
	else:
		r = 255
	
	if(g < 255):
		if(g < 1): g = 0
	else:
		g = 255
	
	if(b < 255):
		if(b < 1): b = 0
	else:
		b = 255
	
	return Color8(r, g, b)

func darken(hex, percent):
	return brighten(hex, -percent)

func random(mn, mx):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randf_range(mn, mx)

func randomInt(mn, mx):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(mn, mx)

func randomChoice(choices):
	return choices[randomInt(0, choices.size() - 1)]

# Animations
func imageTween(imgSrc, startPos, endPos, sizeX, sizeY):
	var time = random(0.5, 1)
	
	var item = TextureRect.new()
	item.texture = imgSrc
	item.expand = true
	item.stretch_mode = 6
	item.rect_size.x = sizeX
	item.rect_size.y = sizeY
	item.rect_position = startPos
	node2d.add_child(item)
	
	var tween = Tween.new()
	tween.interpolate_property(item, 'rect_position', startPos, endPos, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(item, "modulate:a", 0.8, 0.0, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	node2d.add_child(tween)
	tween.start()
	
	yield(tween, 'tween_completed')
	tween.queue_free()
	item.queue_free()

func resize():
	#var size = get_viewport_rect().size
	var size = get_viewport().get_visible_rect().size
	viewPort = [size[0], size[1]]
	viewCenter = [size[0] / 2, size[1] / 2]
	offset = [(size[0] - WIDTH) / 2, (size[1] - HEIGHT) / 2]
	
	if(renderer):
		gameBox.rect_size.x = size[0]
		gameBox.rect_size.y = HEIGHT
		
		renderer.UI.rect_size.x = size[0]
		renderer.UI.rect_size.y = size[1]
		renderer.back.rect_size.x = size[0] + WIDTH
		renderer.back.rect_size.y = size[1] + HEIGHT
		renderer.ground.rect_size.x = size[0] + renderer.groundSpeed
		
		renderer.keysPicked.rect_size.x = prop.key.picked * 124
		renderer.keysPicked.rect_position.x = viewPort[0] - prop.key.picked * 124 / 2 - 40
		renderer.keysTotal.rect_size.x = prop.key.total * 124
		renderer.keysTotal.rect_position.x = viewPort[0] - prop.key.total * 124 / 2 - 40

var userData = 'user://userData.json'

func saveGame():
	var file = File.new()
	file.open(userData, File.WRITE)
	file.store_line(to_json(prop.userVars))
	file.close()
	print('SAVE GAME')
	
func loadGame():
	var file = File.new()
	if not file.file_exists(userData):
		print('No saved file')
		return # Error! We don't have a save to load.
	
	file.open(userData, File.READ)
	prop.userVars = parse_json(file.get_line())
	file.close()
	print('LOAD GAME')
