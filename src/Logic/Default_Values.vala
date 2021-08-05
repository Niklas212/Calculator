using GLib.Math;

public Func get_basic_functions () {
    return Func () {
        key = {"sqrt", "root", "mod", "sum", "mean"},
        eval = {
            fun () {eval = (value) => sqrt (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => pow (value[1], 1 / value[0]), arg_left = 0, arg_right = 2},
            fun () {eval = (value) => mod (value[0], value[1]), arg_left = 0, arg_right = 2},
            fun (2) {eval = (value) => sum (value), arg_left = 0, arg_right = -1},
            fun (1) {eval = (value) => mean (value), arg_left = 0, arg_right = -1}
        }
    };
}

public Func get_trigonometric_functions_deg () {
    return Func () {
        key = {"sin", "cos", "tan", "sinh", "cosh", "tanh"},
        eval = {
            fun () {eval = (value) => sin (value[0] * PI / 180), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => cos (value[0] * PI / 180), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => tan (value[0] * PI / 180), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => sinh (value[0] * PI / 180), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => cosh (value[0] * PI / 180), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => tanh (value[0] * PI / 180), arg_left = 0, arg_right = 1},
        }
    };
}

public Func get_trigonometric_functions_rad () {
    return Func () {
        key = {"sin", "cos", "tan", "sinh", "cosh", "tanh"},
        eval = {
            fun () {eval = (value) => sin (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => cos (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => tan (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => sinh (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => cosh (value[0]), arg_left = 0, arg_right = 1},
            fun () {eval = (value) => tanh (value[0]), arg_left = 0, arg_right = 1},
        }
    };
}

public Func get_intern_functions (bool mode)
{
    Func funs = get_basic_functions ();
    var keys = funs.key;
    var evals = funs.eval;

    Func trigonometric_funs = (mode) ? get_trigonometric_functions_deg () : get_trigonometric_functions_rad ();

    for (int i = 0; i < trigonometric_funs.key.length; i++) {
        keys += trigonometric_funs.key[i];
        evals += trigonometric_funs.eval[i];
    }

    funs.key = keys;
    funs.eval = evals;
    return funs;
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
    Replaceable ret = Replaceable () {
        key = {"e", "p", "pi"},
        value = {2.71828189, PI, PI}
    };
    return ret;
}

public Replaceable get_custom_variable (Replaceable custom )
{
    var ret = get_variable();
    var keys = ret.key;
    var values = ret.value;

    for (int i = 0; i < custom.key.length; i++) {
        if (custom.key[i] in keys) {
            continue;
        }
        else {
            keys += custom.key[i];
            values += custom.value[i];
        }
    }

    return Replaceable () {key = keys, value = values};
}


public UserFunc get_extern_functions (CustomFunctions custom) {
    return UserFunc () {
        key = custom.key,
        arg_right = custom.arg_right,
        data = custom.data
    };
}

