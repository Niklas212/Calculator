calculator_sources = [
  'main.vala',
  'fun.vala',
  'Widgets.vala',
  'Collect.gs',
  'Logic/Calcu_Logic.vala',
  'Logic/Default_Values.vala',
  'Logic/Collection.gs',
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
