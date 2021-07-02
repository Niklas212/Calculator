[indent=0]
uses GLib.Math

delegate Eval(value:array of double, data: Data?):double

class abstract Data: Object
	prop public part:Part
		get
			return part

enum Type
	NUMBER
	VARIABLE
	FUNCTION
	EXPRESSION
	CONTROL
	OPERATOR

struct config
	use_degrees:bool
	round_decimal:bool
	decimal_digit:int
	custom_variable:Replaceable
	custom_functions:CustomFunctions

struct MatchData
	key: array of string
	type: Type

struct PreparePart
	value:string
	type:Type
	length:int
	index:int

struct CustomFunctions
	key: array of string
	arg_right: array of int
	data: array of UserFuncData

	def add_function(_key:string, _arg_right:int, _data:UserFuncData, _override:bool = false) raises Calculation.CALC_ERROR
		if _key in key
			if _override
				for var i = 0 to (key.length - 1)
					if key[i] == _key
						arg_right[i] = _arg_right
						data[i] = _data
						return
			else
				raise new Calculation.CALC_ERROR.UNKNOWN(@"'$_key' is already defined")
		var keys = key
		var args = arg_right
		var datas = data
		keys += _key
		args += _arg_right
		datas += _data
		key = keys
		arg_right = args
		data = datas

	def remove_function(name:string):int raises Calculation.CALC_ERROR
		if not (name in key) do raise new Calculation.CALC_ERROR.UNKNOWN(@"the function '$name' is not defined")

		index:int = -1

		var keys = new array of string[key.length - 1]
		var args = new array of int[key.length - 1]
		var datas = new array of UserFuncData[key.length - 1]

		if key.length == 1
			key = keys
			arg_right = args
			data = datas
			return 0

		m:int = 0
		for var i = 0 to keys.length
			if key[i] == name
				m = 1
				index = i
			else
				keys[i - m] = key[i]
				args[i - m] = arg_right[i]
				datas[i - m] = data[i]
		key = keys
		data = datas
		arg_right = args

		return index


struct UserFunc
	key: array of string
	eval:Eval
	arg_right: array of int
	data:array of UserFuncData

struct Part
	value:double?
	eval:fun
	has_value:bool
	data: Data

struct Replaceable
	key:array of string
	value:array of double

	def add_variable(_key:string, _value:double, _override:bool = false) raises Calculation.CALC_ERROR
		if _key in key or _key in get_variable().key
			if _key in get_variable().key or not _override
				raise new Calculation.CALC_ERROR.UNKNOWN(@"'$(_key)' is already defined")
			if _override
				for var i = 0 to (key.length - 1)
					if key[i] == _key
						key[i] = _key
						value[i] = _value
						return
		var values = value
		var keys = key
		keys += _key
		values += _value
		value = values
		key = keys

	def remove_variable(_name:string):int raises Calculation.CALC_ERROR
		index:int = -1
		if _name in key
			var keys = new array of string[key.length - 1]
			var values = new array of double[value.length - 1]
			if key.length == 1
				key = keys
				value = values
				return 0
			m:int = 0
			for var i = 0 to (key.length - 1)
				if key[i] != _name
					keys [i - m] = key[i]
					values [i - m] = value[i]
				else
					m = 1
					index = i
			key = keys
			value = values

			return index
		else
			raise new Calculation.CALC_ERROR.UNKNOWN(@"the variable '$_name' does not exist")

struct Operation
	key:array of string
	priority:array of int
	eval:array of fun

struct Func
	key:array of string
	eval:array of fun

struct fun
	eval:Eval
	arg_left:int
	arg_right:int


struct Sequence
	index: int
	priority:int
	arguments:int

