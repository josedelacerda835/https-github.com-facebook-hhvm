<?hh
/**
 * Copyright (c) 2014, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *
 */

function foo(A $a): int {
  $p = inst_meth($a, 'f1');
  return $p('moo');
}

class A {
  public function f1(string $s): int {
    return 0;
  }
}
