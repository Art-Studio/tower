class_name Player extends Node

var prop = Game.prop.player

var x         # current x position
var y         # current y position
var w         # width
var h         # height
var dx        # current horizontal speed
var dy        # current vertical speed
var rx
var ry
var ddx       # accumulated force x
var ddy       # accumulated force y
var gravity   # gravitational force
var maxdx     # maximum horizontal speed
var maxdy     # maximum vertical speed
var climbdy   # fixed climbing speed
var impulse   # jump impulse force
var accel     # acceleration to apply when player runs
var friction  # friction to apply when player runs
var collision # collision points...

var falling
var fallingJump
var climbing
var stepping
var stepCount
var hurting
var hurtLeft

var animation
var animationFrame = 0
var animationCounter

var rowNow
var levelEnd

func _init():
	x         = Game.col2x(0.5)
	y         = Game.row2y(0)
	w         = prop.w
	h         = prop.h
	dx        = 0
	dy        = 0
	gravity   = 200 * Game.GRAVITY
	maxdx     = Game.METER * Game.MAXDX
	maxdy     = Game.METER * Game.MAXDY
	climbdy   = Game.METER * Game.CLIMBDY
	impulse   = Game.METER * Game.IMPULSE
	accel     = maxdx / Game.ACCEL
	friction  = maxdx / Game.FRICTION
	collision = createCollisionPoints()
	animation = prop.anim.stand
	rowNow    = 0
	
	if(Game.prop.player.enterPos == 'up'):
		y = Game.row2y(Game.tower.rows - 15)

func createCollisionPoints():
	return {
		'topLeft':     { 'x': -w/4, 'y': h-2 },
		'topRight':    { 'x':  w/4, 'y': h-2 },
		'middleLeft':  { 'x': -w/2, 'y': h/2 },
		'middleRight': { 'x':  w/2, 'y': h/2 },
		'bottomLeft':  { 'x': -w/4, 'y':  0  },
		'bottomRight': { 'x':  w/4, 'y':  0  },
		'underLeft':   { 'x': -w/4, 'y': -1  },
		'underRight':  { 'x':  w/4, 'y': -1  },
		'ladderUp':    { 'x':    0, 'y': h/2 },
		'ladderDown':  { 'x':    0, 'y': -1  }
	}

func update(dt):
	animate()
	
	var wasleft  = dx  < 0
	var wasright = dx  > 0
	var thisFalling  = falling
	var thisFriction
	var thisAccel
	
	if (falling):
		thisFriction = friction * 0.5
	else:
		thisFriction = friction * 1
		
	if (falling or climbing):
		thisAccel = accel * 0.5
	else:
		thisAccel = accel * 1
	
	if (stepping):
		return stepUp()
	
	if (hurting):
		return hurt(dt)
	
	ddx = 0
	
	if (thisFalling):
		ddy = -gravity
	else:
		ddy = 0
	
	if (climbing):
		ddy = 0
		if (Game.input.up):
			dy =  climbdy
		elif (Game.input.down):
			dy = -climbdy
		else:
			dy = 0
	
	if (Game.input.left):
		ddx = ddx - thisAccel
	elif (wasleft):
		ddx = ddx + thisFriction
	
	if (Game.input.right):
		ddx = ddx + thisAccel
	elif (wasright):
		ddx = ddx - thisFriction
	
	# jumping
	if (Game.input.jump && (!thisFalling || fallingJump)):
		performJump()
	
	# climbing
	if (climbing && (Game.input.up || Game.input.down)):
		climbNow()
	
	# running
	if ((Game.input.left || Game.input.right) && !falling && !stepping && !hurting):
		runNow()
	
	# level End
	if(rowNow >= Game.tower.rows):
		isLevelEnd()
	
	updatePosition(dt)
	
	while (checkCollision()):
		# iterate until no more collisions
		pass
	
	# clamp dx at zero to prevent friction from making us jiggle side to side
	if ((wasleft  && (dx > 0)) or (wasright && (dx < 0))):
		dx = 0
	
	#if falling, track short period of time during which we're falling but can still jump
	if (falling && (fallingJump > 0)):
		fallingJump = fallingJump - 1

