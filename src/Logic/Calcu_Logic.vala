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
        //test values TODO remove
        //this.fun_extern.data[0] = new UserFuncData.with_data("p*x", {"x"});
        //this.fun_extern.data[1] = new UserFuncData.with_data("sqrt(xx+yy)", {"x", "y"});
        //this.fun_extern.data[2] = new UserFuncData.with_data("x+y+xy", {"x", "y"});
    }

    private Evaluation.secondary() {

    }

    public Evaluation.small(config c = config(){use_degrees = true}) {
        this.update(c);
    }

    public Evaluation.with_data(GenericArray<Part?> parts, GenericArray<Sequence?> seq) {
        var _section = new GenericArray<Part?>();
        var _sequence = new GenericArray<Sequence?>();

        parts.foreach( (x) => _section.add(x) );
        seq.foreach( (x) => _sequence.add(x) );

        this.section = _section;
        this.sequence = _sequence;
    }

    public void update(config c) {
        fun_intern=get_intern_functions(c.use_degrees);
        fun_extern = get_extern_functions(c.custom_functions);
        operator=get_operator();
        variable=get_custom_variable(c.custom_variable);
        con=c;
    }

    public config con{get; set;}
    public Evaluation? snd_evaluation = null;
	private PreparePart[] parts={};
	public string input{get; set; default="";}
	public double? result{get; private set; default=null;}
	private GenericArray<Part?> section=new GenericArray<Part?>();
	private GenericArray<Sequence?>sequence=new GenericArray<Sequence?>();

	public int bracket{get; set; default=5;}


	public Operation operator{get; set;}
    public Func fun_intern{get; set; }
    public UserFunc fun_extern {get; set;}
	public string[] control{get; set; default={"(", ")", ",", " "};}
	public Replaceable variable{get; set;}

    public void clear(){
        parts={};
        section.remove_range(0,section.length);
        sequence.remove_range(0,sequence.length);
    }

    public PreparePart[] get_parts() {
        return this.parts;
    }

    public GenericArray<Part?> get_section() {
        return this.section;
    }

    public GenericArray<Sequence?> get_sequence() {
        return this.sequence;
    }

	public void split() throws CALC_ERROR
	{
        bool can_negative=true;
        bool check_mul=false;

		var num=PreparePart(){type=Type.NUMBER};
		var opr=PreparePart(){type=Type.OPERATOR};
		var cnt=PreparePart(){type=Type.CONTROL};
		var vrb=PreparePart(){type=Type.VARIABLE};
		var fui=PreparePart(){type=Type.EXPRESSION};
		var fue=PreparePart(){type=Type.FUNCTION};
		PreparePart ap={};

		int len_num;

		int ind_op=-1;
		int ind_cnt=-1;
		int ind_vrb=-1;
		int ind_fui=-1;
		int ind_fue=-1;

		while(input.length>0) {

			num.value=next_number(input,out len_num, can_negative);
			opr.value=next_match(input,operator.key, out ind_op);
			cnt.value=next_match(input,control, out ind_cnt);
			vrb.value=next_match(input,variable.key, out ind_vrb);
			fui.value=next_match(input,fun_intern.key, out ind_fui);
			fue.value=next_match(input,fun_extern.key, out ind_fue);

			opr.length=opr.value.length;
			cnt.length=cnt.value.length;
			vrb.length=vrb.value.length;
			fui.length=fui.value.length;
			fue.length=fue.value.length;
			num.length=len_num;

			opr.index=ind_op;
			cnt.index=ind_cnt;
			vrb.index=ind_vrb;
            fui.index=ind_fui;
            fue.index=ind_fue;

			ap=get_longest(opr,num,cnt,vrb,fui,fue);

			if(ap.length>0)
			    {
                    if(check_mul&&(!(ap.type==Type.OPERATOR||ap.type==Type.NUMBER||(ap.type==Type.CONTROL&&!(ap.value=="(")))))
                        parts+=PreparePart(){value="*", type=Type.OPERATOR, length=1, index=2};

                   if (ap.value == "-" && (parts.length == 0 || (parts[parts.length - 1].type == Type.CONTROL && parts[parts.length - 1].value != ")")))
                        parts += PreparePart(){value="0", type=Type.NUMBER};

			        parts+=ap;
			        input=input[ap.length:input.length];

			        can_negative=(ap.type==Type.OPERATOR||(ap.type==Type.CONTROL&&ap.value!=")"));
			        check_mul=(ap.type==Type.NUMBER||ap.type==Type.VARIABLE||ap.value==")");
			    }
			else {
			    throw new CALC_ERROR.INVALID_SYMBOL (@"the symbol `$(input[0:1])` is not known");
			}

		}
	}

	public void prepare() throws CALC_ERROR
	{
		int bracket_value = 0;

		foreach(PreparePart part in parts)
		{

			switch(part.type)
			{
				case Type.VARIABLE: {
					section.add(Part(){
						value=variable.value[part.index],
						has_value = true
					});

					break;
				}
				case Type.NUMBER: {
					section.add(Part() {
						value=double.parse(part.value),
						has_value = true
					});

					break;
				}
				case Type.OPERATOR: {
					section.add(Part(){
						eval=operator.eval[part.index]
					});
					sequence.add(Sequence(){
						priority=bracket_value+operator.priority[part.index],
						arguments=operator.eval[part.index].arg_left+operator.eval[part.index].arg_right,
						index=section.length-1
					});

					break;
				}
				case Type.EXPRESSION: {
				    section.add(Part(){
				        eval=fun_intern.eval[part.index]
				    });
				    sequence.add(Sequence(){
				        priority=4+bracket_value,
				        arguments=fun_intern.eval[part.index].arg_right,
				        index=section.length-1
				    });

				    break;
				}
				case Type.FUNCTION: {
				    section.add(Part(){
				        eval = fun(){eval = fun_extern.eval, arg_right = fun_extern.arg_right[part.index]},
				        data  = (fun_extern.data[part.index]).with_evaluation(snd_evaluation)
				    });
				    //TODO pass config
				    sequence.add(Sequence(){
				        priority = 4 + bracket_value,
				        arguments = fun_extern.arg_right[part.index],
				        index = section.length - 1
				    });
				    break;
				}
				case Type.CONTROL: {
					if(part.value==")") {
					    bracket_value-=bracket;
					}
					else if(part.value=="(") {
					    bracket_value+=bracket;
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

	}

	public void eval() throws CALC_ERROR
	{

		//sortierung nach priority
		//int64 msec = GLib.get_real_time();
		sequence.sort(sorting);
		//stdout.printf(@"__time:$( (GLib.get_real_time()-msec)/1000 )\n");
		//index berechnung
		//msec = GLib.get_real_time();
		sequence=eval_seq(sequence);
		//stdout.printf(@"__time:$( (GLib.get_real_time()-msec)/1000 )\n");


		for(int i=0; i<sequence.length; i++)
		{
			var ind=sequence.get(i).index;
			var part=section.get(ind);

			double[]arg={};

			//get arg_left
			for(int l=0; l<part.eval.arg_left; l++)
			{
			    if ( (ind - part.eval.arg_left) >= 0 && section.get(ind - part.eval.arg_left).has_value) {
				    arg+=section.get(ind-part.eval.arg_left).value;
				    section.remove_index(ind-part.eval.arg_left);
				}
				else throw new CALC_ERROR.MISSING_ARGUMENT(@"Missing Argument, '$(parts[ind].value)' requires a left argument");
			}

			//get arg_right
			for(int l=0; l<part.eval.arg_right; l++)
			{
			    if ( (ind + 1 - part.eval.arg_left) < section.length && section.get(ind + 1 - part.eval.arg_left).has_value) {
				    arg+=section.get(ind+1-part.eval.arg_left).value;
				    section.remove_index(ind+1-part.eval.arg_left);
				}
				else throw new CALC_ERROR.MISSING_ARGUMENT(@"Missing Argument, '$(parts[ind].value)' requires $(part.eval.arg_right) right $( (part.eval.arg_right > 1) ? "arguments" : "argument"  )");
			}

			section.set(ind-part.eval.arg_left,Part(){
				value=part.eval.eval(arg, part.data),
				has_value = true
			});
		}
		if (section.length > 1)
		    throw new CALC_ERROR.REMAINING_ARGUMENT(@"$(section.length - 1) $( (section.length > 2) ? "arguments are" : "argument is" ) remaining");
		result=section.get(0).value??null;
		//s_result=result.to_string();
		if(con.round_decimal) {
		    result=round(result*pow(10,con.decimal_digit))/pow(10,con.decimal_digit);
		    //s_result=result.to_string();
	    }
	}

    public double eval_auto(string in, config? c=null) throws CALC_ERROR {
        this.input=in;
        if(c!=null)
            this.update(c);
        try{
            this.split();
            try{
                this.prepare();
                try{
                    this.eval();
                }
                catch(Error e) {
                    this.clear();
                    throw e;
                }
            }
            catch(Error e) {
                this.clear();
                throw e;
            }
        }
        catch(Error e) {
            this.clear();
            throw e;
        }
        this.clear();
        return this.result;
    }

	private PreparePart get_longest(PreparePart x,...)
	{
		var ret=x;
		va_list list = va_list ();

		for (PreparePart? y = list.arg<PreparePart?> (); y != null; y = list.arg<PreparePart?> ())
		{
			if(y.length>ret.length)
				ret=y;
		}

		return ret;
	}

	// to genie <
	CompareFunc<Sequence?> sorting = (a, b) => {
		return (int) (a.priority < b.priority) - (int) (a.priority > b.priority);
	};
	// >
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
