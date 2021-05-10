using Gtk;
using Calculation;

public class CustomFlowBox : FlowBox {

    public delegate void VariableRemoved (int index);
    public delegate void VariableChanged (string key, double value);

    private Button button_add;
    private config *con;
    private Window window;
    private Entry entry;

    private int var_count = 0;


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
            //button_add.halign = CENTER;
            button_add.clicked.connect( show_add_dialog );
            button_add.set_tooltip_text("add a variable or function");


        this.add(button_add);
        var separator  = new Separator(VERTICAL);
            separator.halign = CENTER;
        this.add( separator );

    }

    public void add_variable(string key, double value) {
        var_count ++;
        this.insert(new CustomVariable (key, value, entry, con, remove_variable, change_variable_value), /*1 +*/ var_count );
        show_all();
    }

    public void remove_variable (int index) {
        //TODO important: add childs to index
        var to_remove = get_children().nth_data(1 + index);
        var_count --;
        remove (to_remove);
    }

    public void change_variable_value (string key, double value) {
        // last parameter is override
        con.custom_variable.add_variable(key, value, true);
    }

    public void add_function(string key, string[] paras) {
        this.add(new CustomFunction(key, paras, entry, con, remove_function));
        show_all();
    }

    public void remove_function(int index) {
        var to_remove = get_children().nth_data(2 + var_count + index);
        remove (to_remove);
    }

    private void show_add_dialog() {
        var add_variable_dialog = new AddCustomDialog( (ApplicationWindow) window, con);

        add_variable_dialog.var_applied.connect( add_variable );
        add_variable_dialog.fun_applied.connect( add_function );
    }

    private class CustomVariable : Button {

        private Popover _popover;
        private Label _label;
        private string key;
        private double value;
        private config *con;
        private VariableRemoved variable_removed;
        private VariableChanged variable_changed;

        public CustomVariable (string key, double value, Entry entry, config *con, VariableRemoved variable_removed, VariableChanged variable_changed) {
            this.key = key;
            this.value = value;
            this.con = con;
            this.variable_removed = variable_removed;
            this.variable_changed = variable_changed;

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
                remove.get_style_context().add_class("destructive-action");
                remove.clicked.connect( () => {
                    try {
                        variable_removed(con.custom_variable.remove_variable(key));
                    } catch (Error e) {
                        print(e.message);
                    }
                    //con.custom_variable = remove_key(con.custom_variable, key, out index);
                    //variable_removed(index);
                } );

            var change_value = new MenuButton();
                change_value.label = "change value";
                change_value.set_popover( change_value_popover() );
               // change_value.clicked.connect( change_value_dialog );

            var box = new Box(VERTICAL, 8);
                _label = new Label(@"$key ($value)");
                box.pack_start(_label);
                box.pack_start(remove);
                box.pack_start(change_value);
                box.margin = 4;

            _popover.add(box);
            _popover.show_all();
            _popover.hide();
        }

        private Popover change_value_popover() {
            var popover = new Popover(this);

            var entry = new Entry();
                entry.input_purpose = NUMBER;
                entry.placeholder_text = @"new value for $key";

            var message = new Label("");


            entry.activate.connect( () => {
                var evaluation = new Calculation.Evaluation.small();
                    try {
                        evaluation.eval_auto(entry.text);
                        variable_changed(key, evaluation.result);
                        _label.label = @"$key ($(evaluation.result))";
                        set_tooltip_text(evaluation.result.to_string());
                        popover.popdown();
                    } catch (Error e) {
                        message.set_markup (@"<span foreground=\"red\">$(e.message)</span>");
                    }
            } );

            var box = new Box (VERTICAL, 8);
                box.pack_start(entry);
                box.pack_start(message);
                box.margin = 4;
                box.show_all();

            popover.add(box);

            return popover;
        }



    }

    public class CustomFunction : Button {
        private config *con;
        private string key;
        private string description;
        private VariableRemoved function_removed;
        private Popover _popover;

        public CustomFunction(string key, string[] paras, Entry entry, config *con, VariableRemoved function_removed) {
            this.con = con;
            this.key = key;
            this.function_removed = function_removed;

            description = key + " (" + string.joinv(", ", paras) + ")";

            init_popover();
            label = key;
            set_tooltip_text(description);
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

        var btn_remove = new Button.with_label("remove");
            btn_remove.get_style_context().add_class("destructive-action");
            btn_remove.clicked.connect( () => {
                try {
                    function_removed(con.custom_functions.remove_function(key));
                } catch (Error e) {
                    print(e.message);
                }
            });

        var graphics_btn = new Button.with_label("show graphics");
            graphics_btn.clicked.connect( () => {


                var function_graph = new FunctionGraph();

                    /*function_graph.request_data.connect ( (start, end, steps, ref values, array_start) => {
                        //double
                        for (int i = 0; i < steps; i ++) {
                            double x = i * (end - start) / (steps - 1) + start;
                            values[array_start + i] = 0.25 * x * x - 4;
                            //values[i] = i - 5;
                        }

                        //return values;
                    });*/

                    int data_position = get_string_position (con.custom_functions.key, key);

                    var evaluation = new Evaluation.small (*con);
                    var data = con.custom_functions.data[data_position].with_evaluation (evaluation);


                    function_graph.request_data.connect ( (start, end, steps, ref values, array_start) => {
                        Evaluation.get_data_range (data, start, end, steps, ref values, array_start);
                    });

                var window = new Window();
                    window.title = description;
                    window.add (function_graph);
                    //window.destroy.connect (Gtk.main_quit);
                    window.show_all ();
            });

        if (con.custom_functions.arg_right [get_string_position (con.custom_functions.key, key)] != 1) {
            graphics_btn.sensitive = false;
            graphics_btn.set_tooltip_text ("only functions with one parameter can be shown");

        }

        var box = new Box(VERTICAL, 8);
            box.add(btn_remove);
            box.add(graphics_btn);
            box.margin = 4;

        _popover.add(box);
        _popover.show_all();
        _popover.hide();
    }

    }

}

