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

function meh_for(int $i): void {
  $x = $i;
  for( ; $x = 1, $x = "hello"; $i++) {
    $i %= $x;
  }
}
