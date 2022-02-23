
audio_ctx = new AudioContext()
sound_file_paths = {
	bounce: "audio/sfx/boing.mp3"
	quack: "audio/sfx/duck-quack-#.ogg"
	chirp: "audio/sfx/duckling-chirp-#.ogg"
	flame: "audio/sfx/flame-#.mp3"
	chainsaw_rev: "audio/sfx/chainsaw-rev-#.ogg"
	chainsaw_start: "audio/sfx/chainsaw-start.ogg"
	chainsaw_engine_loop: "audio/sfx/chainsaw-engine-loop.ogg"
	table_saw_start: "audio/sfx/table-saw-start.mp3"
	table_saw_loop: "audio/sfx/table-saw-loop.mp3"
	whoosh: "audio/sfx/whoosh.ogg"
}
sound_variation_counts = {
	quack: 12
	chirp: 4
	flame: 5
	chainsaw_rev: 5
}

music_tracks = [
	"audio/music/carnival_of_strangeness.mp3"
	"audio/music/RollUp.ogg"
	"audio/music/taking_you_to_the_circus_mastered.mp3"
]

memoize = (fn) =>
	cache = {}
	(...args) =>
		if cache[args]
			cache[args]
		else
			cache[args] = fn(...args)

load_sound = memoize (path) =>
	response = await fetch(path)
	array_buffer = await response.arrayBuffer()
	audio_buffer = await audio_ctx.decodeAudioData(array_buffer)

# preload sounds
for name, path of sound_file_paths
	if sound_variation_counts[name]
		for i in [1...sound_variation_counts[name]]
			load_sound(path.replace("#", i))
	else
		load_sound(path)

play_sound = (name, { playback_rate = 1, playback_rate_variation = 0, volume = 1, looping = false, time = 0 } = {}) =>
	if sound_file_paths[name]
		path = sound_file_paths[name]
		if sound_variation_counts[name]
			path = path.replace("#", Math.floor(Math.random() * sound_variation_counts[name]) + 1)
		gain = audio_ctx.createGain()
		gain.gain.value = volume
		gain.connect(audio_ctx.destination)
		source = audio_ctx.createBufferSource()
		source.buffer = await load_sound(path)
		source.loop = looping
		source.connect(gain)
		source.start(time)
		source.playbackRate.value = playback_rate + (Math.random() * playback_rate_variation)
		return new Promise((resolve) => source.onended = resolve)
	else
		# console.warn("no sound named", name)
		return Promise.reject(new Error("no sound named " + name))

# Using <audio> for music, so that system media controls can be used (on iOS)
music = new Audio()
music.src = music_tracks[Math.floor(Math.random() * music_tracks.length)]
music.loop = true
# music.play()
addEventListener("pointerdown", (=> music.play()), { once: true })


camera = { centerX: 0, centerY: 0 }

class Unifrog
	
	frames =
		for n in [0..4]
			img = new Image
			img.src = "images/frames/dat-boi-#{n}.png"
			img
	
	@save_properties = ["position", "velocity", "wheel_rotation"]

	constructor: ->
		@position = 0
		@velocity = 0
		@wheel_rotation = 0
	
	get_hand_x: (right)->
		rot = delta_at(@position - 10) / 3
		hand_x = if right then -120 else 40
		@position + sin(rot) * 285 + cos(rot) * hand_x
	
	get_hand_y: (right)->
		rot = delta_at(@position - 10) / 3
		hand_x = if right then -120 else 40
		y_at(@position) - cos(rot) * 285 + sin(rot) * hand_x
	
	step: ->
		@velocity += delta_at(@position) / 8
		@velocity *= 0.995
		@position += @velocity
		x_travel = @velocity
		y_travel = y_at(@position - @velocity) - y_at(@position)
		travel = Math.hypot(x_travel, y_travel) * Math.sign(x_travel)
		@wheel_rotation += travel / 90
	
	draw: ->
		frame_index = -@wheel_rotation / Math.PI / 2 * frames.length # + Date.now() / 1000
		frame = frames[~~(frame_index %% frames.length)]
		
		ctx.save()
		ctx.translate @position, y_at(@position)
		ctx.rotate delta_at(@position - 10) / 3
		ctx.drawImage frame, -185, -390
		ctx.restore()


