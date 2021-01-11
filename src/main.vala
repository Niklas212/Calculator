/* main.vala
 *
 * Copyright 2021 Niklas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Custom_Widget;

public class Calculator:Gtk.Application {

public Calculator(){
    Object(
        application_id:"com.github.niklas212.Calculator",
        flags:ApplicationFlags.FLAGS_NONE
    );



}

public static int main(string[] args)
{
    var app=new Calculator();
    return app.run(args);
}

public delegate void Placeholder();

protected override void activate()
{

    var window =new ApplicationWindow(this);

    var settings=new GLib.Settings("com.github.niklas212.Calculator");



	var con=config(){use_degrees=settings.get_boolean("use-degrees"),round_decimal=settings.get_boolean("show-all"),decimal_digit=settings.get_int("decimal-digits")};

	var ground= new Grid();
    ground.column_spacing=8;
    ground.row_spacing=8;


    var deg_rad=new ToggleButton.with_label(((settings.get_boolean("use-degrees"))?"Degree":"Radian"));
        deg_rad.set_active(settings.get_boolean("use-degrees"));
        deg_rad.toggled.connect(()=>{
            deg_rad.label=(deg_rad.active)?"Degree":"Radian";
            con.use_degrees=!con.use_degrees;
        });
    var btn_dig=new SpinButton.with_range(0,20,1);
        btn_dig.value=settings.get_int("decimal-digits");
        btn_dig.value_changed.connect(()=>{
            con.decimal_digit=(int)btn_dig.value;
        });
    var dig_text=new Label("Number of decimals");

    var dig_swi=new Switch();
        dig_swi.state=settings.get_boolean("show-all");
        dig_swi.halign=END;

        btn_dig.set_sensitive(!(settings.get_boolean("show-all")));
con.round_decimal=false;
        dig_swi.button_press_event.connect(()=>{
            con.round_decimal=dig_swi.state;
            btn_dig.set_sensitive(dig_swi.state);
            return false;
        });
    var swi_box=new Box(HORIZONTAL,8);
        swi_box.pack_start((new Label("show all")));
        swi_box.pack_start(dig_swi);




    var pop_box=new Box(VERTICAL,8);
        pop_box.pack_start(deg_rad);
        pop_box.pack_start((new Separator(HORIZONTAL)));
        pop_box.pack_start(dig_text);
        pop_box.pack_start(swi_box);
        pop_box.pack_start(btn_dig);
        pop_box.pack_start((new Separator(HORIZONTAL)));
        pop_box.margin=8;

    var pop= new Popover(null);
        pop.add(pop_box);
        pop.show_all();
        pop.popdown();



    var menu_button=new MenuButton();
        menu_button.popover=pop;


    var header=new HeaderBar();
    header.show_close_button =true;
    header.title="Calculator";
    //header.pack_end(deg_rad);
    header.pack_end(menu_button);

    Placeholder save=()=>{
        int width,height,pos_x,pos_y;

        window.get_size(out width,out height);
        window.get_position(out pos_x, out pos_y);

        settings.set_int("win-width",width);
        settings.set_int("win-height",height);
        settings.set_int("pos-x",pos_x);
        settings.set_int("pos-y",pos_y);
        settings.set_boolean("use-degrees",deg_rad.active);
        settings.set_boolean("show-all",dig_swi.state);
        settings.set_int("decimal-digits",(int)btn_dig.value);
    };

    window.set_titlebar(header);
    window.border_width = 10;
    window.window_position = WindowPosition.CENTER;
    window.set_default_size (settings.get_int("win-width"), settings.get_int("win-height"));
    window.delete_event.connect(()=>{
        save();
        return false;
    });

    window.destroy.connect (()=>{
        Gtk.main_quit();
    });
    window.move(settings.get_int("pos-x"),settings.get_int("pos-x"));

    var text_exp= new Entry();
    text_exp.set_hexpand(true);
    text_exp.set_vexpand(true);



    var text_result=new Label("");
        text_result.use_markup=true;
        text_result.set_halign(END);
        text_result.set_selectable(true);
        text_result.can_focus=false;

    var text_hexp=new Label("");
        text_hexp.justify=LEFT;
        text_hexp.set_halign(START);
        text_hexp.set_ellipsize(END);
        text_hexp.set_hexpand(true);

    var text_box = new Box(HORIZONTAL,8);
        text_box.pack_end(text_result,false,false);
        text_box.pack_start(text_hexp,false,false);
        text_box.spacing=16;


    ground.attach(text_exp,0,0,9);
    ground.attach(text_box,0,1,9);

    var btn_f= calc_button("=",false);
        btn_f.get_style_context().add_class("suggested-action");
        btn_f.clicked.connect(()=>{evaluate(text_exp,text_result,text_hexp,con);});

    //enter button pressed
    text_exp.activate.connect(()=>{
        evaluate(text_exp,text_result,text_hexp,con);
    });

    var btn_del=calc_button("⇐",false);
        btn_del.get_style_context().add_class("suggested-action");
        btn_del.clicked.connect( ()=>{
            if(text_exp.cursor_position>0) {
                string txt=text_exp.text;
                int pos=text_exp.cursor_position;
                text_exp.text=txt[0:pos-1]+txt[pos:txt.length];
                text_exp.set_position(pos-1);
                }
        } );
    var btn_clear=calc_button("C",false);
        btn_clear.get_style_context().add_class("suggested-action");
        btn_clear.clicked.connect(()=>{
            text_exp.text="";
        });

    var btn_brc_op=calc_button("(",true,text_exp);
    var btn_brc_cl=calc_button(")",true,text_exp);

    var btn_pi=calc_button("pi",true,text_exp,"π");
    var btn_e=calc_button("e",true,text_exp);



    ground.attach(calc_button("7",true,text_exp),0,3);
    ground.attach(calc_button("8",true,text_exp),1,3);
    ground.attach(calc_button("9",true,text_exp),2,3);

    ground.attach(calc_button("4",true,text_exp),0,4);
    ground.attach(calc_button("5",true,text_exp),1,4);
    ground.attach(calc_button("6",true,text_exp),2,4);

    ground.attach(calc_button("1",true,text_exp),0,5);
    ground.attach(calc_button("2",true,text_exp),1,5);
    ground.attach(calc_button("3",true,text_exp),2,5);

    ground.attach(calc_button("0",true,text_exp),0,6);
    ground.attach(calc_button(".",true,text_exp),1,6);
    ground.attach(calc_button("%",true,text_exp),2,6);

    ground.attach(calc_button("/",true,text_exp),3,3);
    ground.attach(calc_button("*",true,text_exp),3,4);
    ground.attach(calc_button("-",true,text_exp),3,5);
    ground.attach(calc_button("+",true,text_exp),3,6);

     ground.attach(btn_f,4,6,2);

     ground.attach(btn_brc_op,4,4);
     ground.attach(btn_brc_cl,5,4);

     ground.attach(btn_pi,4,5);
     ground.attach(btn_e,5,5);

     ground.attach(btn_del,4,3);
     ground.attach(btn_clear,5,3);


    ground.attach(calc_button("sin",true,text_exp),6,3);
    ground.attach(calc_button("cos",true,text_exp),7,3);
    ground.attach(calc_button("tan",true,text_exp),8,3);

    ground.attach(calc_button("sinh",true,text_exp),6,4);
    ground.attach(calc_button("cosh",true,text_exp),7,4);
    ground.attach(calc_button("tanh",true,text_exp),8,4);

    ground.attach(calc_button("!",true,text_exp),6,5);
    ground.attach(calc_button("E",true,text_exp),7,5);
    ground.attach(calc_button("mod",true,text_exp),8,5);

    ground.attach(calc_button("^",true,text_exp),6,6);
    ground.attach(calc_button("sqrt",true,text_exp),7,6);
    ground.attach(calc_button("root",true,text_exp),8,6);

    var btn_add_var=new Button.with_label("add a variable");
        btn_add_var.get_style_context().add_class("suggested-action");
        btn_add_var.can_focus=false;
        btn_add_var.halign=START;

    var box_var=new FlowBox();
        box_var.selection_mode=NONE;
        box_var.can_focus=false;
        box_var.activate_on_single_click=false;
        box_var.homogeneous=false;
        box_var.max_children_per_line=100;

//
//
//
        btn_add_var.clicked.connect(()=>{
            var btn_a=new Button.with_label("apply");
                btn_a.get_style_context().add_class("suggested-action");
                btn_a.margin=8;

            var var_name=new Entry();
                var_name.margin=8;
                var_name.input_purpose=ALPHA;
                var_name.placeholder_text="name";

            var var_value=new Entry();
                var_value.margin=8;
                var_value.input_purpose=NUMBER;
                var_value.placeholder_text="value";

            var show_mess=new Label("");

            var dia_add_var= new Dialog.with_buttons("Add a variable",window,DESTROY_WITH_PARENT);
            dia_add_var.get_content_area().margin=8;
            dia_add_var.get_content_area().add(add_label(var_name,"name of the variable"));
            dia_add_var.get_content_area().add(add_label(var_value,"value of the variable"));
            dia_add_var.get_content_area().add(show_mess);
            dia_add_var.get_action_area().add(btn_a);

            string error_mess="";
            double? val=null;

            Placeholder func=()=>{
                    if(valid_var(var_name.text,var_value.text,con,out error_mess,out val)) {
                        dia_add_var.hide();
                        var rep=con.custom_variable;
                        var keys=rep.key;
                        var values=rep.value;
                        keys+=var_name.text;
                        values+=val??0;
                        con.custom_variable=Replaceable(){key=keys,value=values};
                        box_var.add(var_entry(var_name.text,val.to_string(),text_exp));
                        box_var.show_all();
                    }
                    else {
                        show_mess.set_markup(@"<span foreground=\"red\">$error_mess</span>");
                    }
            };

            var_name.activate.connect(()=>{
                var_value.grab_focus();
            });

            var_value.activate.connect(()=>{
                func();
            });

            btn_a.clicked.connect(()=>{
                    func();
                });

            dia_add_var.show_all();
        });
//
//
//

    box_var.add(btn_add_var);

    ground.attach(box_var,0,2,9);

    window.add(ground);

    window.show_all();

	Gtk.main();

}
}

