<?hh
function foo() {
  return 5;
}
function test() : varray<int> {
  $x = foo();
  /* HH_IGNORE_ERROR[2049] */ hh_show($x);
  $y = varray[];
  $y[] = $x;
  /* HH_IGNORE_ERROR[2049] */ hh_show($y);
  return $y;
}
