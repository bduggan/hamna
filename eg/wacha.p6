#!/usr/bin/env perl6

use lib 'lib';
use Wacha;

/ 'hello world';

/hello/:name -> $/ { "hello, $<name>" }

go;
