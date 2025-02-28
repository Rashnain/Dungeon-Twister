class_name TextureOverlapper


static func overlap(texture1: Texture2D, texture2: Texture2D) -> ImageTexture:
	var image1: Image = texture1.get_image()
	var image2: Image = texture2.get_image()

	image1.convert(Image.FORMAT_RGBA8)
	image2.convert(Image.FORMAT_RGBA8)

	image1.blend_rect(image2, Rect2i(Vector2i(0, 0), image2.get_size()), Vector2i(0, 0))

	return ImageTexture.create_from_image(image1)


static func overlap_str(path1: String, path2: String) -> ImageTexture:
	var texture1: Texture2D = load("res://assets/%s.png" % path1)
	var texture2: Texture2D = load("res://assets/%s.png" % path2)

	return overlap(texture1, texture2)
