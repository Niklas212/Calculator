using GLib.Math;

public Func get_intern_functions(bool i)
{
    return (i)
    ? Func(){
        key={"sqrt","sin","cos","tan","sinh","cosh","tanh","root","mod"},
        eval={
            fun(){eval=(value)=>sqrt(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>sin(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>cos(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>tan(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>sinh(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>cosh(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>tanh(value[0]*PI/180), arg_left=0, arg_right=1},
            fun(){eval=(value)=>pow(value[1],1/value[0]), arg_left=0, arg_right=2},
            fun(){eval=(value)=>mod(value[0],value[1]), arg_left=0, arg_right=2}
        }
    }
    : Func(){
        key={"sqrt","sin","cos","tan","sinh","cosh","tanh","root","mod"},
        eval={
            fun(){eval=(value)=>sqrt(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>sin(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>cos(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>tan(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>sinh(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>cosh(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>tanh(value[0]), arg_left=0, arg_right=1},
            fun(){eval=(value)=>pow(value[1],1/value[0]), arg_left=0, arg_right=2},
            fun(){eval=(value)=>mod(value[0],value[1]), arg_left=0, arg_right=2}
        }
    };
}

public Operation get_operator()
{
    return Operation(){
		key={"+","-","*","/","%","^","!","E"},
		priority={1,1,2,2,4,3,4,3},
		eval={
			fun(){
				eval=(value)=>value[0]+value[1], arg_left=1, arg_right=1 },
			fun(){
				eval=(value)=>value[0]-value[1], arg_right=1, arg_left=1 },
			fun(){
				eval=(value)=>value[0]*value[1], arg_left=1, arg_right=1},
			fun(){
				eval=(value)=>value[0]/value[1], arg_right=1, arg_left=1 },
			fun(){
				eval=(value)=>value[0]/100,
				arg_left=1, arg_right=0},
			fun(){
				eval=(value)=>pow(value[0],value[1]),
				arg_right=1, arg_left=1},
			fun() {
				eval=(value)=>faq(value[0]),
				arg_left=1, arg_right=0},
			fun() {
				eval=(value)=>value[0]*(pow(10,value[1])),
				arg_left=1, arg_right=1}
		}
	};
}

public Replaceable get_variable()
{
    Replaceable ret=Replaceable(){key={"e","p","pi"}, value={2.71828189,PI,PI}};
    return ret;
}

public Replaceable get_custom_variable(Replaceable custom )
{
    var ret=get_variable();
    var keys=ret.key;
    var values=ret.value;

    for (int i=0; i<custom.key.length; i++) {
        if(custom.key[i]in keys) {
            continue;
        }
        else {
            keys+=custom.key[i];
            values+=custom.value[i];
        }
    }

    return Replaceable(){key=keys, value=values};
}
//TODO remove later just for testing
public UserFuncData get_user_func_data() {
    var part = new GenericArray<Part?>();
    var seq = new GenericArray<Sequence?>();
    seq.add(Sequence(){index = 1, priority = 1, arguments = 2});
    part.add(Part(){has_value = true});
    part.add(Part(){eval = fun(){arg_left = 1, arg_right = 1, eval = (value) => value[0]+value[1]}});
    part.add(Part(){has_value = true, value = 9});
    var ret = new UserFuncData(){parts = part, sequence = seq, part_index = {0}, argument_index = {0}};
    return ret;
}
//TODO remove later just for testing
public UserFuncData get_hypo() {
    var part = new GenericArray<Part?>();
        part.add(Part(){eval = fun() {arg_right = 1, eval = (value) => sqrt(value[0])} });
        part.add(Part(){has_value = true});
        part.add(Part(){eval = fun(){arg_left = 1, arg_right = 1, eval = (value) => value[0] * value[1]}});
        part.add(Part(){has_value = true});
        part.add(Part(){eval = fun(){arg_left = 1, arg_right = 1, eval = (value) => value[0] + value[1]}});
        part.add(Part(){has_value = true});
        part.add(Part(){eval = fun(){arg_left = 1, arg_right = 1, eval = (value) => value[0] * value[1]}});
        part.add(Part(){has_value = true});

    var seq = new GenericArray<Sequence?>();
        seq.add(Sequence(){index = 0, arguments = 1, priority = 1});
        seq.add(Sequence(){index = 4, arguments = 2, priority = 2});
        seq.add(Sequence(){index = 2, arguments = 2, priority = 3});
        seq.add(Sequence(){index = 6, arguments = 2, priority = 3});

    return new UserFuncData(){parts = part, sequence = seq, part_index = {1, 3, 5, 7}, argument_index = {0, 0, 1, 1}};
}

public UserFunc get_extern_functions(CustomFunctions custom) {
    return UserFunc(){
        key = custom.key,
        arg_right = custom.arg_right,
        data = custom.data,
        eval = Calculation.Evaluation.fun_extern_eval
    };
}

