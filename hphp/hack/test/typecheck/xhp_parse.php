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

function foo(): void {
  $z = <div> this is a' " # /// try </div>;
  $z = <div><h><p/> this is a' " # /// try </h></div>;
  $x = <div x="test" y ={'yea'}> ' "</div>;
  $y = <div/>;
  $z = <div><!-- an xhp comment </div>--></div>;
}

class :div extends XHPTest {
  attribute string x, string y;
}
class :h extends XHPTest implements XHPChild {}
class :p extends XHPTest implements XHPChild {}
