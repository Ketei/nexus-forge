class_name ItemSheet
extends RefCounted

enum ItemFlag {
	SELLABLE,
	GIFTABLE}


enum Rarity {
	COMMON,
}

var item_id: StringName = &""
var name: String = ""
var category: StringName = &""
var rarity: Rarity = Rarity.COMMON
var value: int = 0
var description: String = ""
var flags: Array[ItemFlag] = []
var data: Dictionary[String, Variant] = {}
