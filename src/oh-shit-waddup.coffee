
images =
	for n in [0..4]
		img = new Image
		img.src = "images/frames/dat-boi-#{n}.png"
		img

ball_image = new Image
ball_image.src = "images/ball.png"

position = 0
velocity = 0

balls = []

window.onclick = ->
	starting_hand_right = false
	setInterval ->
		balls.push {
			x: 0
			y: 0
			vx: 0
			vy: 0
			next_hand_right: starting_hand_right
			t: 0
		}
		starting_hand_right = not starting_hand_right
	, 350

y_at = (ground_x)->
	canvas.height * 3/4 +
	100 * sin(position / 1500 - ground_x / 50) -
	200 * sin((position / 1500 - ground_x / 50) / 3) -
	# 200 * sin(ground_x / 67) -
	ground_x * 2

x_at = (ground_x)->
	ground_x * 4

delta_at = (ground_x)->
	y_at(ground_x+0.1) - y_at(ground_x-0.1)

# get_unicycle_ball_stuck_x = (ground_x, left)->
# 	rot = delta_at(-10) / 3
# 	x_at(0) + sin(rot) * 185
# 
# get_unicycle_ball_stuck_y = (ground_x, left)->
# 	rot = delta_at(-10) / 3
# 	y_at(0) - cos(rot) * 185

# NOTE: frog's right hand, not "the hand on the right"
get_frog_hand_x = (ground_x, right)->
	rot = delta_at(ground_x - 10) / 3
	hand_x = if right then -120 else 28
	x_at(ground_x) + sin(rot) * 285 + cos(rot) * hand_x

get_frog_hand_y = (ground_x, right)->
	rot = delta_at(ground_x - 10) / 3
	hand_x = if right then -120 else 28
	y_at(ground_x) - cos(rot) * 285 + sin(rot) * hand_x

animate ->
	velocity -= delta_at(0)
	velocity *= 0.995
	position += velocity
	
	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	
	ctx.save()
	ctx.translate(canvas.width / 2, 0)
	
	ctx.beginPath()
	for ground_x in [-500..500]
		ctx.lineTo(x_at(ground_x), y_at(ground_x))
	ctx.lineWidth = 150
	ctx.strokeStyle = "hsl(#{sin(Date.now() / 10000) * 360 + 20}, 100%, 90%)"
	ctx.stroke()
	ctx.strokeStyle = "white"
	ctx.lineWidth = 10
	ctx.stroke()
	
	frame_index = position / 1000 * 3 + Date.now() / 1000
	frame = images[~~(frame_index %% images.length)]
	
	ctx.save()
	ctx.translate x_at(0), y_at(0)
	ctx.rotate delta_at(-10) / 3
	ctx.drawImage frame, -185, -390
	ctx.restore()
	
	for ball in balls
		x_to = get_frog_hand_x(0, ball.next_hand_right)
		y_to = get_frog_hand_y(0, ball.next_hand_right)
		dx = x_to - ball.x
		dy = y_to - ball.y
		ball.t += 0.01
		ball.x = (x_to - ball.x) * 1#min(1, ball.t)
		ball.y = (y_to - ball.y) * 1#min(1, ball.t) #- sin(ball.t) * 150
		ctx.save()
		ctx.translate(ball.x, ball.y)
		ctx.drawImage(ball_image, -ball_image.width/2, -ball_image.height/2)
		ctx.restore()
	
	ctx.restore()
