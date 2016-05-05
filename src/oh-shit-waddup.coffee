
images =
	for n in [0..4]
		img = new Image
		img.src = "images/frames/dat-boi-#{n}.png"
		img

y_at = (ground_x)->
	canvas.height * 3/4 +
	100 * sin(Date.now() / 1500 - ground_x / 50) -
	# 200 * sin(ground_x / 67) -
	ground_x * 2

x_at = (ground_x)->
	canvas.width / 2 +
	ground_x * 4

animate ->
	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	frame_index = Date.now() / 1000 * 10
	frame = images[~~(frame_index %% images.length)]
	
	ctx.beginPath()
	for ground_x in [-500..500]
		ctx.lineTo(x_at(ground_x), y_at(ground_x))
	ctx.lineWidth = 150
	ctx.strokeStyle = "hsl(#{sin(Date.now() / 10000) * 360 + 20}, 100%, 90%)"
	ctx.stroke()
	ctx.strokeStyle = "white"
	ctx.lineWidth = 10
	ctx.stroke()
	
	ctx.save()
	ctx.translate x_at(0), y_at(0)
	derive_from = -10
	dy = y_at(derive_from+0.1) - y_at(derive_from-0.1)
	ctx.rotate dy / 3
	ctx.drawImage frame, -185, -390
	ctx.restore()
