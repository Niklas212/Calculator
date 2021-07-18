using Gtk;
using Cairo;

using Calculation;


public class FunctionGraph : DrawingArea {


        // relativ to lines
        private double data_start = 0;
        private double data_end = 0;
        private bool calculating_required = false;

        private int steps_per_size = 10;
        private int pixels_per_step = 4;
        private int amount_of_steps = 0;
        private double[] values;
        private int SIZE = 40;
        private int size = 40;
        private float zoom_factor = 1;
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

            size = (int) (SIZE * zoom_factor);


            if (zoom_factor < 1) {
                int x = SIZE / size;

                x = next_zoom_value (x);

                size_value = x;
                size *= x;

                print (@"zoom:$zoom_factor\t$x\n");
            } else {
                int x = size / SIZE;

                x = next_zoom_value (x);

                size_value = 1.0 / x;
                size /= x;

                print (@"zoom:$zoom_factor\t$x\t$size_value\n");
            }


            int pixel_start = -width / 2 - shift_x;
            int pixel_end = width / 2 - shift_x;

            double new_data_start = (double) pixel_start / (double) size * (double) size_value;
            double new_data_end = (double) pixel_end / (double) size * (double) size_value;

            int required_steps = (pixel_end - pixel_start) / pixels_per_step + 1;

            int new_amount_of_steps = required_steps;
            if ( (! (new_amount_of_steps == amount_of_steps && new_data_start == data_start)) || calculating_required) {

                calculating_required = false;
                values.resize (new_amount_of_steps);


                int64 msec = GLib.get_real_time ();
                request_data (new_data_start, new_data_end, new_amount_of_steps, ref values, 0);
                int64 msec2 = GLib.get_real_time ();
                print (@"$new_amount_of_steps -> $(msec2 - msec) [$data_start -> $data_end]\n");
                data_start = new_data_start;
                data_end = new_data_end;
                amount_of_steps = new_amount_of_steps;
            }

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
            for (int i = 0; i < height / 2 / size + 2; i ++) {
                cr.move_to (0, height / 2 + i * size + shift_y % size);
                cr.line_to (width, height / 2 + i * size + shift_y % size);

                cr.move_to (0, height / 2 - i * size + shift_y % size);
                cr.line_to (width, height / 2 - i * size + shift_y % size);
            }

            cr.stroke ();

            //vertical
            for (int i = 0; i < width / 2 / size + 2; i ++) {
                cr.move_to (width / 2 + i * size + shift_x % size, 0);
                cr.line_to (width / 2 + i * size + shift_x % size, height);

                cr.move_to (width / 2 - i * size + shift_x % size, 0);
                cr.line_to (width / 2 - i * size + shift_x % size, height);
            }

            cr.stroke ();


            //draw text
            cr.set_font_size (10);
            cr.set_source_rgba (color_text.red, color_text.green, color_text.blue, color_text.alpha);

            // horizontal values
            int h_data_start = pixel_start / size;
            int h_data_end = pixel_end / size;

            int position_y = wrap (height / 2 + 10 + shift_y, 15, height - 10);

            for (int i = h_data_start; i <= h_data_end; i ++) {
                cr.move_to (i * size + 5 + shift_x + width / 2, position_y);
                cr.show_text (@"$(i * size_value)");
            }

            //vertical values

            int v_data_start = (-height / 2 - shift_y) / size;
            int v_data_end = (height / 2 - shift_y) / size;

            int position_x = wrap (width / 2 + 5 + shift_x, 10, width - 20);

            for (int i = v_data_start; i <= v_data_end; i ++) {
                cr.move_to (position_x, height / 2 + i * size - 5 + shift_y);
                cr.show_text (@"$(i * size_value)");
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


            double horizontal_step_size = (double) (pixel_end - pixel_start) / (double) amount_of_steps;
            cr.move_to (0, height / 2 - size * values[0] / size_value + shift_y);

            for (int i = 1; i < amount_of_steps; i++) {
                if (values [i] != (0.0 / 0.0) && values [i] != (1.0 / 0.0) && values [i] != (-1.0 / 0.0) )
                    cr.line_to (i * horizontal_step_size, height / 2 - size * values[i] / size_value + shift_y);
                else if (i + 1 < amount_of_steps) {
                    cr.move_to ((i + 1) * horizontal_step_size, height / 2 - size * values[i + 1] / size_value + shift_y);

                }

            }

            cr.stroke ();

            return false;
        }

        public void default_zoom_in () {
            zoom ( (float) 0.1 * -1);
        }

        public void default_zoom_out () {
            zoom ( (float) 0.1);
        }

        public void zoom (float value) {
            zoom_factor += value;

            if (zoom_factor < 0.1)
                zoom_factor = (float) 0.1;

            // force redraw
            calculating_required = true;
            queue_draw ();
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
