using Gtk;

public class CustomFlowBox : FlowBox {

    private Button button_add;
    private config *con;
    private Window window;
    private Entry entry;


    public CustomFlowBox (Entry entry, Window window, config *con) {
        this.entry = entry;
        this.window = window;
        this.con = con;

        selection_mode = NONE;
        can_focus = false;
        homogeneous = false;
        max_children_per_line = 20;

        button_add = new Button.with_label("+");
            button_add.get_style_context().add_class("suggested-action");
            button_add.can_focus = false;
            button_add.halign = START;
            button_add.clicked.connect( show_add_dialog );


        this.add(button_add);
    }

    public void add_variable(string key, double value) {
        this.add(new CustomVariable (key, value, entry, con, remove_variable) );
        show_all();
    }

    public void remove_variable (int index) {
        //TODO important: add childs to index
        var to_remove = get_children().nth_data(1 + index);
        remove (to_remove);
    }

    private void show_add_dialog() {
        var add_variable_dialog = new AddCustomDialog( (ApplicationWindow) window, con);

        add_variable_dialog.var_applied.connect( () => {

                var key = con.custom_variable.key[con.custom_variable.key.length - 1];
                var value = con.custom_variable.value[con.custom_variable.key.length - 1];

                add_variable(key, value);

        });
    }

    private class CustomVariable : Button {

        private Popover _popover;
        private string key;
        private double value;
        private config *con;
        //public signal void variable_removed (int index);
        public delegate void VariableRemoved (int index);
        private VariableRemoved variable_removed;

        public CustomVariable (string key, double value, Entry entry, config *con, VariableRemoved variable_removed) {
            this.key = key;
            this.value = value;
            this.con = con;
            this.variable_removed = variable_removed;

            init_popover();
            label = key;
            set_tooltip_text(value.to_string());
            can_focus = false;

            //show popup
            button_press_event.connect( (event) => {
                if (event.type == BUTTON_PRESS && event.button == 3)
                    _popover.show();
                return false;
            });

            //set text
            clicked.connect( () => {
                int pos = entry.cursor_position;
                string txt = entry.text;

                entry.text = txt[0:pos] + key + txt[pos:txt.length];
                entry.set_position(pos + key.length);
            } );


        }

        private void init_popover() {
            _popover = new Popover(this);

            var remove = new Button.with_label("remove");
                remove.clicked.connect( () => {
                    int index = -1;
                    con.custom_variable.remove_variable(key, out index);
                    variable_removed(index);
                } );

            var box = new Box(VERTICAL, 8);
                box.pack_start(new Label(@"$key ($value)"));
                box.pack_start(remove);
                box.margin = 4;

            _popover.add(box);
            _popover.show_all();
            _popover.hide();
        }



    }
}