props = []
particles = []

class Particle

	# flame_image = new Image
	# flame_image.src = "images/flame.png"

	constructor: (@x, @y, @vx, @vy, @vangle)->
		@angle = Math.random() * Math.PI * 2
		@vx /= 5
		@vy /= 5
		@life = 100

	step: ->
		@x += @vx
		@y += @vy
		@vx *= 0.99
		@vy *= 0.99
		@vangle += (Math.random() - 0.5) * 0.1
		@angle += @vangle
		@vx += Math.cos(@angle) * 0.1
		@vy += Math.sin(@angle) * 0.1
		@vy -= 0.1
		@life -= 1
	
	draw: ->
		ctx.save()
		ctx.translate @x, @y
		ctx.rotate @angle
		scale = Math.pow(@life / 80, 6)
		ctx.scale scale, scale
		# ctx.drawImage @flame_image, -@flame_image.width / 2, -@flame_image.height / 2
		# ctx.shadowBlur = 10
		# ctx.shadowColor = "rgba(255, 125, 0, 0.2)"
		ctx.fillStyle = "rgba(255, 125, 0, 0.3)"
		ctx.fillRect -4, -8, 8, 16
		ctx.fillStyle = "rgba(255, 255, 0, 0.6)"
		ctx.fillRect -2, -4, 4, 8
		ctx.fillStyle = "rgba(255, 255, 255, 0.9)"
		ctx.fillRect -1, -2, 2, 4
		ctx.restore()

gravity = 0.5

