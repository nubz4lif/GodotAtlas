@tool
extends EditorPlugin

var importers:Array[EditorImportPlugin]

func _enter_tree() -> void:
	for newImporterClass in [EditorImporterAtlasData, EditorImporterAtlasSpriteFrames]:
		var newImporter = newImporterClass.new()
		add_import_plugin(newImporter)
		importers.push_back(newImporter)

func _exit_tree() -> void:
	while !importers.is_empty():
		var importer = importers.pop_front()
		remove_import_plugin(importer)