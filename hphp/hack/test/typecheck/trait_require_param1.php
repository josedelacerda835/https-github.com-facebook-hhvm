<?hh

abstract class Foo<T> {
  protected function bar(): T {
    throw new Exception();
  }
}

trait Tbaz {
  require extends Foo<int>;

  protected function f(): void {
    $int = $this->bar();
    f_takes_int($int);
  }
}

function f_takes_int(int $f): void {}