class Prop
	
	ball_image = new Image
	ball_image.src = "images/ball.png"

	duck_image = new Image
	duck_image.src = "images/duck.png"

	duckie_image = new Image
	duckie_image.src = "images/duckie.png"

	torch_image = new Image
	torch_image.src = "images/juggling-torch.png"

	chainsaw_image = new Image
	chainsaw_image.src = "images/juggling-chainsaw.png"

	table_saw_image = new Image
	table_saw_image.src = "images/table-saw.png"

	@save_properties = ["x", "y", "angle", "vx", "vy", "vangle", "next_hand_right", "height_reached_after_bounce", "collides_with_ground", "in_ground", "in_hand"]

	constructor: (@x, @y, @frog, @type)->
		@vx = 0
		@vy = 0
		@vangle = 0
		@angle = 0
		@next_hand_right = starting_hand_right
		@height_reached_after_bounce = -Infinity
		@collides_with_ground = false
		@in_ground = false
	
	throw_to: (x_to, y_to, parabola_height)->
		dx = x_to - @x
		dy = y_to - @y
		t = (sqrt(2) * sqrt(parabola_height)) / sqrt(gravity) * 2
		@vy = 1 - (1/2 * gravity * t ** 2 - dy) / t
		@vx = dx / t
	
	throw_to_next_hand: ->
		frog_saved_properties = Object.fromEntries(Unifrog.save_properties.map (key)=>
			[key, @frog[key]]
		)
		
		parabola_height = if @next_hand_right then 300 else 200
		parabola_height *= Math.max(1, Math.min(3, props.length / 20 - 1/2))
		t = (sqrt(2) * sqrt(parabola_height)) / sqrt(gravity) * 2

		for i in [0..t]
			@frog.step()
		hand_x = @frog.get_hand_x(@next_hand_right)
		hand_y = @frog.get_hand_y(@next_hand_right)
		
		for key in Unifrog.save_properties
			@frog[key] = frog_saved_properties[key]

		@throw_to(hand_x, hand_y, parabola_height)
		@vangle *= -1
	
	step: ->
		@x += @vx
		@y += @vy
		@angle += @vangle
		@vy += gravity
		
		hand = @in_hand?.hand ? @next_hand_right
		hand_x = @frog.get_hand_x(hand)
		hand_y = @frog.get_hand_y(hand)
		@height_reached_after_bounce = min(@height_reached_after_bounce, @y)
		
		if @in_hand
			@x = hand_x
			@y = hand_y
			# @angle = 0
			@in_hand.time += 1
			time_needed = switch @type
				when "ball" then 0
				when "duck" then 20
				when "duckie" then 0
				when "torch" then 10
				when "chainsaw" then 15
				when "table-saw" then 20
				else 0
			if @in_hand.time > time_needed
				@in_hand = null
				@throw_to_next_hand()
				@play_bounce_sound(true)
		else if (
			(@height_reached_after_bounce < hand_y - 30) and
			(hand_x - 30 < @x < hand_x + 30) and
			(hand_y < @y < hand_y + 50)
		)
			hand_occupied = props.some((prop)->
				prop.in_hand? and prop.in_hand.hand == hand
			)
			if not hand_occupied
				@in_hand = { hand: @next_hand_right, time: 0 }
				@next_hand_right = not @next_hand_right
				@height_reached_after_bounce = @y
				@collides_with_ground = true
				# @throw_to_next_hand()
				# @play_bounce_sound(true)
		
		if @y > y_at(@x) and @collides_with_ground
			@vy = -0.9 * abs(@vy)
			@vx += delta_at(@x)
			# if @y + @vy <= y_at(@x + @vx)
				# exiting the ground
			# @play_bounce_sound(false)
			@in_ground = true
		else if @in_ground
			# exiting the ground
			@in_ground = false
			@play_bounce_sound(false)
	
	play_bounce_sound: (juggling)->
		# TODO: clank sounds for chainsaw and table saw when hitting ground (not juggling)
		if @type is "duck"
			play_sound("quack")
		else if @type is "duckie"
			play_sound("chirp", { playback_rate_variation: 0.1 })
		else if @type is "torch"
			play_sound("flame", { playback_rate_variation: 0.2 })
		else if @type is "chainsaw"
			play_sound("chainsaw_rev", { playback_rate_variation: 0.2 })
		else if @type is "table_saw"
			# play_sound("chainsaw_rev", { playback_rate_variation: 0.2 })
			# play_sound("table_saw_loop", { playback_rate_variation: 0.2 })
			# play_sound("table_saw_loop", { playback_rate: 20 })
			if juggling
				play_sound("whoosh", { playback_rate_variation: 0.2 })
			else
				play_sound("bounce", { playback_rate: Math.pow(@vy / -15, 1.2) + 0.2, volume: 0.5 })
		else
			play_sound("bounce", { playback_rate: Math.pow(@vy / -15, 1.2) + 0.2, volume: 0.2 })
	
	start_engine: ->
		if @type isnt "chainsaw" and @type isnt "table_saw"
			return
		start_sound = if @type is "table_saw" then "table_saw_start" else "chainsaw_start"
		loop_sound = if @type is "table_saw" then "table_saw_loop" else "chainsaw_engine_loop"
		audio_buffer = await load_sound(sound_file_paths[start_sound])
		play_sound(start_sound, { time: audio_ctx.currentTime })
		play_sound(loop_sound, { looping: true, time: audio_ctx.currentTime + audio_buffer.duration })
	
	draw: ->
		ctx.save()
		ctx.translate(@x, @y)
		if @type isnt "ball"
			ctx.rotate(@angle)
		if @type is "duck"
			ctx.scale(0.5, 0.5)
			ctx.drawImage(duck_image, -duck_image.width/2, -duck_image.height/2)
		else if @type is "duckie"
			ctx.scale(0.25, 0.25)
			ctx.drawImage(duckie_image, -duckie_image.width/2, -duckie_image.height/2)
		else if @type is "torch"
			scale = 0.4
			ctx.scale(scale, scale)
			ctx.drawImage(torch_image, -torch_image.width/2, -torch_image.height/2)
			x = Math.sin(Math.PI-@angle) * torch_image.height/2*scale + @x
			y = Math.cos(Math.PI-@angle) * torch_image.height/2*scale + @y
			for [0..4]
				particles.push(new Particle(x, y, @vx, @vy, @vangle))
		else if @type is "chainsaw"
			ctx.scale(0.6, 0.6)
			ctx.drawImage(chainsaw_image, -chainsaw_image.width/2, -chainsaw_image.height/2)
		else if @type is "table_saw"
			ctx.scale(0.3, 0.3)
			ctx.drawImage(table_saw_image, -table_saw_image.width/2, -table_saw_image.height/2)
		else
			ctx.drawImage(ball_image, -ball_image.width/2, -ball_image.height/2)
		ctx.restore()

