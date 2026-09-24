extends RefCounted
## Pixel replication shared by the creation tool and the comparison lab.

const MAX_FACTOR := 32
const MAX_EDGE := 16384
const MAX_PIXELS := 16777216


static func png_error(path: String, factor: int) -> String:
	# Inspect dimensions before decoding, including when browsing art in the lab.
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Cannot read the input PNG."
	var signature := file.get_buffer(8)
	file.big_endian = true
	if signature != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]) or file.get_32() != 13 or file.get_buffer(4).get_string_from_ascii() != "IHDR":
		return "Input does not contain a valid PNG header."
	var error := size_error(file.get_32(), file.get_32(), factor)
	if not error.is_empty():
		return error
	if file.get_8() > 8:
		return "Use an 8-bit PNG; converting 16-bit source would lose precision."
	return ""


static func size_error(width: int, height: int, factor: int) -> String:
	if factor < 1 or factor > MAX_FACTOR:
		return "Factor must be an integer from 1 to %d." % MAX_FACTOR
	if width < 1 or height < 1:
		return "The source image must not be empty."
	if width * factor > MAX_EDGE or height * factor > MAX_EDGE:
		return "Output exceeds the %d-pixel edge limit; use a smaller factor." % MAX_EDGE
	if width * height * factor * factor > MAX_PIXELS:
		return "Output exceeds the 16-megapixel limit; use a smaller factor."
	return ""


static func enlarge(source: Image, factor: int) -> Image:
	if source == null or not size_error(source.get_width(), source.get_height(), factor).is_empty():
		return null
	var result := source.duplicate() as Image
	result.clear_mipmaps()
	result.convert(Image.FORMAT_RGBA8)
	result.resize(source.get_width() * factor, source.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return result
