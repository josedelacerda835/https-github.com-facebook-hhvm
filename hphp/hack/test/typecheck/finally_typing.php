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

function finally_typing1(): string {
  $a = 23;
  try {
    do_something();
  } finally {
    $a = 'string'; // this definition escapes the clause
  }
  return $a;
}

function finally_typing2(): string {
  $a = 23;
  try {
    do_something();
    return 'string';
  } finally {
    // this definition escapes the clause, even with terminality
    $a = 'string';
  }
  return $a;
}

// with a different story with respect to unreachable code ...
// function finally_typing3(): int {
//   $a = 23;
//   try {
//     do_something();
//     $a = 25;
//     return $a; // terminal block
//   } finally {
//     // this assignment beats out the original, but it doesn't matter
//     // because the try is fully terminal
//     $a = 'string';
//   }
//   return $a;
// }

function do_something(): void {}

function finally_typing3(bool $c): int {
  try {
    try {
      if ($c) {
        $a = "string";
        throw new Exception();
      }
      $a = 0;
    } finally {
      // $a has different types depending on the continuation
      $b = $a;
    }
  } catch (Exception $_) {
    // $b should be a string here
    return str_to_int($b);
  }
  return $b;
}

function str_to_int(string $s): int {
  return 0;
}

function finally_typing4(int $x): void {
  $a = 0;
  try {
    try {
      if ($x < 0) {
        throw new Exception();
      }
    } finally {
      if ($x < 1) {
        $a = "string";
        throw new Exception();
      }
      $a = 1;
    }
  } catch (Exception $_) {
    hh_show($a);
    return;
  }
  hh_show($a);
}
