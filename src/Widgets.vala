namespace Custom_Widget{
using Gtk;

    public Button calc_button(string text,bool default_function,Entry? wdg=null, PopInfo info=PopInfo(), string? c_t=null)
    {
        var btn=new Button.with_label(c_t??text);
        if(default_function)
        {
            btn.clicked.connect(()=>{
            int pos=wdg.cursor_position;
            string txt=wdg.text;

                wdg.text=txt[0:pos]+text+txt[pos:txt.length];
                wdg.set_position(pos+text.length);
            });
        }
        btn.can_focus=false;
        if(info.show) {
            if(info.custom_text) {
                btn.set_tooltip_text(info.definition);
            }
            else {
                btn.set_tooltip_text(info.definition.replace("_", text));
            }
        }
        return btn;
    }

    public Widget add_label(Widget wdg, string text, int space=8)
    {
        var stor=new Box(HORIZONTAL,space);
            stor.pack_start((new Label(text)));
            stor.pack_start(wdg);

        return stor;
    }

    public Widget var_entry(string key,string value,Entry ent) {
        var e=calc_button(key,true,ent,PopInfo(){show=true, definition=value});
        e.halign=START;

        return e;
    }

    public class VarEntry{
    public signal void remove_clicked(string akey);

    public Widget show(string key, string value, Entry ent) {
        var svalue=value.replace("e","E");

        var widget=var_entry(key, svalue, ent);

        widget.button_press_event.connect((event)=>{
            if(event.type == BUTTON_PRESS && event.button == 3) {
                var pop=new Popover(widget);
                //pop.margin=8;

        var remove=new Button.with_label("remove");

            remove.clicked.connect(()=>{

                remove_clicked(key);
            });

        var pop_box=new Box(VERTICAL,8);
            pop_box.pack_start((new Label(@"$key ($svalue)")));
            pop_box.pack_start(remove);
            pop_box.margin=4;
            pop_box.show_all();

        pop.add(pop_box);
        pop.show_all();
            }
            return false;
        });
        return widget;
    }
    }

    public class AddVariableDialog{
    public signal string apply(string key, string value);

    public Dialog show(ApplicationWindow window) {
        var dialog=new Dialog.with_buttons("Add a variable",window,DESTROY_WITH_PARENT);
        dialog.get_content_area().margin=8;

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

        dialog.get_content_area().add(add_label(var_name,"name of the variable"));
        dialog.get_content_area().add(add_label(var_value,"value of the variable"));
        dialog.get_content_area().add(show_mess);
        dialog.get_action_area().add(btn_a);

        var_name.activate.connect(()=>{
            var_value.grab_focus();
        });

        var_value.activate.connect(()=>{
            string mess=apply(var_name.text, var_value.text);
            if(mess!=""&&mess!=null) {
                show_mess.set_markup(@"<span foreground=\"red\">$mess</span>");
            }
            else dialog.hide();
        });

        btn_a.clicked.connect(()=>{
            string mess=apply(var_name.text, var_value.text);
            if(mess!=""&&mess!=null) {
                show_mess.set_markup(@"<span foreground=\"red\">$mess</span>");
            }
            else dialog.hide();
        });

        dialog.show_all();
        return dialog;
    }
    }

}