func updatePosition(dt):
	x  = Game.normalizex(x  + (dt * dx))
	
	y  = y + (dt * dy)
	if(y < 0): dy = 0
	
	dx = Game.bound(dx + (dt * ddx), -maxdx, maxdx)
	dy = Game.bound(dy + (dt * ddy), -maxdy, maxdy)
	rowNow = y / Game.ROW_HEIGHT

func hurt(dt):
	if(typeof(hurting) == 1):
		if (hurting == true):
			dx = -dx / 2
			ddx = 0
			ddy = impulse / 2
			hurting = Game.FPS
			hurtLeft = Game.input.left
	else:
		ddy = -gravity
		hurting = hurting - 1
	
	updatePosition(dt)
	if (y <= 0):
		hurting = false
		falling = false
		y = 0
		dy = 0

func animate():
	if (hurting):
		if (hurtLeft):
			Game.animate(Game.FPS, self, prop.anim.hurtL)
		else:
			Game.animate(Game.FPS, self, prop.anim.hurtR)
		
	elif (climbing && (Game.input.up || Game.input.down || Game.input.left || Game.input.right)):
		Game.animate(Game.FPS, self, prop.anim.climb)
	elif (climbing):
		Game.animate(Game.FPS, self, prop.anim.back)
	elif (Game.input.left  || (stepping == Game.DIR.LEFT)):
		Game.animate(Game.FPS, self, prop.anim.left)
	elif (Game.input.right || (stepping == Game.DIR.RIGHT)):
		Game.animate(Game.FPS, self, prop.anim.right)
	else:
		Game.animate(Game.FPS, self, prop.anim.stand)

func checkCollision():
	var thisFalling = falling
	var fallingUp   = falling && (dy > 0)
	var fallingDown = falling && (dy <= 0)
	var thisClimbing = climbing
	#var climbingUp   = climbing && Game.input.up
	var climbingDown = climbing && Game.input.down
	var runningLeft  = dx < 0
	var runningRight = dx > 0
	var tl = collision.topLeft
	var tr = collision.topRight
	var ml = collision.middleLeft
	var mr = collision.middleRight
	var bl = collision.bottomLeft
	var br = collision.bottomRight
	var ul = collision.underLeft
	var ur = collision.underRight
	var ld = collision.ladderDown
	var lu = collision.ladderUp
	
	updateCollisionPoint(tl)
	updateCollisionPoint(tr)
	updateCollisionPoint(ml)
	updateCollisionPoint(mr)
	updateCollisionPoint(bl)
	updateCollisionPoint(br)
	updateCollisionPoint(ul)
	updateCollisionPoint(ur)
	updateCollisionPoint(ld)
	updateCollisionPoint(lu)
	
	# Did we collide with a coin
	if (tl.coin): return collectCoin(tl)
	elif (tr.coin): return collectCoin(tr)
	elif (ml.coin): return collectCoin(ml)
	elif (mr.coin): return collectCoin(mr)
	elif (bl.coin): return collectCoin(bl)
	elif (br.coin): return collectCoin(br)
	
	# Did we collide with a key
	if (tl.key): return collectKey(tl)
	elif (tr.key): return collectKey(tr)
	elif (ml.key): return collectKey(ml)
	elif (mr.key): return collectKey(mr)
	elif (bl.key): return collectKey(bl)
	elif (br.key): return collectKey(br)
	
	# Did we collide with a door
	if ((bl.door or br.door) && Game.input.up):
		return enterDoor()
	
	# Did we land on the top of a platform or a ladder
	if (fallingDown && bl.blocked && !ml.blocked && !tl.blocked && Game.nearRowSurface(y + bl.y, bl.row)):
		return collideDown(bl)
	
	if (fallingDown && br.blocked && !mr.blocked && !tr.blocked && Game.nearRowSurface(y + br.y, br.row)):
		return collideDown(br)
	
	if (fallingDown && ld.ladder && !lu.ladder):
		return collideDown(ld)
	
	# Did we hit our heads on a platform above us
	if (fallingUp && tl.blocked && !ml.blocked && !bl.blocked):
		return collideUp(tl)
	
	if (fallingUp && tr.blocked && !mr.blocked && !br.blocked):
		return collideUp(tr)
	
	# Did we reach the bottom of a ladder
	if (climbingDown && ld.blocked):
		return stopClimbing(ld)
	
	# While running right, did we run into a platform, or a step up
	if (runningRight && tr.blocked && !tl.blocked):
		return collide(tr, false)
	
	if (runningRight && mr.blocked && !ml.blocked):
		return collide(mr, false)
	
	if (runningRight && br.blocked && !bl.blocked):
		if (thisFalling):
			return collide(br, false)
		else:
			return startSteppingUp(Game.DIR.RIGHT)
	
	# While running left, did we run into a platform, or a step up
	if (runningLeft && tl.blocked && !tr.blocked):
		return collide(tl, true)
	
	if (runningLeft && ml.blocked && !mr.blocked):
		return collide(ml, true)
	
	if (runningLeft && bl.blocked && !br.blocked):
		if (thisFalling):
			return collide(bl, true)
		else:
			return startSteppingUp(Game.DIR.LEFT)
	
	# Did we just start climbing, falling, or fall off a ladder
	var onLadder = (lu.ladder || ld.ladder) && Game.nearColCenter(x, lu.col, Game.LADDER_EDGE)
	
	# check to see if we are now falling or climbing
	if (!thisClimbing && onLadder && ((lu.ladder && Game.input.up) || (ld.ladder && Game.input.down))):
		return startClimbing()
	elif (!thisClimbing && !thisFalling && !ul.blocked && !ur.blocked && !onLadder):
		return startFalling(true)
	
	# check to see if we have fallen off a ladder
	if (thisClimbing && !onLadder):
		return stopClimbing(false)
	
	# Did we just hit a monster
	if (!hurting && (tl.monster || tr.monster || ml.monster || mr.monster || bl.monster || br.monster || lu.monster || ld.monster)):
		return hitMonster()
	
	return false; # done, we didn't collide with anything

