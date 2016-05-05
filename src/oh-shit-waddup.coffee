
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

y_at = null

starting_hand_right = false
window.onclick = ->
# setInterval ->
	balls.push {
		x: 0
		y: 0
		vx: 0
		vy: 0
		next_hand_right: starting_hand_right
		height_reached_after_bounce: -Infinity
		t: 0
	}
	# starting_hand_right = not starting_hand_right
	y_at = (ground_x)->
		canvas.height * 3/4
# , 500

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

gravity = 0.5

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
		# x_from = get_frog_hand_x(0, not ball.next_hand_right)
		# y_from = get_frog_hand_y(0, not ball.next_hand_right)
		# x_to = get_frog_hand_x(0, ball.next_hand_right)
		# y_to = get_frog_hand_y(0, ball.next_hand_right)
		# ball.t += 0.01
		# arc_height = if ball.next_hand_right then 300 else 150
		# if balls.length > 20
		# 	ball.x = x_from + (x_to - x_from) * min(1, ball.t) - sin((ball.t) * TAU/2) * velocity * sin(ball.t * velocity / 15)
		# 	ball.y = y_from + (y_to - y_from) * min(1, ball.t) - cos((ball.t - 1/2) * TAU/2) * arc_height
		# else
		# 	ball.x = x_from + (x_to - x_from) * min(1, ball.t)
		# 	ball.y = y_from + (y_to - y_from) * min(1, ball.t) - cos((ball.t - 1/2) * TAU/2) * arc_height
		# if ball.t >= 1
		# 	ball.next_hand_right = not ball.next_hand_right
		# 	ball.t = 0
		ball.x += ball.vx
		ball.y += ball.vy
		ball.vy += gravity
		# dx = get_frog_hand_x(0, ball.next_hand_right) - ball.x
		# ball.vx += dx / 1000
		# ball.vx *= 0.99
		hand_x = get_frog_hand_x(0, ball.next_hand_right)
		hand_y = get_frog_hand_y(0, ball.next_hand_right)
		ball.height_reached_after_bounce = min(ball.height_reached_after_bounce, ball.y)
		if (
			(ball.height_reached_after_bounce < hand_y - 30) and
			(hand_x - 30 < ball.x < hand_x + 30) and
			(hand_y < ball.y < hand_y + 50)
		)
			ball.next_hand_right = not ball.next_hand_right
			ball.height_reached_after_bounce = ball.y
			# t = 50
			# dx = get_frog_hand_x(-0.001 * velocity, ball.next_hand_right) - ball.x
			dx = get_frog_hand_x(0, ball.next_hand_right) - ball.x
			dy = get_frog_hand_y(0, ball.next_hand_right) - ball.y
			# dx = get_frog_hand_x(0, ball.next_hand_right) - ball.x
			
			
			# ball.vx = dx / t
			# ball.vy = -15
			# ball.vy = ball.vy * sin(theta) - gravity * t
			# ball.vx = cos(theta)
			# ball.vy * tan(theta) - gravity * t
			# y 
			# speed = sqrt(2)#5
			# # theta = atan2(dy, dx / speed)
			# theta = TAU / 8 #acos(dx)
			# ball.vy = speed * sin(theta) - gravity * t
			# ball.vx = speed * cos(theta)
			# dist = sqrt(dx * dx + dy * dy)
			# dx = ball.vy * t + 1/2 * (gravity * (t ** 2))
			# d = ball.vy * t + 1/2 * (gravity * (t ** 2))
			# d / t = ball.vy + (1 / 2 * (gravity * (t ** 2)) / t)
			# d / t - ball.vy = (1 / 2 * (gravity * (t ** 2)) / t)
			# - ball.vy = (1 / 2 * (gravity * (t ** 2)) / t) - d / t
			# ball.vy = dx / t - (1 / 2 * (gravity * (t ** 2)) / t)
			# ball.vy = dx / t - (1 / 2 * (gravity * (t ** 2)) / t)
			# # ball.vx = ball.vy
			# ball.vx = dx / t
			# # d = ball.vy * t + 1/2 * (gravity * (t ** 2))
			# height = 200
			# ttt = height / 2
			# height = 1/2 * gravity * t ** 2
			# ttt = 28.2843 #sqrt(gravity * 2)
			# height = 400
			# ttt = (sqrt(2) * sqrt(height)) / sqrt(gravity)
			# # ball.vy = gravity / ttt
			# # ball.vy = gravity * ttt
			# # ball.vx = dx / (ttt * 2)
			# ball.vy = -gravity * ttt
			# ball.vx = dx / (ttt * 2)
			# # theta = atan2(ball.vy, ball.vx)
			# 
			
			# ball.vy = 
			# ball.vx = dx / (ttt * 2)
			
			# dy = ball.vy + 1/2 * g * t ** 2
			# dx = ball.vx + 1/2 * 0 * t ** 2 = ball.vx ?
			# dy - ball.vy = 1/2 * g * t ** 2
			# dx - ball.vx = 0
			
			# ball.vy = 1 - (1/2 * gravity * ttt ** 2 - dy) / ttt
			# ball.vx = dx / ttt
			
			height = if ball.next_hand_right then 300 else 200
			t = (sqrt(2) * sqrt(height)) / sqrt(gravity) * 2
			ball.vy = 1 - (1/2 * gravity * t ** 2 - dy) / t
			ball.vx = dx / t

		# if ball.y > y_at(ball.x)
		# if ball.y > y_at(x_at(ball.x))
		if ball.y > y_at(ball.x / 4)
			ball.vy = -0.9 * abs(ball.vy)
			ball.vx += delta_at(ball.x / 4)
		
		ctx.save()
		ctx.translate(ball.x, ball.y)
		ctx.drawImage(ball_image, -ball_image.width/2, -ball_image.height/2)
		ctx.restore()
	
	ctx.restore()
