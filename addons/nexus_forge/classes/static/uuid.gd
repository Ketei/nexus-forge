#MIT License

# Copyright (c) 2023 Xavier Sellier
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name UUID
extends Resource
## Godot UUID by Binogure Studio used to generate V4 UUIDs
##
## Unique identifier generation v4 for Godot Engine
## Version 3.0.0
# This script has been modified from its original version.
# Modifications by Ketei (2025):
# - Added explicit type hints for variables and function returns.
# - Renamed static functions for clarity.
# - Changed internal array to `PackedByteArray` for memory efficiency.
# - Added some documentation.

const BYTE_MASK: int = 0b11111111 # 255
var _uuid: PackedByteArray


# You generally would not call this function directly; it's an internal helper for `v4()`.
## Generates the raw 16 bytes (128 bits) for a UUID v4.
## It uses the global `randi()` function for randomness and applies the necessary
## bit manipulations to bytes at index 6 and 8 to conform to the UUID v4 standard.
static func _generate_raw_uuid_bytes_global() -> PackedByteArray:
	var bytes_array: PackedByteArray = PackedByteArray()
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(((randi() & BYTE_MASK) & 0x0f) | 0x40) # Version 4 bits
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(((randi() & BYTE_MASK) & 0x3f) | 0x80) # RFC 4122 variant bits
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	bytes_array.append(randi() & BYTE_MASK)
	
	return bytes_array


# You generally would not call this function directly; it's an internal helper for `generate_with_rng()` and `_init()`.
## Generates the raw 16 bytes (128 bits) for a UUID v4 using a provided RandomNumberGenerator.
static func _generate_raw_uuid_bytes_rng(rng: RandomNumberGenerator) -> PackedByteArray:
	var bytes_array: PackedByteArray = PackedByteArray()
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(((rng.randi() & BYTE_MASK) & 0x0f) | 0x40) # Version 4 bits
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(((rng.randi() & BYTE_MASK) & 0x3f) | 0x80) # RFC 4122 variant bits
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	bytes_array.append(rng.randi() & BYTE_MASK)
	
	return bytes_array


# You should call this function when you need a new, randomly generated UUID string.
## Generates a new UUID v4 string.
static func generate_new() -> String:
  # 16 random bytes with the bytes on index 6 and 8 modified
	var bytes: PackedByteArray = _generate_raw_uuid_bytes_global()

	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
		bytes[0], bytes[1], bytes[2], bytes[3],

	# mid
		bytes[4], bytes[5],

	# hi
		bytes[6], bytes[7],

	# clock
		bytes[8], bytes[9],

	# clock
		bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
	]


# You should call this function if you need to generate UUIDs using a specific random number generator.
## Generates a new UUID v4 string using a provided [param random_number_generator].
## This offers more control over the source of randomness for the UUID.
static func generate_with_rng(random_number_generator: RandomNumberGenerator) -> String:
  # 16 random bytes with the bytes on index 6 and 8 modified
	var bytes: PackedByteArray = _generate_raw_uuid_bytes_rng(random_number_generator)

	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
		bytes[0], bytes[1], bytes[2], bytes[3],

	# mid
		bytes[4], bytes[5],

	# hi
		bytes[6], bytes[7],

	# clock
		bytes[8], bytes[9],

	# clock
		bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
	]


func _init(rng: RandomNumberGenerator = RandomNumberGenerator.new()) -> void:
	_uuid = _generate_raw_uuid_bytes_rng(rng)


# You generally would not call this frequently unless for specific low-level operations.
## Returns the raw 16 bytes of the UUID as a duplicate of the internal array.
func as_array() -> PackedByteArray:
	return _uuid.duplicate()


# You generally would not call this for common UUID string generation.
## Converts the UUID's raw bytes into a dictionary representation,
## breaking it down into its standard UUID fields (low, mid, hi, clock, node).
## Supports both [param big_endian] and little-endian byte ordering.
func as_dict(big_endian: bool = true) -> Dictionary[String, int]:
	if big_endian:
		return {
			"low"  : (_uuid[0]  << 24) + (_uuid[1]  << 16) + (_uuid[2]  << 8 ) +  _uuid[3],
			"mid"  : (_uuid[4]  << 8 ) +  _uuid[5],
			"hi"   : (_uuid[6]  << 8 ) +  _uuid[7],
			"clock": (_uuid[8]  << 8 ) +  _uuid[9],
			"node" : (_uuid[10] << 40) + (_uuid[11] << 32) + (_uuid[12] << 24) + (_uuid[13] << 16) + (_uuid[14] << 8 ) +  _uuid[15]
		}
	else:
		return {
			"low"  : _uuid[0]          + (_uuid[1]  << 8 ) + (_uuid[2]  << 16) + (_uuid[3]  << 24),
			"mid"  : _uuid[4]          + (_uuid[5]  << 8 ),
			"hi"   : _uuid[6]          + (_uuid[7]  << 8 ),
			"clock": _uuid[8]          + (_uuid[9]  << 8 ),
			"node" : _uuid[10]         + (_uuid[11] << 8 ) + (_uuid[12] << 16) + (_uuid[13] << 24) + (_uuid[14] << 32) + (_uuid[15] << 40)
		}


## Converts the internal raw byte array of the UUID object into the standard UUID v4 string format.
## Call this after creating a UUID object with [method UUID.new] to get its string representation.
func as_string() -> String:
	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
		_uuid[0], _uuid[1], _uuid[2], _uuid[3],

	# mid
		_uuid[4], _uuid[5],

	# hi
		_uuid[6], _uuid[7],

	# clock
		_uuid[8], _uuid[9],

	# node
		_uuid[10], _uuid[11], _uuid[12], _uuid[13], _uuid[14], _uuid[15]
	]


## Compares this UUID object to the [param other] UUID object to check if they represent the same UUID.
func is_equal(other: UUID) -> bool:
  # Godot Engine compares Array recursively
  # There's no need for custom comparison here.
	return _uuid == other._uuid