func updateCollisionPoint(point):
	point.row  = Game.y2row(y + point.y)
	point.col  = Game.x2col(x + point.x)
	point.cell = Game.tower.getCell(point.row, point.col)
	point.blocked  = point.cell.platform
	point.platform = point.cell.platform
	point.ladder   = point.cell.ladder
	point.monster  = false
	point.coin     = false
	point.key      = false
	point.door     = false
	
	if (point.cell.monster):
		var monster = point.cell.monster
		if (Game.between(x + point.x, monster.x + monster.nx, monster.x + monster.nx + monster.w)
		&& Game.between(y + point.y, monster.y + monster.ny, monster.y + monster.ny + monster.h)):
			point.monster  = point.cell.monster
	
	if (point.cell.coin && str(point.cell.coin) != 'picked'):
		# center point of column +/- COIN.W/2
		if (Game.between(x + point.x, Game.col2x(point.col+0.5) - Game.prop.coin.w/2, Game.col2x(point.col+0.5) + Game.prop.coin.w/2)
		&& Game.between(y + point.y, Game.row2y(point.row), Game.row2y(point.row+1))):
			point.coin = true
	
	if (point.cell.key):
		# center point of column +/- KEY.W/2
		if (Game.between(x + point.x, Game.col2x(point.col+0.5) - Game.prop.key.w/2, Game.col2x(point.col+0.5) + Game.prop.key.w/2)
		&& Game.between(y + point.y, Game.row2y(point.row), Game.row2y(point.row+1))):
			point.key = true
	
	if (point.cell.door):
		# center point of column +/- DOOR.W/2
		if (Game.between(x + point.x, Game.col2x(point.col+0.5) - Game.prop.door.w/2, Game.col2x(point.col+0.5) + Game.prop.door.w/2)
		&& Game.between(y + point.y, Game.row2y(point.row), Game.row2y(point.row+1))):
			point.door = true

# level End
func isLevelEnd():
	if(!levelEnd):
		levelEnd = true
		print ('levelEnd')

# running
func runNow ():
	Game.soundSteps('steps', -15)

# climbing
func climbNow ():
	Game.soundSteps('climb', -10)

func enterDoor():
	Game.changeLevel()

# collided with a coin
func collectCoin(point):
	point.cell.coin = 'picked'
	#Game.prop.vars.score += 0.1
	Game.prop.vars.score += 1
	
	if(Game.prop.vars.score < 10):
		Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].enoughCoins
	else:
		if(Game.prop.key.picked == Game.prop.key.total):
			Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].doorOpen
		else:
			Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].findKey
	
	Game.soundFx('coins', 0)
	coinAnim(point)

