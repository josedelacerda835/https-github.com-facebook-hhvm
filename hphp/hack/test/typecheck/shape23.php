<?hh

/**
 * Structural subtyping of ad-hoc shapes
 */

type t = shape(
  'x' => int,
  ...
);

function test(t $s): t {
  return shape('x' => 4, 'y' => 'aaa');
}
