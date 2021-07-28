# Calculator
this is a simple Calculator written in Gtk and Vala/Genie

![Calculator](https://github.com/Niklas212/niklas212.github.io/blob/master/res/Calculator/Calculator_new.png)

![Graph](https://github.com/Niklas212/niklas212.github.io/blob/master/res/Calculator/Graph_new.png)

### Features
* perform arithmetic calculations
* define variables and functions
* display functions graphically

### Installation
**This works only on Linux**
#### Dependencies
- [meson](https://mesonbuild.com/Quick-guide.html)
- valac
- [gtk](https://www.gtk.org/docs/installations/)
- a c compiler
1. clone this repository
2. change the directory to this folder
3. create a build folder: ```meson build --prefix=/usr``` (type the command in the terminal)
4. change the directory to the created build folder: ```cd build```
5. install: ```sudo ninja install ```
