<?hh
// Copyright 2004-present Facebook. All Rights Reserved.

function f(bool $b, /* TAny */ $a): void {
  hh_show(() ==> {
    if ($b) {
      return;
    } else {
      return $a;
    }
  });
}

function v(): void {}
