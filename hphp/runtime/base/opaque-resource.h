/*
   +----------------------------------------------------------------------+
   | HipHop for PHP                                                       |
   +----------------------------------------------------------------------+
   | Copyright (c) 2010-present Facebook, Inc. (http://www.facebook.com)  |
   +----------------------------------------------------------------------+
   | This source file is subject to version 3.01 of the PHP license,      |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | http://www.php.net/license/3_01.txt                                  |
   | If you did not receive a copy of the PHP license and are unable to   |
   | obtain it through the world-wide-web, please send a note to          |
   | license@php.net so we can mail you a copy immediately.               |
   +----------------------------------------------------------------------+
*/

#pragma once

#include "hphp/runtime/base/type-resource.h"
#include "hphp/runtime/base/type-string.h"
#include "hphp/runtime/base/type-variant.h"

namespace HPHP {
///////////////////////////////////////////////////////////////////////////////

struct OpaqueResource : ResourceData {
  OpaqueResource(int64_t id, Variant val) : m_id(id), m_value(val) {}
  virtual ~OpaqueResource() = default;
  const String& o_getClassNameHook() const override {
    static StaticString OpaqueValue("OpaqueValue");
    return OpaqueValue;
  }
  int64_t opaqueId() const { return m_id; }
  Variant opaqueValue() const { return m_value; }
private:
  int64_t m_id;
  Variant m_value;
};

}
