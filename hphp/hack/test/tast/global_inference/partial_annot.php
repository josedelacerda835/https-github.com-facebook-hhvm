//// file1.php
<?hh

/* HH_FIXME[4101] */
function foo(A $x) {
  return $x->get();
}

//// file2.php
<?hh

class A<T super string> {
  public function get(): ?T {
    return null;
  }
}
