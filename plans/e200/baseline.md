# Baseline test results (M0)

Recorded before any LLVM source change on branch `ppc-e200-vle`
(sources identical to upstream `24b1941da3f6`).

Build configuration (`build-e200`):

```
cmake -S llvm -B build-e200 -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="clang;lld;lldb" \
  -DLLVM_TARGETS_TO_BUILD="PowerPC;X86" -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_USE_LINKER=lld -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DLLDB_ENABLE_PYTHON=OFF -DLLDB_ENABLE_LIBEDIT=OFF -DLLDB_ENABLE_CURSES=OFF \
  -DLLDB_ENABLE_LUA=OFF -DLLDB_INCLUDE_TESTS=OFF -DLLVM_PARALLEL_LINK_JOBS=6
```

Host: 16 cores, Ubuntu clang 18.1.3, CMake 3.28.3, Ninja, ccache.
LLDB is configured without Python, libedit and curses (no swig/libedit on
the host), so LLDB API tests are unavailable; LLDB unit tests are used.

- check-llvm: 80,370 discovered; 43,931 passed, 35,970 unsupported,
  393 skipped, 76 expectedly failed, 0 failed.
- check-clang: 55,768 discovered; 50,770 passed, 4,958 unsupported,
  11 skipped, 29 expectedly failed, 0 failed.
- check-lld: 3,255 discovered; 2,172 passed, 1,082 unsupported,
  1 expectedly failed, 0 failed.

Any failure in these suites after a change is a regression and blocks the
milestone.
