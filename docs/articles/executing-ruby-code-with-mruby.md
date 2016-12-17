---
layout: post
title: Executing Ruby code with mruby
categories: articles
---

# Executing Ruby code with mruby

**originally written by [Daniel Bovensiepen](http://bovensiepen.net/)**

The traditional way to execute Ruby code is distributing the plain source code
and requiring a Ruby interpreter with lots of files to be installed.
mruby can be used like that too. So if you have experience with
another Ruby implementation you may know some of the examples listed here.
However with mruby you can also build standalone programs and compile to
bytecode which can be dumped and loaded.

A file called `test_program.rb` is used in some of the examples. Its content is:

~~~ruby
puts 'hello world'
~~~

## REPL (mirb)

Not exactly directly used for program execution but still,
Ruby code can be evaluated by using the `mirb` program:

~~~
$ mruby/bin/mirb
mirb - Embeddable Interactive Ruby Shell

> puts 'hello world'
hello world
 => nil
~~~

### Pros & Cons

✔ direct feedback without any indirection like files

✘ not usable for productive execution

✘ the input needs to be parsed twice: first `mirb` checks if the code is
complete and afterwards `mirb` compiles it into bytecode and executes it

## Source code (.rb)

The probably most common way to run Ruby code is by passing a filename as
argument to an interpreter. In mruby that's the `mruby` program:

~~~
$ mruby/bin/mruby test_program.rb
hello world
~~~

### Pros & Cons

✔ very simple development cycle: programming → testing → programming

✘ Ruby code has to be provided to users

✘ the `mruby` program and a file system is required

✘ Ruby code has to be parsed and compiled to bytecode before its execution

## Source code (.c)

Ruby code can also be written as a C string. This is similar to
the `-e` switch of the `mruby` program.

~~~c
#include <mruby.h>
#include <mruby/compile.h>

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) { /* handle error */ }
  // mrb_load_nstring() for strings without null terminator or with known length
  mrb_load_string(mrb, "puts 'hello world'");
  mrb_close(mrb);
  return 0;
}
~~~

To compile and link:

~~~
$ gcc -std=c99 -Imruby/include test_program.c -o test_program mruby/build/host/lib/libmruby.a -lm
~~~

To execute:

~~~
$ ./test_program
hello world
~~~

### Pros & Cons

✔ simple development cycle:
programming → compiling (`gcc`) → testing → programming

✔ the program is fully standalone

✘ additional boilerplate is needed to get the program up and running

✘ Ruby code has to be parsed and compiled to bytecode before its execution

✘ updating the Ruby code might require a recompilation of the C code or
an advanced updating mechanism

## Bytecode (.mrb)

mruby provides a Java-like execution style by compiling to an
intermediate representation form which will then be executed.

The first step is to compile the source code to bytecode with the `mrbc` program:

~~~
$ mruby/bin/mrbc test_program.rb
~~~

This will produce a file called `test_program.mrb` which contains the
intermediate representation of the previously given Ruby code:

~~~
$ hexdump -C test_program.mrb
00000000  52 49 54 45 30 30 30 33  e1 c0 00 00 00 65 4d 41  |RITE0003.....eMA|
00000010  54 5a 30 30 30 30 49 52  45 50 00 00 00 47 30 30  |TZ0000IREP...G00|
00000020  30 30 00 00 00 3f 00 01  00 04 00 00 00 00 00 04  |00...?..........|
00000030  00 80 00 06 01 00 00 3d  00 80 00 a0 00 00 00 4a  |.......=.......J|
00000040  00 00 00 01 00 00 0b 68  65 6c 6c 6f 20 77 6f 72  |.......hello wor|
00000050  6c 64 00 00 00 01 00 04  70 75 74 73 00 45 4e 44  |ld......puts.END|
00000060  00 00 00 00 08                                    |.....|
00000065
~~~

This file can be executed by the `mruby` program or the `mrb_load_irep_file()`
function. The `-b` switch tells the program that the file is bytecode rather than
plain Ruby code:

~~~
$ mruby/bin/mruby -b test_program.mrb
hello world
~~~

### Pros & Cons

✔ Ruby code doesn't have to be provided to users

✔ no Ruby code has to be parsed

✔ bytecode can easily be updated by replacing the .mrb file

✘ complex development cycle:
programming → compiling (`mrbc`) → testing (`mruby`) → programming

✘ the `mruby` program and a file system is required

## Bytecode (.c)

This variant is interesting for those who want to integrate Ruby code directly
into their C code. It will create a C array containg the bytecode which you
then have to execute by yourself.

The first step is to compile the Ruby program. This is done by using `mrbc`
and its `-B` switch. An identifier for the array also has to be given:

~~~
$ mruby/bin/mrbc -Btest_symbol test_program.rb
~~~

This creates a file called `test_program.c` containing the `test_symbol` array:

~~~c
/* dumped in little endian order.
   use `mrbc -E` option for big endian CPU. */
#include <stdint.h>
const uint8_t
#if defined __GNUC__
__attribute__((aligned(4)))
#elif defined _MSC_VER
__declspec(align(4))
#endif
test_symbol[] = {
0x45,0x54,0x49,0x52,0x30,0x30,0x30,0x33,0x73,0x0d,0x00,0x00,0x00,0x65,0x4d,0x41,
0x54,0x5a,0x30,0x30,0x30,0x30,0x49,0x52,0x45,0x50,0x00,0x00,0x00,0x47,0x30,0x30,
0x30,0x30,0x00,0x00,0x00,0x3f,0x00,0x01,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x04,
0x06,0x00,0x80,0x00,0x3d,0x00,0x00,0x01,0xa0,0x00,0x80,0x00,0x4a,0x00,0x00,0x00,
0x00,0x00,0x00,0x01,0x00,0x00,0x0b,0x68,0x65,0x6c,0x6c,0x6f,0x20,0x77,0x6f,0x72,
0x6c,0x64,0x00,0x00,0x00,0x01,0x00,0x04,0x70,0x75,0x74,0x73,0x00,0x45,0x4e,0x44,
0x00,0x00,0x00,0x00,0x08,
};
~~~

To execute this bytecode the following boilerplate has to be written (name this
file `test_stub.c`):

~~~c
#include <mruby.h>
#include <mruby/irep.h>
#include <test_program.c>

int
main(void)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) { /* handle error */ }
  mrb_load_irep(mrb, test_symbol);
  mrb_close(mrb);
  return 0;
}
~~~

This will read the bytecode from the array and executes it immediately:

To compile and link:

~~~
$ gcc -std=c99 -Imruby/include test_stub.c -o test_program mruby/build/host/lib/libmruby.a -lm
~~~

To execute:

~~~
$ ./test_program
hello world
~~~

### Pros & Cons

✔ Ruby code doesn't have to be provided to users

✔ no Ruby code has to be parsed

✔ the program is fully standalone

✘ even more complex development cycle: programming → compiling (`mrbc`) →
integrating C code → compiling (`gcc`) → testing → programming

✘ additional boilerplate is needed to get the program up and running

✘ updating the bytecode requires a recompilation of the C code or
an advanced updating mechanism

## Fazit

The **REPL (mirb)** is mainly used during the early development.
**Source code (.rb)** is the most common usage of mruby these
days as it emphasises Ruby as a scripting language which can easily be
modified by changing the source code on the machine. **Source code (.c)**
is the easiest step to embed mruby into your own application.
**Bytecode (.mrb)** provides the feeling of a Java application, which can
be file based installed but doesn't provide access to the source code.
**Bytecode (.c)** is quite likely for many people the most complex way to
use mruby but at the same time it provides the most efficient way to
execute mruby code inside of program.
