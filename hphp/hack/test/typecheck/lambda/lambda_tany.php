<?hh
// Copyright 2004-present Facebook. All Rights Reserved.

class B {
  public function foo(): void {}
}
class C extends B {
  public function foo(): void {}
}

function test_tany(/* TAny */ $y): void {
  $f = $x ==> $x->foo();
  $f($y);
  $f(new C());
}

function break_it(): void {
  test_tany(new B());
}
