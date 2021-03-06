//// file1.php
<?hh

class BarImpl implements IMemoizeParam {
  public function getInstanceKey(): string {
    return "dummy";
  }
}

newtype Bar = varray<varray<BarImpl>>;

//// file2.php
<?hh
class Foo {
  <<__Memoize>>
  public function someMethod(Bar $i): void {}
}

<<__Memoize>>
function some_function(Bar $i): void {}
