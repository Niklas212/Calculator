using Gtk;
using Cairo;

using Calculation;


public class FunctionGraph : DrawingArea {


        // relativ to lines
        private int data_start = 0;
        private int data_end = 0;

        private int steps_per_size = 2;
        private int amount_of_steps = 0;
        private double[] values;
        private double SIZE = 40;
        private double size_value = 1;

        public signal void request_data(double start, double end, int steps, ref double[] _array, int array_start = 0);
        //public signal double request_single_data (double x);


        public FunctionGraph () {

            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                      | Gdk.EventMask.BUTTON_RELEASE_MASK
                      | Gdk.EventMask.POINTER_MOTION_MASK);

            set_size_request (400, 300);

            //data_start = 200 / SIZE * -1;
            //data_end = 200 / SIZE;
            values = new double[0];

      /*      size_allocate.connect( () => {
                var width = get_allocated_width ();
                var height = get_allocated_height ();

                int new_data_start = (int) (width / -2.0 / SIZE);
                int new_data_end = (int) (width / 2.0 / SIZE);

                if (width % SIZE != 0) {
                    new_data_start --;
                    new_data_end ++;
                }

                int new_amount_of_steps = 1 + (new_data_end - new_data_start) * steps_per_size;

                if (new_data_start - 1 == data_start && new_data_end + 1 == data_end) {
                    print ("verkleinern\n");
                    var _values = values[steps_per_size:new_amount_of_steps + steps_per_size];
                    values.resize (new_amount_of_steps);
                    values = _values;

                    data_start = new_data_start;
                    data_end = new_data_end;
                    amount_of_steps = new_amount_of_steps;
                } else if (new_data_start + 1 == data_start && new_data_end - 1 == data_end) {
                    print (@"vergroessern, $new_amount_of_steps, $amount_of_steps\n");
                    values.resize (new_amount_of_steps);
                    values.move (0, steps_per_size, amount_of_steps);
                    request_data (new_data_start, data_start - 1, steps_per_size, ref values);
                    request_data (data_end + 1, new_data_end, steps_per_size, ref values, new_amount_of_steps - steps_per_size);

                    data_start = new_data_start;
                    data_end = new_data_end;
                    amount_of_steps = new_amount_of_steps;
                }

            });*/

        }

        public override bool draw (Cairo.Context cr) {

            //print ("draw\n\n");
            var width = get_allocated_width ();
            var height = get_allocated_height ();

            int new_data_start = (int) (width / -2.0 / SIZE);
            int new_data_end = (int) (width / 2.0 / SIZE);

            if (width % SIZE != 0) {
                new_data_start --;
                new_data_end ++;
            }

            int new_amount_of_steps = 1 + (new_data_end - new_data_start) * steps_per_size;

            if ( ! (new_amount_of_steps == amount_of_steps && new_data_start == data_start) ) {


                //values.move (0, amount_of_steps - new_amount_of_steps, new_amount_of_steps);
                values.resize (new_amount_of_steps);

                //if (new_data_start + 1 == )
        int64 msec = GLib.get_real_time () / 1000;
                request_data (new_data_start * size_value, new_data_end * size_value, new_amount_of_steps, ref values, 0);
        int64 msec2 = GLib.get_real_time () / 1000;
        print (@"$new_amount_of_steps -> $(msec2 - msec)\n");
                data_start = new_data_start;
                data_end = new_data_end;
                amount_of_steps = new_amount_of_steps;
            }

            //values = new double[steps];
            //request_data (data_start, data_end, steps, ref values);

            var color_primary = get_style_context().get_color(ACTIVE);
            var color_secondary = get_style_context().get_color(FOCUSED);
            var color_accent = get_style_context().get_color(LINK);

            get_style_context().lookup_color ("theme_selected_bg_color", out color_accent);
            get_style_context().lookup_color ("theme_fg_color", out color_primary);
            get_style_context().lookup_color ("insensitive_fg_color", out color_secondary);



            cr.set_source_rgba (color_secondary.red, color_secondary.green, color_secondary.blue, color_secondary.alpha);
            cr.set_line_width (2);

            for (int i = 1; i < height / 2 / SIZE + 1; i ++) {
                cr.move_to (0, height / 2 + i * SIZE);
                cr.line_to (width, height / 2 + i * SIZE);

                cr.move_to (0, height / 2 - i * SIZE);
                cr.line_to (width, height / 2 - i * SIZE);
            }

            cr.stroke ();


            for (int i = 1; i < width / 2 / SIZE + 1; i ++) {
                cr.move_to (width / 2 + i * SIZE, 0);
                cr.line_to (width / 2 + i * SIZE, height);

                cr.move_to (width / 2 - i * SIZE, 0);
                cr.line_to (width / 2 - i * SIZE, height);
            }

            cr.stroke ();


            cr.set_line_width (4);

            cr.set_source_rgba (color_primary.red, color_primary.green, color_primary.blue, color_primary.alpha);

            cr.move_to (0, height / 2);
            cr.line_to (width, height / 2);

            cr.move_to (width / 2, 0);
            cr.line_to (width / 2, height);

            cr.stroke ();


            cr.set_source_rgba (color_accent.red, color_accent.green, color_accent.blue, color_accent.alpha);
            cr.set_line_width (2);


            int horizontal_step_size = (int) (SIZE / steps_per_size);
            int start_line_position = (int) (width / 2 - (amount_of_steps - 1) / 2 * SIZE / steps_per_size);
            cr.move_to (start_line_position, height / 2 - SIZE * values[0] / size_value);

            //print (@"#$start_line_position, $(values.length)\n");

            for (int i = 1; i < amount_of_steps; i++) {
                cr.line_to (start_line_position + i * horizontal_step_size, height / 2 - SIZE * values[i] / size_value);
                //cr.move_to (start_line_position + i * horizontal_step_size, height / 2 - SIZE * values[i]);
            }

            cr.stroke ();


            return false;
        }

        public override bool button_press_event (Gdk.EventButton event) {

            return false;
        }

        public override bool button_release_event (Gdk.EventButton event) {

            return false;
        }

        public override bool motion_notify_event (Gdk.EventMotion event) {

            return false;
        }


    }
