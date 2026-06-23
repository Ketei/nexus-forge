extends NFCatalogEntry
class_name NFCatalogEntryStat
## A catalog entry specific for stats.

## The stat type this entry is.
var type: int = TYPE_FLOAT:
	set(t):
		if t == TYPE_INT:
			type = t
		else:
			t = TYPE_FLOAT
