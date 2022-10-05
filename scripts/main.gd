extends Node2D

var step = 1.0 / Game.FPS

func _ready():
	Game.tree = get_tree()
	Game.tree.set_auto_accept_quit(false)
	
	var viewPort = Game.tree.get_root()
	viewPort.connect('size_changed', Game, 'resize')
	
	Game.prop.audio.var.nodeFx = self.get_node('soundFx')
	Game.prop.audio.var.nodeSteps = self.get_node('soundSteps')
	Game.prop.audio.var.nodeBg = self.get_node('soundBg')
	
	Game.gameBox = self.get_node('gameBox')
	Game.node2d  = Game.gameBox.get_node('Node2D')
	
	Game.loadGame()
	
	if(Game.prop.debug.isEnable):
		Game.prop.userVars.levelNow = Game.prop.debug.level
	
	Game.run()

func _process(dt):
	if(Game.prop.debug.isEnable):
		var info = 'FPS: ' + str(Engine.get_frames_per_second()) + '\n'
		info += 'DT: ' + str(dt) + '\n'
		info += 'DRAW_CALLS: ' + str(Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)) + '\n'
		info += 'NODE_COUNT: ' + str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) + '\n'
		info += 'TIME_PROCESS: ' + str(Performance.get_monitor(Performance.TIME_PROCESS) * 1000) + '\n'
		info += 'OBJECT_COUNT: ' + str(Performance.get_monitor(Performance.OBJECT_COUNT)) + '\n'
		info += 'LEVELS TOTAL: ' + str(Game.prop.vars.lvsTotal) + '\n'
		info += 'LEVEL NOW: ' + str(Game.prop.userVars.levelNow) + '\n'
		info += 'INPUT: ' + Game.prop.debug.input + '\n'
		
		Game.renderer.debugLabel.text = info
	
	if(!Game.prop.vars.gameStop):
		while(dt > step):
			dt = dt - step
			Game.update(step)
		Game.render(dt)

func _notification(type):
	if (type == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		Game.saveGame()
		print('QUIT GAME')
		# do whatever you want here
		Game.tree.quit()


