
images =
	for n in [0..4]
		img = new Image
		img.src = "images/frames/dat-boi-#{n}.png"
		img

animate ->
	ctx.fillStyle = "hsl(#{sin(Date.now() / 10000) * 360}, 80%, 80%)"
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	frame_index = Date.now() / 1000 * 15
	frame = images[~~(frame_index %% images.length)]
	ctx.save()
	ctx.translate canvas.width / 2, canvas.height * 3/4
	ctx.drawImage frame, -185, -384
	ctx.restore()
