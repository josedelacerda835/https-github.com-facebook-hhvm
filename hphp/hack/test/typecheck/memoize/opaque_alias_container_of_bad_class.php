//// file1.php
<?hh

class BarImpl {
}

newtype Bar = varray<BarImpl>;

//// file2.php
<?hh
class Foo {
  <<__Memoize>>
  public function someMethod(Bar $i): void {}
}
