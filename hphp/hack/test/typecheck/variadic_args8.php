<?hh

function takes_string(string $s): void {}

function f(int ...$args): void {
  foreach ($args as $arg) {
    takes_string($arg);
  }
}

function test(): void {
  f('str', 'str', 20);
}
