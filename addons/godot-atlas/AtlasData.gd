class_name AtlasData
extends Resource

var animations:Dictionary[String, AtlasAnimationData]

const frame_regex = "\\d+"
static func load_xml(path:String) -> AtlasData:
	if not FileAccess.file_exists(path):
		return null

	var xml: XMLParser = XMLParser.new()
	var error = xml.open(path)
	if error != OK: return null

	var atlas_data:AtlasData = AtlasData.new()

	var texture: Texture2D
	var image: Image

	var frames:Dictionary[AtlasAnimationData, Dictionary]

	var regex = RegEx.create_from_string(frame_regex)
	while xml.read() == OK:
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue

		var node_name: String = xml.get_node_name().to_lower()

		if node_name == 'textureatlas':
			var image_name:String = xml.get_named_attribute_value_safe('imagePath')
			var image_path:String = path.get_base_dir().path_join(image_name)

			if FileAccess.file_exists(image_path) || ResourceLoader.exists(image_path):
				if ResourceLoader.exists(image_path, 'Texture2D'):
					texture = ResourceLoader.load(image_path)
					image = texture.get_image()
				else:
					image = Image.load_from_file(image_path)
					if image != null: # Trying to create a texture from a null image can crash Godot, apparently
						texture = ImageTexture.create_from_image(image)

				if texture == null: return null
				if image != null: image.decompress()
				continue

		if node_name != 'subtexture': continue
		if texture == null: return

		var source = Rect2i(
			Vector2i(xml.get_named_attribute_value_safe('x').to_int(), xml.get_named_attribute_value_safe('y').to_int()),
			Vector2i(xml.get_named_attribute_value_safe('width').to_int(), xml.get_named_attribute_value_safe('height').to_int())
		)

		var offset = Rect2i(
			Vector2i(xml.get_named_attribute_value_safe('frameX').to_int(), xml.get_named_attribute_value_safe('frameY').to_int()),
			Vector2i(xml.get_named_attribute_value_safe('frameWidth').to_int(), xml.get_named_attribute_value_safe('frameHeight').to_int())
		)

		var name:StringName = str(xml.get_named_attribute_value_safe('name')).strip_edges()
		var frame:int = 0

		var result:RegExMatch = regex.search(name)
		if result:
			name = name.left(name.length() - result.get_string().length())
			frame = int(result.get_string())


		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.filter_clip = true
		atlas.region = source

		var rotated: bool = xml.get_named_attribute_value_safe('rotated') == 'true'

		var margin: Rect2i = Rect2i(-1, -1, -1, -1)
		if xml.has_attribute('frameX'):
			if offset.size == Vector2i.ZERO:
				offset.size = source.size

			margin = Rect2i(
					-offset.position.x, -offset.position.y,
					offset.size.x - source.size.x, offset.size.y - source.size.y)

			margin.size = margin.size.clamp(margin.position.abs(), Vector2i.MAX)
			atlas.margin = margin

		if rotated:
			var atlas_image: Image = atlas.get_image()
			atlas_image.rotate_90(COUNTERCLOCKWISE)

			var atlas_texture: ImageTexture = ImageTexture.create_from_image(atlas_image)
			atlas = atlas_texture
			if margin != Rect2i(-1, -1, -1, -1):
				source = Rect2(Vector2.ZERO, atlas_texture.get_size())

				atlas = AtlasTexture.new()
				atlas.atlas = atlas_texture
				atlas.region = source

				margin = Rect2i(
					-offset.position.x, -offset.position.y,
					offset.size.x - source.size.x, offset.size.y - source.size.y)

				atlas.margin = margin

		var animation:AtlasAnimationData = atlas_data.animations.get_or_add(name, AtlasAnimationData.new())
		#if frame >= animation.frames.size(): animation.frames.resize(frame) # This is the lazy way of doing this, as it may create larger than intended arrays when the frame indices are messed up
		frames.get_or_add(animation, {}).set(frame, atlas)

	# Trim indices in case there are any nulls (as a result of resizing)
	for animation in frames.keys():
		var animation_frames = frames.get(animation)

		animation_frames.sort()
		for animation_frame in animation_frames.values():
			animation.frames.push_back(animation_frame)


	return atlas_data

# AseSprite
static func load_json(path:String) -> AtlasData:
	return null # TODO

func to_sprite_frames(fps:int = 24) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	for animation_name in animations.keys():
		if not sprite_frames.has_animation(animation_name):
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, fps)

		var animation = animations.get(animation_name)
		for frame:Texture2D in animation.frames:
			sprite_frames.add_frame(animation_name, frame)
	return sprite_frames
