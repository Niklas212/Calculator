calculator_sources = [
  'main.vala',
  'Widgets.vala',
  'funs.gs',
  'Logic/Calcu_Logic.vala',
  'Logic/Default_Values.vala',
  'Logic/Collection.gs',
  'Widgets/AddCustomDialog.vala',
  'Widgets/CustomFlowBox.vala',
  'Widgets/Graphics.vala',
]

calculator_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  meson.get_compiler('c').find_library('m', required: false),
]

gnome = import('gnome')

calculator_sources += gnome.compile_resources('calculator-resources',
  'calculator.gresource.xml',
  c_name: 'calculator'
)

executable('calculator', calculator_sources,
  vala_args: '--target-glib=2.50',  dependencies: calculator_deps,
  install: true,
)
