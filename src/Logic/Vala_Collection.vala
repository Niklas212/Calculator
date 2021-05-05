public struct Replaceable {
    public string[] key;
    public double[] value;

    public void add_variable(string _key, double _value, bool _override = false) throws Calculation.CALC_ERROR {
        if (_key in key || _key in get_variable().key) {
            if (_key in get_variable().key || !_override)
                throw new Calculation.CALC_ERROR.UNKNOWN(@"'$(_key)' is already defined");
            if (_override) {
                for (int i = 0; i < key.length; i++ )
                    if (key[i] == _key) {
                        key[i] = _key;
                        value[i] = _value;
                        return;
                    }
            }
        }

        var values = value;
        var keys = key;

        values += _value;
        keys += _key;

        key = keys;
        value = values;
    }

    public int remove_variable(string _name) throws Calculation.CALC_ERROR {
        int index = -1;
        if (_name in key) {
            string[] keys = {};
            double[] values = {};

            if (key.length == 1) {
                key = keys;
                value = values;
                return 0;
            }

            for (int i = 0; i < key.length; i++) {
                if (key[i] != _name) {
                    keys += key[i];
                    values += value[i];
                } else {
                    index = i;
                }
            }

            print("###start###\n");
            key = keys;
            value = values;
            print("###end###\n");
            return index;
        }

         else {
            throw new Calculation.CALC_ERROR.UNKNOWN(@"the variable '$_name' does not exist");
        }
    }
}
