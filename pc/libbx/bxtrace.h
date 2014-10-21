// bxtrace.h ---------------------------------------------------------
//
// Copyright (c) 2001 to 2012  te
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------
#ifndef bxtraceH
#define bxtraceH

#define _CRT_SECURE_NO_WARNINGS       // must be before stdio, etc

namespace glob {
  #if defined(_DEBUGxxx)

    #include <stdio.h>
    #include <stdarg.h>

    #include "bxdefs.h"               // for LOOKS_LIKE_WINDOWS

    #if defined(LOOKS_LIKE_WINDOWS)
      #include <io.h>
    #endif

    #define FNAME "bxtrce.txt"

    void Tr(const char *format, ...) {
      va_list argptr;
      va_start(argptr, format);
      FILE *f = fopen(FNAME, "at");   // could fail
      if (f) {
        fprintf(f, "\n");
        vfprintf(f, format, argptr);
        fclose(f);
        }
      va_end(argptr);
      }
  #else
    void traceOn() {}
    void traceOff() {}
    void Tr(const char *format, ...) {}
  #endif
  }

#endif
// EOF ----------------------------------------------------------------