class UserFuncData: Data
	part_index: array of int
	argument_index: array of int
	config: config
	sequence: GenericArray of Sequence?
	parts: GenericArray of Part?
	evaluation: Calculation.Evaluation

	def with_evaluation(eval:Calculation.Evaluation): UserFuncData
		this.evaluation = eval
		return this

	construct with_data(expression:string, variables: array of string) raises Calculation.CALC_ERROR
		try
			this.generate_data(expression, variables)
		except e: Calculation.CALC_ERROR
			raise e

	def generate_data(expression:string, variables: array of string, test:bool = true) raises Calculation.CALC_ERROR
		//TODO use config from this class
		var e = new Calculation.Evaluation.small()
		e.input = expression
		var keys = get_variable().key
		var values = get_variable().value
		for i in variables
			if i in keys
				 raise new Calculation.CALC_ERROR.UNKNOWN(@"'$i' is already defined --- use another variable name")
			else
				keys += i
				values += 0.0
		e.variable = Replaceable(){key = keys, value = values}
		e.update_match_data ()
		try
			e.split()
		except er: Calculation.CALC_ERROR
			e.clear()
			raise er
		// set part_index && argument_index
		var parts = e.get_parts()
		part_ind: array of int = new array of int[0]
		argument_ind: array of int = new array of int[0]
		i:int = 0
		position:int = -1
		for p in parts
			if p.type == Type.VARIABLE
				position = get_string_index(e.variable.key, p.value)
				if position > 2
					part_ind += i
					argument_ind += position - 3
			else if p.type == Type.CONTROL do i--
			i++
		this.part_index = part_ind
		this.argument_index = argument_ind
		//set sequence && parts
		try
			e.prepare()
			this.parts = e.get_section()
			this.sequence = e.get_sequence()
		except er: Calculation.CALC_ERROR
			e.clear()
			raise er

		//test generated data
		if test
			var test_e = new Calculation.Evaluation.with_data(e.get_section(), e.get_sequence())
			try
				test_e.eval()
			except er: Calculation.CALC_ERROR
				er.message = "incorrect expression: " + er.message
				raise er

def get_string_index(arr: array of string, match:string):int
	i:int = 0
	for a in arr
		if a == match
			return i
		i ++
	return -1

def faq(a:double):double
	if a<0 do return 0
	if a==0 do return 1
	ret:double=1
	for var i=1 to a
		ret*=i
	return ret

def mod(a:double,b:double):double
	d:double=a/b
	dc:double=floor(d)
	if d==dc do return 0
	ret:double=(d-dc)*b
	return Math.round(ret*100000)/100000

def eval_seq(data:GenericArray of Sequence?):GenericArray of Sequence?
	for var i=0 to (data.length-2)
		var arg=data.get(i).arguments
		var num=data.get(i).index
		for var c=i+1 to (data.length-1)
			if num<data.get(c).index
				var s=data.get(c)
				s.index-=arg
				data.set(c,s)
	return data



def next_multi_match (input:string, data:array of MatchData): PreparePart
	max_match_type_index:int = -1
	max_match_index:int = -1
	max_match_length:int = -1

	i:int = -1
	j:int = -1
	// consider using sorted (string-length) data
	for d in data
		i ++
		j = -1
		for e in d.key
			j ++
			if (e.length <= input.length && e.length > max_match_length && input[0:e.length] == e)
				max_match_type_index = i
				max_match_index = j
				max_match_length = e.length

	if (max_match_length > 0)
		return PreparePart() {
			value = data[max_match_type_index].key[max_match_index],
			type = data[max_match_type_index].type,
			length = data[max_match_type_index].key[max_match_index].length,
			index = max_match_index
		}
	else
		return PreparePart() {
			length = -1
		}


def next_real_match (input:string, data:array of MatchData, can_negative:bool):PreparePart
	can_number:bool = false
	is_decimal:bool = false
	is_number:bool = false

	if (can_negative && (input[0] == '-' || input[0] == '+'))
		can_number = true
	else if input[0].isdigit ()
		can_number = true
		is_number = true
	else if input[0] == '.'
		can_number = true
		is_decimal = true

	if can_number
		var i = 0
		while (++i <= input.length)
			if input[i].isdigit ()
				is_number = true
			else if (!is_decimal && input[i] == '.')
				is_decimal = true
			else
				if is_number
					return PreparePart () {
						value = input[0:i],
						type = NUMBER,
						length = i
					}
				else do break

	return next_multi_match (input, data)


def next_match(data:string, key:array of string, out index:int):string
	max_match:string=""
	ind:int=-1
	counter:int=-1
	for p in key
		counter++
		if p.length > data.length
			continue
		else if (p==(data[0:p.length]))
			if p.length>max_match.length
				max_match=p
				ind=counter
	index=ind
	return max_match

