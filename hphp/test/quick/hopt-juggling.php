<?hh

function foo1() {
  $x = true;
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) + HH\Lib\Legacy_FIXME\cast_for_arithmetic(true);
}

function foo2() {
  $x = true;
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) + HH\Lib\Legacy_FIXME\cast_for_arithmetic(null);
}

function foo3() {
  $x = "5";
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) + 3;
}

function foo4() {
  $x = true;
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) - HH\Lib\Legacy_FIXME\cast_for_arithmetic(true);
}

function foo5() {
  $x = true;
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) * HH\Lib\Legacy_FIXME\cast_for_arithmetic(true);
}

function foo6() {
  $x = "13";
  return (int)($x) ^ 6;
}

function foo7() {
  $x = "7";
  return (int)$x & (int)false;
}

function foo8() {
  $x = "4";
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) * HH\Lib\Legacy_FIXME\cast_for_arithmetic("6");
}

function foo9() {
  $x = "3";
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) - HH\Lib\Legacy_FIXME\cast_for_arithmetic(null);
}

function foo10($x) {
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) + HH\Lib\Legacy_FIXME\cast_for_arithmetic("10");
}

function foo11($x, $y) {
  return HH\Lib\Legacy_FIXME\cast_for_arithmetic($x) + HH\Lib\Legacy_FIXME\cast_for_arithmetic($y);
}

function foo12() {
  $x = varray[];
  return (int)$x;
}

function foo13() {
  $x = varray[1,2,3];
  return (int)$x;
}
<<__EntryPoint>> function main(): void {
var_dump(foo1());
var_dump(foo2());
var_dump(foo3());
var_dump(foo4());
var_dump(foo5());
var_dump(foo6());
var_dump(foo7());
var_dump(foo8());
var_dump(foo9());
var_dump(foo10(6));
var_dump(foo11(4, true));
var_dump(foo12());
var_dump(foo13());
}
