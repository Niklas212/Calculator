struct PopInfo
	show:bool
	custom_text:bool
	definition:string
	example:string

def popinfo (defi:string): PopInfo
	var ret = PopInfo()

	ret.show = true
	ret.definition = defi

	return ret


class GuiUserFuncData : UserFuncData
	parameters: array of string
	expression: string

	construct with_data (expression:string, args:array of string) raises Calculation.CALC_ERROR
		try
			super.with_data (expression, args)
		except e: Calculation.CALC_ERROR
			raise e

	def save_to_string (name:string) : string
		return name + "'" + expression + "'" + string.joinv ("'", parameters)


def get_string_position (_array: array of string, _string: string):int
	var ret = -1

	for var i = 0 to _array.length
		if _array[i] == _string
			return i

	return ret

def functions_to_string (data: CustomFunctions): string
	var parts = new array of string[data.key.length]

	for var i = 0 to (data.key.length - 1)
		var _data = data.data[i] as GuiUserFuncData
		parts[i] = _data.save_to_string (data.key[i])

	return string.joinv ("#", parts)

def functions_from_string (data:string): CustomFunctions raises Calculation.CALC_ERROR

	if ! (data.length > 1)
		return CustomFunctions()

	var parts = data.split ("#")

	var ret = CustomFunctions()

	keys:array of string = ret.key
	datas:array of UserFuncData = ret.data
	args:array of int = ret.arg_right

	for p in parts

		try
			var _parts = p.split ("'")

			keys += _parts[0]
			args += _parts.length - 2

			var _data = new GuiUserFuncData.with_data (_parts[1], _parts[2:_parts.length])
			_data.expression = _parts[1]
			_data.parameters = _parts[2:_parts.length]

			var fun_data = _data as UserFuncData
			datas += fun_data

		except e:Calculation.CALC_ERROR
			raise e


	ret.key = keys
	ret.data = datas
	ret.arg_right = args

	return ret

def variables_from_string (data:string): Replaceable
	var ret = Replaceable()

	var values = ret.value
	var keys = ret.key

	var parts = data.split ("'")

	if parts.length > 1
		var number = false

		for part in parts
			if number
				values += double.parse (part)
			else
				keys += part

			number = !number

	ret.key = keys
	ret.value = values
	return ret

def variables_to_string (data:Replaceable):string

	if data.key.length < 1
		return ""

	var builder = new StringBuilder (@"$(data.key[0])'$(data.value[0])")

	for var i = 1 to (data.key.length - 1)
		builder.append (@"'$(data.key[i])'$(data.value[i])")

	return builder.str

//TODO make it faster
def wrap (value:int, min:int, max:int):int
	if value > max
		return max
	else if value < min
		return min
	else do return value

	
