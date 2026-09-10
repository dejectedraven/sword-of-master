class_name Unshaded
extends RefCounted
# 夜色下不参与光照的材质工厂（飘字/提示/UI 等需要始终可见的 CanvasItem）

static func material() -> CanvasItemMaterial:
	var m = CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m
