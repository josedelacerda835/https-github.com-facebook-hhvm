//// f1.php
<?hh

class CamelCase {
  final public function foo(int $x): void {}
}

//// f2.php
<?hh
function foo(cAmelCase $arg): :xhp {
  expect_CamelCase($arg);
  $v = ret();
  expect_CamelCase($v);
  return new :xhp();
}

function ret(): camelcase {
  return new cAMELcASE();
}

function expect_CamelCase(CamelCase $x):void {}

class :xhp {}
