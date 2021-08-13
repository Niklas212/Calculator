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

}

