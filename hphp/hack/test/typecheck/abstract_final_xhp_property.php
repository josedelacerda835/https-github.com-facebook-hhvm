<?hh
abstract final class :foo {
  attribute string foobar;
}
class :bar {
  attribute :foo;
}
