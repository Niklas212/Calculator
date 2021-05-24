using Gtk;
using Cairo;

using Calculation;


public class FunctionGraph : DrawingArea {


        // relativ to lines
        private int data_start = 0;
        private int data_end = 0;

        private int steps_per_size = 10;
        private int amount_of_steps = 0;
        private double[] values;
        private int SIZE = 40;
        private double size_value = 1;

        private int shift_x;
        private int shift_y;

        private bool dragging = false;
        private int drag_start_x;
        private int drag_start_y;

        public signal void request_data(double start, double end, int steps, ref double[] _array, int array_start = 0);
        //public signal double request_single_data (double x);


        public FunctionGraph () {

            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                      | Gdk.EventMask.BUTTON_RELEASE_MASK
                      | Gdk.EventMask.POINTER_MOTION_MASK);

            set_size_request (400, 300);

            values = new double[0];


        }

        public override bool draw (Cairo.Context cr) {


            var width = get_allocated_width ();
            var height = get_allocated_height ();

            int new_data_start = (int) ( (width / -2.0 - shift_x) / SIZE);
            int new_data_end = (int) ( (width / 2.0 - shift_x) / SIZE);

            double visible_data_start = (width / -2.0 - shift_x) / SIZE;
            //new_data_start += (int) (shift_x / SIZE);
            //new_data_start -= (int) (shift_x / SIZE);

            int v_data_start = (int) ( (height / -2.0 - shift_y) / SIZE);
            int v_data_end = (int) ( (height / 2.0 - shift_y) / SIZE);

            if ( (width - shift_x) % SIZE != 0) {
                new_data_start --;
                new_data_end ++;
            }

            if ( (height - shift_y) % SIZE != 0) {
                v_data_start --;
                v_data_end ++;
            }

            int new_amount_of_steps = 1 + (new_data_end - new_data_start) * steps_per_size;

            if ( ! (new_amount_of_steps == amount_of_steps && new_data_start == data_start) ) {


                //values.move (0, amount_of_steps - new_amount_of_steps, new_amount_of_steps);
                values.resize (new_amount_of_steps);

                //if (new_data_start + 1 == )
        int64 msec = GLib.get_real_time () / 1000;
                request_data (new_data_start * size_value, new_data_end * size_value, new_amount_of_steps, ref values, 0);
        int64 msec2 = GLib.get_real_time () / 1000;
        print (@"$new_amount_of_steps -> $(msec2 - msec) [$data_start -> $data_end]\n");
                data_start = new_data_start;
                data_end = new_data_end;
                amount_of_steps = new_amount_of_steps;
            }

            //values = new double[steps];
            //request_data (data_start, data_end, steps, ref values);

            var color_primary = get_style_context().get_color(ACTIVE);
            var color_secondary = get_style_context().get_color(FOCUSED);
            var color_accent = get_style_context().get_color(LINK);
            var color_text = get_style_context().get_color (LINK);

            get_style_context().lookup_color ("theme_selected_bg_color", out color_accent);
            get_style_context().lookup_color ("theme_fg_color", out color_primary);
            get_style_context().lookup_color ("insensitive_fg_color", out color_secondary);
            get_style_context().lookup_color ("theme_text_color", out color_text);


            cr.set_source_rgba (color_secondary.red, color_secondary.green, color_secondary.blue, color_secondary.alpha);
            cr.set_line_width (2);

            //draw lines
            // horizontal
            for (int i = 0; i < height / 2 / SIZE + 2; i ++) {
                cr.move_to (0, height / 2 + i * SIZE + shift_y % SIZE);
                cr.line_to (width, height / 2 + i * SIZE + shift_y % SIZE);

                cr.move_to (0, height / 2 - i * SIZE + shift_y % SIZE);
                cr.line_to (width, height / 2 - i * SIZE + shift_y % SIZE);
            }

            cr.stroke ();

            //vertical
            for (int i = 0; i < width / 2 / SIZE + 2; i ++) {
                cr.move_to (width / 2 + i * SIZE + shift_x % SIZE, 0);
                cr.line_to (width / 2 + i * SIZE + shift_x % SIZE, height);

                cr.move_to (width / 2 - i * SIZE + shift_x % SIZE, 0);
                cr.line_to (width / 2 - i * SIZE + shift_x % SIZE, height);
            }

            cr.stroke ();


            //draw text
            cr.set_font_size (10);
            cr.set_source_rgba (color_text.red, color_text.green, color_text.blue, color_text.alpha);

            // horizontal values
            int position_y = wrap (height / 2 + 10 + shift_y, 15, height - 10);
            for (int i = data_start; i <= data_end; i ++) {
                cr.move_to (i * SIZE + width / 2 + 5 + shift_x, position_y);
                cr.show_text (@"$(size_value * i)");
            }

            //vertical values
            int position_x = wrap (width / 2 + 5 + shift_x, 10, width - 20);
            for (int i = v_data_start; i <= v_data_end; i ++) {
                cr.move_to (position_x, height / 2 + i * SIZE - 5 + shift_y);
                cr.show_text (@"$(size_value * i)");
            }




            //draw main lines
            cr.set_line_width (4);

            cr.set_source_rgba (color_primary.red, color_primary.green, color_primary.blue, color_primary.alpha);

            cr.move_to (0, height / 2 + shift_y);
            cr.line_to (width, height / 2 + shift_y);

            cr.move_to (width / 2 + shift_x, 0);
            cr.line_to (width / 2 + shift_x, height);

            cr.stroke ();

            //draw graph
            cr.set_source_rgba (color_accent.red, color_accent.green, color_accent.blue, color_accent.alpha);
            cr.set_line_width (2);

            int horizontal_step_size = (int) (SIZE / steps_per_size);
            int start_line_position = (int) (((double) data_start - visible_data_start) * SIZE);

            cr.move_to (start_line_position, height / 2 - SIZE * values[0] / size_value + shift_y);


            for (int i = 1; i < amount_of_steps; i++) {
                if (values [i] != (0.0 / 0.0) && values [i] != (1.0 / 0.0) && values [i] != (-1.0 / 0.0) )
                    cr.line_to (start_line_position + i * horizontal_step_size, height / 2 - SIZE * values[i] / size_value + shift_y);
                else if (i + 1 < amount_of_steps) {
                    cr.move_to (start_line_position + (i + 1) * horizontal_step_size, height / 2 - SIZE * values[i + 1] / size_value + shift_y);

                }

            }

            cr.stroke ();

            return false;
        }

        public override bool button_press_event (Gdk.EventButton event) {
            dragging = true;
            drag_start_x = (int) event.x - shift_x;
            drag_start_y = (int) event.y - shift_y;
            return false;
        }

        public override bool button_release_event (Gdk.EventButton event) {
            dragging = false;
            return false;
        }


        public override bool motion_notify_event (Gdk.EventMotion event) {
            if (dragging) {
                shift_x = (int) event.x - drag_start_x;
                shift_y = (int) event.y - drag_start_y;
                queue_draw ();
                //print (@"$shift_x  $shift_y\n");
            }
            return false;
        }


    }
