using Gtk;
using Custom_Widget;

public class AddCustomDialog : Dialog {
        // on variable added
        public signal void var_applied (string key, double value);
        public signal void fun_applied (string name, string[] paras);

        public AddCustomDialog (ApplicationWindow window, config *con, Calculation.Evaluation eval = new Calculation.Evaluation.small()) {

            // TODO set title
            this.get_content_area().margin = 8;


            //
            // add variable box
            var show_mess = new Label("");

            var var_name = new Entry();
                    var_name.margin = 8;
                    var_name.input_purpose = ALPHA;
                    var_name.placeholder_text = "name";
                    var_name.valign = CENTER;

            var var_value = new Entry();
                    var_value.margin = 8;
                    var_value.input_purpose = NUMBER;
                    var_value.placeholder_text = "value";
                    var_value.valign = CENTER;

            var_name.activate.connect( var_value.grab_focus );


            var_value.activate.connect(() => {
                check_add_variable(var_name.text, var_value.text, show_mess, con, eval);
            });


            var variable_box = new Box(VERTICAL, 8);
                variable_box.pack_start(add_label(var_name, "name of the variable"));
                variable_box.pack_start(add_label(var_value, "value of the variable"));
                variable_box.pack_start(show_mess);

            variable_box.show_all();

            //
            // add function box
            var show_mess_fun = new Label("");

            var fun_name = new Entry();
                fun_name.margin = 8;
                fun_name.valign = CENTER;
                fun_name.input_purpose = ALPHA;
                fun_name.placeholder_text = "name";

            var fun_arg = new Entry();
                fun_arg.margin = 8;
                fun_arg.valign = CENTER;
                fun_arg.input_purpose = ALPHA;
                fun_arg.placeholder_text = "parameters e.g. 'a, b, c, ...'";

            var fun_exp = new Entry();
                fun_exp.margin = 8;
                fun_exp.valign = CENTER;
                fun_exp.input_purpose = ALPHA;
                fun_exp.placeholder_text = "expression";

            fun_name.activate.connect( fun_arg.grab_focus );
            fun_arg.activate.connect( fun_exp.grab_focus );
            fun_exp.activate.connect( () => {
                check_add_function(fun_name.text, fun_exp.text, fun_arg.text, con, show_mess_fun);
            } );

            var fun_grid = new Grid();
                fun_grid.column_homogeneous = true;
                fun_grid.attach( new Label("list of parameters"), 0, 1 );
                fun_grid.attach( fun_arg, 1, 1);
                fun_grid.attach( new Label("expression of the function"), 0, 2 );
                fun_grid.attach( fun_exp, 1, 2 );
                fun_grid.attach( new Label("name of the function"), 0, 0 );
                fun_grid.attach( fun_name, 1, 0 );
                fun_grid.attach( show_mess_fun, 0, 3, 2 );

            var function_box = new Box(VERTICAL, 8);
                function_box.add(fun_grid);
            //
            // Dialog Button
            var btn_a = new Button.with_label("apply");
                btn_a.get_style_context().add_class("suggested-action");
                btn_a.margin = 8;


            var box = new Box(VERTICAL, 8);

            var stack = new Stack();
                stack.add_with_properties (variable_box, name : "variable", title : "VARIABLE");
                stack.add_with_properties (function_box, name : "function", title : "FUNCTION");
                stack.set_transition_type(StackTransitionType.SLIDE_LEFT_RIGHT);
                stack.set_transition_duration(500);

            var stack_switcher = new StackSwitcher();
                stack_switcher.stack = stack;
                stack_switcher.hexpand = true;
                stack_switcher.homogeneous = true;

            btn_a.clicked.connect(() => {
                if (stack.visible_child_name == "variable")
                    var_value.activate();
                else if (stack.visible_child_name == "function")
                    fun_exp.activate();
            });

            box.pack_start(stack_switcher, true, true);
            box.add(stack);

            this.get_content_area().add(box);
            this.get_action_area().add(btn_a);

            //activates text entry by default
            var_name.grab_focus();

            this.show_all();
        }

        private void check_add_variable(string key, string value, Label show_mess, config *con, Calculation.Evaluation eval) {

                // checks if an field is empty
                if (key.length < 1 || value.length < 1) {
                    show_mess.set_markup( red_markup("the fields may not be empty") );
                    return;
                }
                // checks if key contains non alphabetic chars
                for (int i = 0; i < key.length; i++)
                    if(!key[i].isalpha()) {
                        show_mess.set_markup( red_markup("the name is not valid") );
                        return;
                    }

                // checks if key is already defined (function)
                if (key in con.custom_functions.key) {
                    show_mess.set_markup(red_markup(@"$key is already defined (function)"));
                    return;
                }
                else try {
                    double result = eval.eval_auto(value);
                    // add_variable() also checks if name is already defined
                    con.custom_variable.add_variable(key, result);
                    var_applied(key, result);
                    this.hide();
                } catch (Error e) {
                    show_mess.set_markup(red_markup(e.message));
                    return;
                }
        }

        private void check_add_function(string name, string expression, string parameters, config *con, Label label) {
            string _parameters = parameters.replace(" ", "");



                // checks if an field is empty
                if (name.length < 1 || expression.length < 1 || parameters.length < 1) {
                    label.set_markup( red_markup("the fields may not be empty") );
                    return;
                }
                // checks if key contains non alphabetic chars
                for (int i = 0; i < name.length; i++)
                    if(!name[i].isalpha()) {
                        label.set_markup( red_markup("the name is not valid") );
                        return;
                    }

                // checks if key is already defined (variable)
                if (name in con.custom_variable.key) {
                    label.set_markup(red_markup(@"$name is already defined (variable)"));
                    return;
                }



            if (! Regex.match_simple("[a-zA-Z](,[a-zA-Z])*" , _parameters)) {
                label.set_markup( red_markup("the parameters are wrong formatted") );
                return;
            }

            string[] args = Regex.split_simple(",", _parameters);

            try {

                var data = new GuiUserFuncData.with_data (expression, args);
                    data.parameters = args;
                    data.expression = expression;
                con.custom_functions.add_function(name, args.length, data, false);
                fun_applied(name, args);
                this.hide();

            } catch (Error e) {
                label.set_markup ( red_markup (e.message) );
                return;
            }
        }

        private string red_markup (string mess) {
            return @"<span foreground=\"red\">$mess</span>";
        }
    }

