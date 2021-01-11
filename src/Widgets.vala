namespace Custom_Widget{
using Gtk;
    public Button calc_button(string text,bool default_function,Entry? wdg=null,string? c_t=null)
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
        var e=calc_button(key,true,ent);
        e.halign=START;
        e.set_tooltip_text(value);

        return e;
    }

}
