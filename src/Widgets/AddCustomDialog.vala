using Gtk;
using Custom_Widget;

public class AddCustomDialog : Dialog {
        // on variable added
        public signal void var_applied ();
        private delegate bool CheckVariable (string key, string value);

        public AddCustomDialog (ApplicationWindow window, config *con, Calculation.Evaluation eval = new Calculation.Evaluation.small()) {

            // TODO set title
            this.get_content_area().margin = 8;

            var btn_a = new Button.with_label("apply");
                    btn_a.get_style_context().add_class("suggested-action");
                    btn_a.margin = 8;

            var var_name = new Entry();
                    var_name.margin = 8;
                    var_name.input_purpose = ALPHA;
                    var_name.placeholder_text = "name";

            var var_value = new Entry();
                    var_value.margin = 8;
                    var_value.input_purpose = NUMBER;
                    var_value.placeholder_text = "value";

            var show_mess = new Label("");

            this.get_content_area().add(add_label(var_name,"name of the variable"));
            this.get_content_area().add(add_label(var_value,"value of the variable"));
            this.get_content_area().add(show_mess);
            this.get_action_area().add(btn_a);

            var_name.activate.connect( () => {
                var_value.grab_focus();
            });

            CheckVariable add_variable = (key, value) => {
                // checks if an field is empty
                if (key.length < 1 || value.length < 1) {
                    show_mess.set_markup( red_markup("the fields may not be empty") );
                    return false;
                }
                // checks if key contains non alphabetic chars
                for (int i = 0; i < key.length; i++)
                    if(!key[i].isalpha()) {
                        show_mess.set_markup( red_markup("the name is not valid") );
                        return false;
                    }

                // checks if key is already defined (function)
                if (key in con.custom_functions.key) {
                    show_mess.set_markup(red_markup(@"$key is already defined (function)"));
                    return false;
                }
                else try {
                    double result = eval.eval_auto(value);
                    // add_variable() also checks if name is already defined
                    con.custom_variable.add_variable(key, result);
                } catch (Error e) {
                    show_mess.set_markup(red_markup(e.message));
                    return false;
                }
                return true;
            };

            var_value.activate.connect(() => {
                if (add_variable(var_name.text, var_value.text)) {
                    var_applied();
                    this.hide();
                }
            });

            btn_a.clicked.connect(() => {
                if (add_variable(var_name.text, var_value.text)) {
                    var_applied();
                    this.hide();
                }
            });

            this.show_all();
        }

        private string red_markup (string mess) {
            return @"<span foreground=\"red\">$mess</span>";
        }
    }

