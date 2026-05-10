@tool
class_name EditorImporterAtlasSpriteFrames extends EditorImportPlugin


func _get_importer_name() -> String:
	return 'io.nubz4lif.atlas_sprite_frames'


func _get_visible_name() -> String:
	return 'SpriteFrames'


func _get_recognized_extensions() -> PackedStringArray:
	return ['xml', 'json']


func _get_save_extension() -> String:
	return 'res'


func _get_resource_type() -> String:
	return 'SpriteFrames'


func _get_preset_count() -> int:
	return 1


func _get_preset_name(preset_index: int) -> String:
	return 'Default'


func _get_import_options(path: String, preset_index: int):
	return [
		{'name': 'framerate', 'default_value': 24, 'hint_string': 'int'}
	]


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 16


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var atlas_data = AtlasData.load_xml(source_file) if source_file.ends_with('.xml') else AtlasData.load_json(source_file)
	if atlas_data != null:
		var filename: StringName = &'%s.%s' % [save_path, _get_save_extension()]
		return ResourceSaver.save(atlas_data.to_sprite_frames(), filename, ResourceSaver.FLAG_COMPRESS)
	return FAILED