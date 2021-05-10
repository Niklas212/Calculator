
def get_string_position (_array: array of string, _string: string):int
	var ret = -1

	for var i = 0 to _array.length
		if _array[i] == _string
			return i

	return ret
