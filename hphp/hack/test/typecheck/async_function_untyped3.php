<?hh

function takes_int(int $x): void {}

async function f() /* : TAny */ {
  return 10;
}

function test(): int {
  $val = f();
  takes_int($val);
  return $val;
}