y_at = (ground_x)->
	ground_x /= 4
	100 * sin(- ground_x / 50) -
	200 * sin((- ground_x / 50) / 3) -
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

dat_boi = new Unifrog

starting_hand_right = false
duck_counter = 0
get_next_prop = ->
	prop_type = "ball"
	if duck_counter > 0
		prop_type = "duckie"
		duck_counter -= 1
	else if Math.random() < 0.1 and props.filter((prop) -> prop.type is "duck").length < 1
		prop_type = "duck"
		duck_counter = 3 + Math.random() * 4
	else if Math.random() < 0.1 and props.filter((prop) -> prop.type is "torch").length < 3
		prop_type = "torch"
	else if Math.random() < 0.1 and props.filter((prop) -> prop.type is "chainsaw").length < 3
		prop_type = "chainsaw"
	else if Math.random() < 0.01 and props.filter((prop) -> prop.type is "table_saw").length < 3
		prop_type = "table_saw"
	prop = new Prop(100000, 100000, dat_boi, prop_type)
	prop.vangle = 0.1
	props.push prop
	if prop_type is "chainsaw" or prop_type is "table_saw"
		prop.start_engine()
	prop

next_prop = get_next_prop()
mouse_client_coords = {x: 100000, y: 100000}

client_to_world = ({x, y})=>
	x: x - canvas.width/2 + camera.centerX
	y: y - canvas.height/2 + camera.centerY

world_to_client = ({x, y})=>
	x: x + canvas.width/2 - camera.centerX
	y: y + canvas.height/2 - camera.centerY

window.onclick = (e)->
	mouse_client_coords.x = e.clientX
	mouse_client_coords.y = e.clientY
	{x, y} = client_to_world(mouse_client_coords)
	next_prop.x = x
	next_prop.y = y
	next_prop.throw_to_next_hand()
	# starting_hand_right = not starting_hand_right
	next_prop = get_next_prop()
	next_prop.x = x
	next_prop.y = y

window.onmousemove = (e)->
	mouse_client_coords.x = e.clientX
	mouse_client_coords.y = e.clientY

animate ->
	
	dat_boi.step()
	prop.step() for prop in props when prop isnt next_prop
	particle.step() for particle in particles
	particles = particles.filter((particle)-> particle.life > 0)
	next_prop.angle += next_prop.vangle
	
	camera.centerX = dat_boi.position
	camera.centerY = y_at(dat_boi.position) - canvas.height/3
	
	mouse_in_world = client_to_world(mouse_client_coords)
	next_prop.x = mouse_in_world.x
	next_prop.y = mouse_in_world.y

	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	
	ctx.save()
	ctx.translate(canvas.width / 2, canvas.height / 2)
	ctx.translate(-camera.centerX, -camera.centerY)
	
	ctx.beginPath()
	ctx.lineWidth = 150
	bound = canvas.width/2 + ctx.lineWidth
	for ground_x in [camera.centerX-bound..camera.centerX+bound] by 5
		ctx.lineTo(ground_x, y_at(ground_x))
	ctx.strokeStyle = "hsl(#{sin(Date.now() / 10000) * 360 + 20}, 100%, 90%)"
	ctx.stroke()
	ctx.strokeStyle = "white"
	ctx.lineWidth = 10
	ctx.stroke()
	
	dat_boi.draw()
	prop.draw() for prop in props
	particle.draw() for particle in particles

	if window.visualize_trajectory
		prop_save_states = props.map (prop)->
			properties = Object.fromEntries(Prop.save_properties.map (key)->
				[key, prop[key]]
			)
			{ prop, properties }
		dat_boi_saved_properties = Object.fromEntries(Unifrog.save_properties.map (key)->
			[key, dat_boi[key]]
		)
		ctx.globalAlpha = 0.1
		for [0..40]
			for prop in props
				prop.step()
				prop.draw()
			dat_boi.step()
		ctx.globalAlpha = 1
		for { prop, properties } in prop_save_states
			for key in Prop.save_properties
				prop[key] = properties[key]
		for key in Unifrog.save_properties
			dat_boi[key] = dat_boi_saved_properties[key]
	
	ctx.restore()
