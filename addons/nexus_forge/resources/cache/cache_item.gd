class_name NFLRUCacheLink
extends RefCounted


## The data being held in cache
var data: Variant = null
## The key assigned to the data
var key: String = ""
## The pointer to the [NFLRUCacheLink] in front this object inside a
## [NFLRUCache].
var newer_link: NFLRUCacheLink = null
## The pointer to the [NFLRUCacheLink] behind this object inside a
## [NFLRUCache].
var older_link: NFLRUCacheLink = null


## Clears the whole item. Releasing the [member data], clearing
## the [member key] and releasing the references of the [member newer_link]
## and [member older_link].
func clear() -> void:
	data = null
	key = ""
	newer_link = null
	older_link = null
