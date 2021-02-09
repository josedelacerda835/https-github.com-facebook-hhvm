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
#include "hphp/runtime/vm/verifier/pretty.h"

#include <iostream>
#include <iomanip>
#include <sstream>
#include <stdio.h>

#include <folly/Format.h>

#include "hphp/runtime/vm/repo.h"
#include "hphp/runtime/vm/verifier/util.h"
#include "hphp/runtime/vm/verifier/cfg.h"

#include "hphp/util/logger.h"

namespace HPHP {
namespace Verifier {

void pretty_print(const FuncEmitter* fe, std::ostream& out) {
  if (fe->pce() != nullptr) {
    out << "Method";
    Func::print_attrs(out, fe->attrs);
    if (fe->isMemoizeWrapper) out << " (memoize_wrapper)";
    if (fe->isMemoizeWrapperLSB) out << " (memoize_wrapper_lsb)";
    out << ' ' << fe->pce()->name()->data() << "::" << fe->name->data();
  } else {
    out << "Function";
    Func::print_attrs(out, fe->attrs);
    if (fe->isMemoizeWrapper) out << " (memoize_wrapper)";
    if (fe->isMemoizeWrapperLSB) out << " (memoize_wrapper_lsb)";
    out << ' ' << fe->name->data();
  }

  out << " at " << fe->base;
  out << std::endl;

  auto const& params = fe->params;
  for (uint32_t i = 0; i < params.size(); ++i) {
    auto const& param = params[i];
    out << " Param: " << fe->localNameMap()[i]->data();
    if (param.typeConstraint.hasConstraint()) {
      out << " " << param.typeConstraint.displayName();
    }
    if (param.userType) {
      out << " (" << param.userType->data() << ")";
    }
    if (param.funcletOff != kInvalidOffset) {
      out << " DV" << " at " << param.funcletOff;
      if (param.phpCode) {
        out << " = " << param.phpCode->data();
      }
    }
    out << std::endl;
  }

  if (fe->retTypeConstraint.hasConstraint() ||
      (fe->retUserType && !fe->retUserType->empty())) {
    out << " Ret: ";
    if (fe->retTypeConstraint.hasConstraint()) {
      out << " " << fe->retTypeConstraint.displayName();
    }
    if (fe->retUserType && !fe->retUserType->empty()) {
      out << " (" << fe->retUserType->data() << ")";
    }
    out << std::endl;
  }

  if (fe->repoReturnType.tag() != RepoAuthType::Tag::Cell) {
    out << "repoReturnType: " << show(fe->repoReturnType) << '\n';
  }
  if (fe->repoAwaitedReturnType.tag() != RepoAuthType::Tag::Cell) {
    out << "repoAwaitedReturnType: " << show(fe->repoAwaitedReturnType) << '\n';
  }
  out << "maxStackCells: " << fe->maxStackCells << '\n'
      << "numLocals: " << fe->numLocals() << '\n'
      << "numIterators: " << fe->numIterators() << '\n';

  auto const& ehtab = fe->ehtab;
  size_t ehId = 0;
  for (auto it = ehtab.begin(); it != ehtab.end(); ++it, ++ehId) {
    out << " EH " << ehId << " Catch for " <<
      it->m_base << ":" << it->m_past;
    if (it->m_parentIndex != -1) {
      out << " outer EH " << it->m_parentIndex;
    }
    if (it->m_iterId != -1) {
      out << " iterId " << it->m_iterId;
    }
    out << " handle at " << it->m_handler;
    if (it->m_end != kInvalidOffset) {
      out << ":" << it->m_end;
    }
    if (it->m_parentIndex != -1) {
      out << " parentIndex " << it->m_parentIndex;
    }
    out << std::endl;
  }
}

static void pretty_print(
  const UnitEmitter* ue,
  std::ostream& out,
  Offset startOffset,
  Offset stopOffset
) {
  std::map<Offset,const FuncEmitter*> funcMap;
  for (auto& func : ue->fevec()) {
    funcMap[func->base] = func.get();
  }
  for (Id i = 0; i < ue->numPreClasses(); i++) {
    for (auto fe : ue->pce(i)->methods()) {
      funcMap[fe->base] = fe;
    }
  }

  auto funcIt = funcMap.lower_bound(startOffset);

  const auto* it = &ue->bc()[startOffset];
  int prevLineNum = -1;
  while (it < &ue->bc()[stopOffset]) {
    auto fe = funcIt->second;
    assertx(funcIt == funcMap.end() || funcIt->first >= fe->offsetOf(it));
    if (funcIt != funcMap.end() && funcIt->first == fe->offsetOf(it)) {
      out.put('\n');
      pretty_print(fe, out);
      ++funcIt;
      prevLineNum = -1;
    }

    int lineNum = SourceLocation::getLineNumber(fe->lineTable(), fe->offsetOf(it));
    if (lineNum != prevLineNum) {
      out << "  // line " << lineNum << std::endl;
      prevLineNum = lineNum;
    }

    out << ' '
        << std::setw(4) << (it - ue->bc()) << ": "
        << instrToString(it, fe)
        << std::endl;
    it += instrLen(it);
  }
}

void printInstr(const FuncEmitter* func, PC pc) {
  std::cout << "  " << std::setw(4) << (pc - func->ue().bc()) << ":" <<
               (isCF(pc) ? "C":" ") <<
               (isTF(pc) ? "T":" ") <<
               std::setw(3) << instrLen(pc) <<
               " " << instrToString(pc, func) << std::endl;
}

std::string blockToString(const Block* b, const Graph*, const FuncEmitter* f) {
  std::stringstream out;
  out << "B" << b->id << ":"
      << f->offsetOf(b->start) <<
         "-" << f->offsetOf(b->last) <<
         " rpo=" << b->rpo_id <<
         " succ=";
  for (BlockPtrRange j = succBlocks(b); !j.empty(); ) {
    const Block* s = j.popFront();
    out << "B" << s->id << (j.empty() ? "" : ",");
  }
  if (b->exn) {
    out << " exn=B" << b->exn->id;
  }
  return out.str();
}

void printBlocks(const FuncEmitter* func, const Graph* g) {
  pretty_print(func, std::cout);
  for (LinearBlocks i(g->first_linear, 0); !i.empty(); i.popFront()) {
    const Block* b = i.front();
    std::cout << blockToString(b, g, func) << std::endl;
    for (InstrRange j(b->start, b->end); !j.empty(); ) {
      printInstr(func, j.popFront());
    }
  }
  std::cout << std::endl;
}

void printGml(const UnitEmitter* unit) {
  std::string filename = unit->sha1().toString() + ".gml";
  FILE* file = fopen(filename.c_str(), "w");
  if (!file) {
    std::cerr << "Couldn't open GML output file " << filename << std::endl;
    return;
  }
  int nextid = 1;
  fprintf(file, "graph [\n"
                "  hierarchic 1\n"
                "  directed 1\n");
  for (auto& func : unit->fevec()) {
    Arena scratch;
    GraphBuilder builder(scratch, func.get());
    const Graph* g = builder.build();
    int gid = nextid++;
    fprintf(file, "node [ isGroup 1 id %d ]\n", gid);
    // nodes
    for (LinearBlocks j = linearBlocks(g); !j.empty();) {
      const Block* b = j.popFront();
      std::stringstream strbuf;
      pretty_print(
        unit, strbuf, func->offsetOf(b->start), func->offsetOf(b->end)
      );
      std::string code = strbuf.str();
      for (int i = 0, n = code.size(); i < n; ++i) {
        if (code[i] == '"') code[i] = '\'';
      }
      fprintf(file, "  node [ id %d gid %d\n"
                    "    graphics [ type \"roundrectangle\" ]"
                    "    LabelGraphics ["
                    "      anchor \"e\""
                    "      alignment \"left\""
                    "      fontName \"Consolas\"\n"
                    "      text \"%s\"\n"
                    "    ]\n"
                    "  ]\n",
              nextid + b->id, gid, code.c_str());
    }
    // edges
    for (LinearBlocks j = linearBlocks(g); !j.empty();) {
      const Block* b = j.popFront();
      for (BlockPtrRange k = succBlocks(b); !k.empty();) {
        const Block* s = k.popFront();
        fprintf(file, "  edge [ source %d target %d ]\n",
                nextid + b->id, nextid + s->id);
      }
      if (b->exn) {
        fprintf(file, "  edge [ source %d target %d"
                      "    graphics [ style \"dotted\" ]"
                      "  ]\n",
                nextid + b->id, nextid + b->exn->id);
      }
    }
    nextid += g->block_count + 1;
  }
  fprintf(file, "]\n");
  fclose(file);
}

void verify_error(const UnitEmitter* unit,
                  const FuncEmitter* func,
                  bool throws,
                  const char* fmt,
                  ...) {
  char buf[1024];
  va_list args;
  va_start(args, fmt);
  vsnprintf(buf, sizeof buf, fmt, args);
  va_end(args);
  auto out = folly::sformat(
    "Verification Error (unit {}{}{}{}{}): {}",
    unit->m_filepath->data(),
    func ? " func " : "",
    func && func->pce() ? func->pce()->name()->data() : "",
    func && func->pce() ? "::" : "",
    func ? func->name->data() : "",
    buf
  );
  if (throws) {
    throw std::runtime_error(out);
  }
  Logger::Error(out);
}

}} // namespace HPHP::VM
