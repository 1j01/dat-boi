
position = 0

class Unifrog
	
	frames =
		for n in [0..4]
			img = new Image
			img.src = "images/frames/dat-boi-#{n}.png"
			img
	
	constructor: ->
		@velocity = 0
	
	getHandX: (ground_x, right)->
		rot = delta_at(ground_x - 10) / 3
		hand_x = if right then -120 else 40
		ground_x + sin(rot) * 285 + cos(rot) * hand_x
	
	getHandY: (ground_x, right)->
		rot = delta_at(ground_x - 10) / 3
		hand_x = if right then -120 else 40
		y_at(ground_x) - cos(rot) * 285 + sin(rot) * hand_x
	
	step: ->
		@velocity -= delta_at(0)
		@velocity *= 0.995
		position += @velocity
	
	draw: ->
		frame_index = position / 1000 * 3 + Date.now() / 1000
		frame = frames[~~(frame_index %% frames.length)]
		
		ctx.save()
		ctx.translate 0, y_at(0)
		ctx.rotate delta_at(-10) / 3
		ctx.drawImage frame, -185, -390
		ctx.restore()


balls = []

gravity = 0.5

class Ball
	
	ball_image = new Image
	ball_image.src = "images/ball.png"

	@save_properties = ["x", "y", "vx", "vy", "next_hand_right", "height_reached_after_bounce"]

	constructor: (@x, @y, @frog)->
		@vx = 0
		@vy = 0
		@next_hand_right = starting_hand_right
		@height_reached_after_bounce = -Infinity
	
	throwTo: (x_to, y_to, parabola_height)->
		dx = x_to - @x
		dy = y_to - @y
		t = (sqrt(2) * sqrt(parabola_height)) / sqrt(gravity) * 2
		@vy = 1 - (1/2 * gravity * t ** 2 - dy) / t
		@vx = dx / t
	
	throwToNextHand: ->
		hand_x = @frog.getHandX(0, @next_hand_right)
		hand_y = @frog.getHandY(0, @next_hand_right)
		parabola_height = if @next_hand_right then 300 else 200
		@throwTo(hand_x, hand_y, parabola_height)
	
	step: ->
		@x += @vx
		@y += @vy
		@vy += gravity
		
		hand_x = @frog.getHandX(0, @next_hand_right)
		hand_y = @frog.getHandY(0, @next_hand_right)
		@height_reached_after_bounce = min(@height_reached_after_bounce, @y)
		
		if (
			(@height_reached_after_bounce < hand_y - 30) and
			(hand_x - 30 < @x < hand_x + 30) and
			(hand_y < @y < hand_y + 50)
		)
			@next_hand_right = not @next_hand_right
			@height_reached_after_bounce = @y
			@throwToNextHand()
		
		if @y > y_at(@x)
			@vy = -0.9 * abs(@vy)
			@vx += delta_at(@x)
	
	draw: ->
		ctx.save()
		ctx.translate(@x, @y)
		ctx.drawImage(ball_image, -ball_image.width/2, -ball_image.height/2)
		ctx.restore()

y_at = (ground_x)->
	ground_x /= 4
	canvas.height * 3/4 +
	100 * sin(position / 1500 - ground_x / 50) -
	200 * sin((position / 1500 - ground_x / 50) / 3) -
	# 200 * sin(ground_x / 67) -
	ground_x * 2

delta_at = (ground_x)->
	y_at(ground_x+0.4) - y_at(ground_x-0.4)

# get_unicycle_ball_stuck_x = (ground_x, left)->
# 	rot = delta_at(-10) / 3
# 	sin(rot) * 185
# 
# get_unicycle_ball_stuck_y = (ground_x, left)->
# 	rot = delta_at(-10) / 3
# 	y_at(0) - cos(rot) * 185

datBoi = new Unifrog

starting_hand_right = false
window.onclick = (e)->
	# simplify the terrain to make juggling easier (TODO: remove)
	y_at = (ground_x)->
		canvas.height * 3/4
	
	ball = new Ball(e.clientX - canvas.width/2, e.clientY, datBoi)
	balls.push ball
	ball.throwToNextHand()
	# starting_hand_right = not starting_hand_right

animate ->
	
	datBoi.step()
	ball.step() for ball in balls
	
	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	
	ctx.save()
	ctx.translate(canvas.width / 2, 0)
	
	ctx.beginPath()
	ctx.lineWidth = 150
	bound = canvas.width/2 + ctx.lineWidth
	for ground_x in [-bound..bound] by 5
		ctx.lineTo(ground_x, y_at(ground_x))
	ctx.strokeStyle = "hsl(#{sin(Date.now() / 10000) * 360 + 20}, 100%, 90%)"
	ctx.stroke()
	ctx.strokeStyle = "white"
	ctx.lineWidth = 10
	ctx.stroke()
	
	datBoi.draw()
	ball.draw() for ball in balls
	old_position = position
	old_velocity = datBoi.velocity
	ball_save_states = balls.map (ball)->
		properties = Object.fromEntries(Ball.save_properties.map (key)->
			[key, ball[key]]
		)
		{ ball, properties }
	ctx.globalAlpha = 0.1
	for [0..40]
		for ball in balls
			ball.step()
			ball.draw()
		datBoi.step()
	ctx.globalAlpha = 1
	for { ball, properties } in ball_save_states
		for key in Ball.save_properties
			ball[key] = properties[key]
	position = old_position
	datBoi.velocity = old_velocity
	
	ctx.restore()
