
images =
	for n in [0..4]
		img = new Image
		img.src = "images/frames/dat-boi-#{n}.png"
		img

y_at = (ground_x)->
	canvas.height * 3/4 +
	canvas.height * 0.1 * sin(Date.now() / 1500 - ground_x / 50) -
	ground_x * 2

x_at = (ground_x)->
	canvas.width / 2 +
	ground_x * 4 #+ y_at(ground_x) / 5

animate ->
	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	frame_index = Date.now() / 1000 * 10
	frame = images[~~(frame_index %% images.length)]
	
	ctx.beginPath()
	# ctx.moveTo(-50, height_at(-50))
	for ground_x in [-500..500]
		ctx.lineTo(x_at(ground_x), y_at(ground_x))
	ctx.lineWidth = 150
	# ctx.strokeStyle = "#FF8B6E"
	# ctx.strokeStyle = "#555555"
	ctx.strokeStyle = "hsl(#{sin(Date.now() / 10000) * 360 + 20}, 100%, 90%)"
	ctx.stroke()
	ctx.strokeStyle = "white"
	ctx.lineWidth = 10
	ctx.stroke()
	
	ctx.save()
	ctx.translate x_at(0), y_at(0)
	ctx.drawImage frame, -185, -390
	ctx.restore()
