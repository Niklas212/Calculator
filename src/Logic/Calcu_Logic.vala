namespace Calculation {
using GLib.Math;

public errordomain CALC_ERROR {
    INVALID_SYMBOL,
    MISSING_ARGUMENT,
    REMAINING_ARGUMENT,
    MISSING_CLOSING_BRACKET,
    MISSING_OPENING_BRACKET,
    UNKNOWN
    }


public class Evaluation:GLib.Object
{


    public Evaluation(config c=config(){use_degrees=true})
    {
        this.update(c);
        snd_evaluation = new Evaluation.secondary();
    }

    private Evaluation.secondary() {

    }

    public Evaluation.small(config c = config(){use_degrees = true}) {
        this.update(c);
    }

    public Evaluation.with_data(GenericArray<Part?> parts, GenericArray<uint?> seq) {
        var _section = new GenericArray<Part?>();
        var _sequence = new GenericArray<uint?>();

        parts.foreach( (x) => _section.add(x) );
        seq.foreach( (x) => _sequence.add(x) );

        this.section = _section;
        this.sequence = _sequence;
    }

    public void update(config c) {
        fun_intern = get_intern_functions(c.use_degrees);
        fun_extern = get_extern_functions(c.custom_functions);
        operator = get_operator();
        variable = get_custom_variable(c.custom_variable);
        con = c;

        update_match_data ();
    }

    public config con{get; set;}
    public Evaluation? snd_evaluation = null;
	private PreparePart[] parts={};
	public string input{get; set; default="";}
	public double? result{get; private set; default=null;}
	private GenericArray<Part?> section=new GenericArray<Part?>();
	public GenericArray <uint?> sequence = new GenericArray <uint?> ();

	public int bracket{get; set; default=5;}


	public Operation operator{get; set;}
    public Func fun_intern{get; set; }
    public UserFunc fun_extern {get; set;}
	public string[] control{get; set; default={"(", ")", ",", " "};}
    public Replaceable variable {get; set;}

	private MatchData[] match_data = new MatchData[5];

    public void clear(){
        parts={};
        section.remove_range(0,section.length);
        sequence.remove_range (0, sequence.length);
    }

    public void update_match_data () {
        match_data = {
		    MatchData () {key = operator.key, type = OPERATOR},
		    MatchData () {key = fun_intern.key, type = EXPRESSION},
		    MatchData () {key = fun_extern.key, type = FUNCTION},
		    MatchData () {key = control, type = CONTROL},
		    MatchData () {key = variable.key, type = VARIABLE}
		};
    }

    public PreparePart[] get_parts() {
        return this.parts;
    }

    public GenericArray<Part?> get_section() {
        return this.section;
    }

    public GenericArray<uint?> get_sequence() {
        return this.sequence;
    }

	public void split() throws CALC_ERROR
	{
        bool can_negative=true;
        bool check_mul=false;

		PreparePart ap = {};

        int i = 0;
		while (i < input.length) {

            ap = next_real_match (input[i:input.length], match_data, can_negative);

			if(ap.length>0)
			    {
                    if(check_mul&&(!(ap.type==Type.OPERATOR||ap.type==Type.NUMBER||(ap.type==Type.CONTROL&&!(ap.value=="(")))))
                        parts+=PreparePart(){value="*", type=Type.OPERATOR, length=1, index=2};

                   if (ap.value == "-" && (parts.length == 0 || (parts[parts.length - 1].type == Type.CONTROL && parts[parts.length - 1].value != ")")))
                        parts += PreparePart(){value="0", type=Type.NUMBER};

			        parts+=ap;
			        i += ap.length;

			        can_negative=(ap.type==Type.OPERATOR||(ap.type==Type.CONTROL&&ap.value!=")"));
			        check_mul=(ap.type==Type.NUMBER||ap.type==Type.VARIABLE||ap.value==")");
			    }
			else {
			    throw new CALC_ERROR.INVALID_SYMBOL (@"the symbol `$(input[i:i+1])` is not known");
			}

		}
	}

	public void prepare() throws CALC_ERROR
	{
		int bracket_value = 0;
		int invisible_parts = 0;

		foreach (PreparePart part in parts)
		{
			switch (part.type)
			{
				case Type.VARIABLE: {
					section.add (Part () {
						value = variable.value[part.index],
						has_value = true
					});

					break;
				}
				case Type.NUMBER: {
					section.add (Part () {
						value = double.parse (part.value),
						has_value = true
					});

					break;
				}
				case Type.OPERATOR: {
					section.add (Part () {
					    index = section.length + invisible_parts,
						eval = operator.eval[part.index],
						priority = bracket_value + operator.priority[part.index]
					});
					sequence.add (bracket_value + operator.priority[part.index]);

					break;
				}
				case Type.EXPRESSION: {
				    section.add (Part () {
				        index = section.length + invisible_parts,
				        eval = fun_intern.eval[part.index],
				        priority = 4 + bracket_value
				    });
                    sequence.add (bracket_value + 4);
				    break;
				}
				case Type.FUNCTION: {
				    section.add (Part () {
				        index = section.length + invisible_parts,
				        priority = 4 + bracket_value,
				        eval = fun(){eval = fun_extern.eval, arg_right = fun_extern.arg_right[part.index]},
				        data  = (fun_extern.data[part.index]).with_evaluation(snd_evaluation)
				    });
				    //TODO pass config
				    sequence.add (bracket_value + 4);
				    break;
				}
				case Type.CONTROL: {
				    invisible_parts ++;
					if (part.value == ")") {
					    bracket_value -= bracket;
					    if (section.length >= 1)
					        section.get (section.length - 1).bracket_value --;
					}
					else if (part.value == "(") {
					    bracket_value += bracket;
                        if (section.length >= 1) {
					        section.get (section.length - 1).bracket_value ++;
					        section.get (section.length - 1).modifier = OPENING_BRACKET;
					    }
					}
					break;
				}
				default: {
					break;
				}
			}
		}

	if(bracket_value!=0) {
	    if(bracket_value>0) {
            throw new CALC_ERROR.MISSING_CLOSING_BRACKET(@" `$(bracket_value/bracket)` closing $((bracket_value/bracket==1)?"bracket is":"brackets are") missing");
	    }
	    else {
	        bracket_value*=-1;
            throw new CALC_ERROR.MISSING_OPENING_BRACKET(@" `$(bracket_value/bracket)` opening $((bracket_value/bracket==1)?"bracket is":"brackets are") missing");
	    }
	}

	if (section.length < 1)
	    throw new CALC_ERROR.MISSING_ARGUMENT ("");

	}

	public void eval() throws CALC_ERROR
	{

        sequence.sort ( (a, b) => (int) (a < b) );


		for (int i = 0; i < sequence.length; i++)
		{
			var ind = -1;

			for (int j = 0; j < section.length; j++)
			    if (section.get(j).has_value == false && section.get(j).priority == sequence.get(i)) {
			        ind = j;
			        break;
			    }

			var part = section.get (ind);

			var bracket_scope = 0;
			var check_scope = false;
			if ( (part.eval.arg_right >= 1 || part.eval.arg_right == -1) ) {
			    check_scope = true;
			    bracket_scope = part.bracket_value;

			    if (! (part.modifier == OPENING_BRACKET)) {
			        bracket_scope ++;
			    }
			    //bracket_scope += (int) (OPENING_BRACKET in part.modifier);
			}

			double[] arg = {};

			//get arg_left
			if (part.eval.arg_left > 0)
			{
			    if ( (ind - 1) >= 0 && section.get (ind - 1).has_value) {
				    arg += section.get (ind - 1).value;
				    section.remove_index (ind - 1);
				}
				else throw new CALC_ERROR.MISSING_ARGUMENT(@"Missing Argument, '$(parts[ind].value)' requires a left argument");
			}

			//get arg_right
			int l = 0;
			while (l < part.eval.arg_right || part.eval.arg_right == -1)
			{
			    l ++;
			    if ( (ind + 1 - part.eval.arg_left) < section.length && section.get (ind + 1 - part.eval.arg_left).has_value && !(check_scope && bracket_scope <= 0) ) {
				    arg += section.get (ind + 1 - part.eval.arg_left).value;
				    bracket_scope += section.get (ind + 1 - part.eval.arg_left).bracket_value;
				    section.remove_index (ind + 1 - part.eval.arg_left);
				}
				else if (part.eval.min_arg_right != -1 && l > part.eval.min_arg_right) {
				    break;
				}
				else {
				    var arg_right = (part.eval.min_arg_right > 0) ? part.eval.min_arg_right : part.eval.arg_right;
				    var no_max = part.eval.min_arg_right > 0;
				    var key = parts[part.index].value;
				    throw new CALC_ERROR.MISSING_ARGUMENT(@"Missing Argument, '$key' requires $( (no_max) ? "at least " : "" )$(arg_right) right $( (arg_right > 1) ? "arguments" : "argument"  )");
			    }
			}

			section.set (ind - part.eval.arg_left, Part() {
				value = part.eval.eval(arg, part.data),
				has_value = true,
				bracket_value = bracket_scope
			});
		}
		if (section.length > 1)
		    throw new CALC_ERROR.REMAINING_ARGUMENT(@"$(section.length - 1) $( (section.length > 2) ? "arguments are" : "argument is" ) remaining");
		result = section.get(0).value ?? 0 / 0;
		if (con.round_decimal) {
		    result=round(result*pow(10,con.decimal_digit))/pow(10,con.decimal_digit);
	    }
	}

    public double eval_auto (string in, config? c = null) throws CALC_ERROR {
        this.input = in;
        if (c != null)
            this.update (c);
        try {
            #if DEBUG
            int64 msec0 = GLib.get_real_time();
            #endif
            this.split();
            #if DEBUG
            int64 msec1 = GLib.get_real_time();
            #endif
            this.prepare();
            #if DEBUG
            int64 msec2 = GLib.get_real_time();
            #endif
            this.eval();
            #if DEBUG
            int64 msec3 = GLib.get_real_time();
            print (@"times\t$(msec1 - msec0)\t$(msec2 - msec1)\t$(msec3 - msec2)\n");
            #endif
        }
        catch(Error e) {
            this.clear();
            throw e;
        }
        this.clear();
        return this.result;
    }

    public static  Eval fun_extern_eval = (value, data) =>{
                    var func_data = data as UserFuncData;

                    for (int i = 0; i < func_data.parts.length; i++)
                        func_data.evaluation.section.add(func_data.parts[i]);
                    for (int i = 0; i < func_data.sequence.length; i++)
                        func_data.evaluation.sequence.add(func_data.sequence[i]);

                    // causes "g_object_ref: assertion 'G_IS_OBJECT (object)' failed"
                    //func_data.parts.foreach((part) => func_data.evaluation.section.add(part));
                    //func_data.sequence.foreach((seq) => func_data.evaluation.sequence.add(seq));

                    for (int i = 0; i < func_data.part_index.length; i++) {
                        func_data.evaluation.section[func_data.part_index[i]].value = value[func_data.argument_index[i]];
                    }

                    func_data.evaluation.eval();
                    func_data.evaluation.clear();
                    return func_data.evaluation.result ?? 0 / 0;
            };

    public static void get_data_range (UserFuncData data, double start, double end, int amount_of_steps, ref double[] values, int array_start ) {

        for (int i = 0; i < amount_of_steps; i++) {
            double x = start + (end - start) / (amount_of_steps - 1) * i;

            values [i + array_start] = fun_extern_eval ( {x}, data);

        }

    }

}

}