func lostCoins():
	if (Game.prop.vars.score > 0):
		Game.prop.vars.score = 0
		for i in 10:
			Game.soundFx('coins', -10)
			coinAnim({'x': Game.randomInt(-1, 1)})
		
		Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].lostCoins
		
		# restore coins
		for row in Game.tower.map.size():
			for cell in Game.tower.map[row]:
				if(str(cell.coin) == 'picked'): cell.coin = true

func coinAnim(point):
	var dir = 1
	if(point.x < 0): dir = -1
	
	var posX = Game.viewPort[0] / 2 - point.x * dir
	var posY = Game.HEIGHT - Game.HORIZON - Game.prop.coin.h
	
	var startPos = Vector2(posX, posY)
	var endPos = Vector2(posX - Game.randomInt(100, 200) * dir, posY - Game.randomInt(200, 400))
	
	Game.imageTween(Game.prop.images.coins.src, startPos, endPos, Game.prop.coin.w, Game.prop.coin.h)

# collided with a key
func collectKey(point):
	if(Game.prop.vars.score >= 10):
		Game.prop.vars.score -= 10
	else:
		Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].needCoins
		return
		
	point.cell.key = false
	Game.prop.key.picked += 1
	Game.renderer.keysPicked.rect_size.x = Game.prop.key.picked * 124
	Game.renderer.keysPicked.rect_position.x = Game.viewPort[0] - Game.prop.key.picked * 124 / 2 - 40
	
	if(Game.prop.key.picked < Game.prop.key.total):
		Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].needKeys
	else:
		Game.renderer.helpLabel.text = Game.langs.list[Game.prop.userVars.lang].doorOpen
	
	Game.soundFx('coins', 0)
	keyAnim(point)

func keyAnim(point):
	var dir = 1
	if(point.x < 0): dir = -1
	
	var posX = Game.viewPort[0] / 2 - point.x * dir
	var posY = Game.HEIGHT - Game.HORIZON - Game.prop.key.h
	
	var startPos = Vector2(posX, posY)
	var endPos = Vector2(posX - 200 * dir, posY - 400)
	
	Game.imageTween(Game.prop.images.key.src, startPos, endPos, Game.prop.key.w, Game.prop.key.h)

# detected nothing below us
func startFalling (allowFallingJump):
	falling = true
	
	if(allowFallingJump):
		fallingJump = Game.FALLING_JUMP
	else:
		fallingJump = 0

# collided with a platform while running
func collide (point, left):
	if(left):
		x  = Game.normalizex(Game.col2x(point.col + 1) - point.x)
	else:
		x  = Game.normalizex(Game.col2x(point.col + 0) - point.x)
	dx = 0
	return true

# collided with a platform while jumping
func collideUp (point):
	y = Game.row2y(point.row) - point.y
	dy = 0
	return true

# collided with a platform while falling
func collideDown (point):
	y = Game.row2y(point.row + 1)
	dy = 0
	falling = false
	return true

func performJump ():
	if (climbing):
		stopClimbing(false)
	
	dy  = 0
	ddy = impulse; # an instant big force impulse
	startFalling(false)
	Game.input.jump = false
	Game.soundFx('jump', -10)

func startSteppingUp (dir):
	stepping  = dir
	stepCount = prop.stairStep.frames
	return false # NOT considered a collision

# collided with step while running
func stepUp():
	var left = (stepping == Game.DIR.LEFT)
	var thisDx   = prop.stairStep.w / prop.stairStep.frames
	var thisDy   = prop.stairStep.h / prop.stairStep.frames
	
	dx  = 0
	dy  = 0
	
	if(left):
		x = Game.normalizex(x + -thisDx)
	else:
		x = Game.normalizex(x + thisDx)
	
	if (stepCount <= 0):
		stepping = Game.DIR.NONE
		y = y + 1
	else:
		y = y + thisDy
		stepCount -= 1

# collided with a ladder while user input up or down
func startClimbing ():
	climbing = true
	dx = 0

# reached bottom of ladder, or fell off the side
func stopClimbing (point):
	climbing = false
	dy = 0
	
	if(point):
		y = Game.row2y(point.row + 1)
	
	return true

# collided with a monster
func hitMonster ():
	hurting = true
	Game.soundFx('hurt', 0)
	lostCoins()
	return true
