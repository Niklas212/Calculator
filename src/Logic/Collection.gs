[indent=0]
uses GLib.Math

delegate Eval(value:array of double):double

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

struct PreparePart
	value:string
	type:Type
	length:int
	index:int

struct Part
	value:double?
	eval:fun

struct Replaceable
	key:array of string
	value:array of double

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
	//maybe to custom round
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


def possible_number(data:string,negative:bool,is:bool=false):bool
	is_decimal:bool=false

	for var i=0 to data.length
		if data[i].to_string() in "0123456789"
			continue
		else if data[i] == '.'
			if is_decimal //or (is and i+1==data.length)
				return false
			else
				is_decimal=true
				continue
		else if (data[i] == '-' or data[i] == '+') and (i==0) and (not is or data.length>1) and negative
			continue
		else
			return false

	return true

def next_number(input:string, out pos:int?=null,neg:bool):string
	last_pos:int=0
	pos=-1
	for var i=1 to input.length
		if possible_number(input[0:i],neg,true)
			last_pos=i
		if (not possible_number(input[0:1],neg) or i==input.length)
			pos=last_pos;
			if i>0
				return (input[0:last_pos])
	return ""


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


