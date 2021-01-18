using Gtk;
using Calculation;

public void evaluate(Entry e,Label l,Label h,config c)
{
    var eval=new Evaluation(c);
    eval.input=e.text;
    h.label="";
    l.label="";

    if(e.text.length>0)
    {
        try{
            eval.split();
            try{
                eval.prepare();
                try{
                    eval.eval();
                    h.label=e.text;
                    e.text=eval.result.to_string();
                    e.set_position(eval.result.to_string().length);
                    l.label=eval.result.to_string();
                }
                catch(Error e)
                {
                    l.set_markup(@"<span foreground=\"red\">$(e.message)</span>");
                }
            }
            catch(Error e)
            {
                l.set_markup(@"<span foreground=\"red\">$(e.message)</span>");
            }
        }
        catch(Error e)
        {
            l.set_markup(@"<span foreground=\"red\">$(e.message)</span>");
        }
    }
}

public bool valid_var(string key, string value,config c,out string message=null,out double val=null)
{
    if(key.length<1||value.length<1) {
        message="the fields may not be empty";
        return false;
    }
        var eval=new Evaluation();
        eval.input=value;
        try{
            eval.split();
            try{
                eval.prepare();
                try{
                    eval.eval();
                    val=eval.result;
                }
                catch(Error e)
                {
                    message="invalid number or expression:"+e.message;
                    return false;
                }
            }
            catch(Error e)
            {
                    message="invalid number or expression:"+e.message;
                return false;
            }
        }
        catch(Error e)
        {
                    message="invalid number or expression:"+e.message;
            return false;
        }

    for (int i=0; i<key.length; i++) {
        if(key[i].isalpha())
        continue;
        else {
            message="the name is not valid";
            return false;
        }
    }


    if(key in c.custom_variable.key||key in get_variable().key) {
        message="the name already exists";
        return false;
    }
    return true;
}

public Replaceable remove_key(Replaceable rep, string key, out int pos) {

    string[]keys={};
    double[]values={};

    for(int i=0; i<rep.key.length; i++) {
        if(rep.key[i]==key) {
            pos=i;
        }
        else {
            keys+=rep.key[i];
            values+=rep.value[i];
        }
    }
    return Replaceable(){key=keys, value=values};
}

public double[] get_values(string v) {
    string last="";
    double[]ret={};

    for(int i=0; i<v.length; i++) {
        if(v[i]==' ') {
            if(last.length>0) {
                ret+=double.parse(last);
                last="";
            }
        }
        else {
            last+=v[i].to_string();
        }
    }

    return ret;
}

public string[] get_keys(string v) {
    string last="";
    string[] ret={};

    for(int i=0; i<v.length; i++) {
        if(v[i]==' ') {
            if(last.length>0) {
                ret+=last;
                last="";
            }
        }
        else {
            last+=v[i].to_string();
        }
    }
    return ret;
}

public string set_values(double[] v) {
    string ret="";
    foreach(double value in v) {
        ret+=value.to_string()+" ";
    }
    return ret;
}

public string set_keys(string[] k) {
    string ret="";
    foreach(string key in k) {
        ret+=key+" ";
    }
    return ret;
}

