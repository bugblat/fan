#ifndef GFILE_H
#define GFILE_H

#include <stdio.h>

#include "gexport.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct G_FILE G_FILE;

GIDEROS_API G_FILE* g_fopen(const char* filename, const char* mode);
GIDEROS_API int g_fclose(G_FILE* file);
GIDEROS_API size_t g_fread(void* dst, size_t size, size_t count, G_FILE* file);
GIDEROS_API int g_getc(G_FILE* file);
GIDEROS_API int g_ungetc(int ch, G_FILE* file);
GIDEROS_API int g_feof(G_FILE* file);
GIDEROS_API int g_ferror(G_FILE* file);
//G_FILE* g_freopen(const char* filename, const char* mode, G_FILE* file);
GIDEROS_API char* g_fgets(char* buf, int maxcount, G_FILE* file);
GIDEROS_API void g_clearerr(G_FILE* file);
GIDEROS_API size_t g_fwrite(const void* str, size_t size, size_t count, G_FILE* file);
GIDEROS_API int g_fseek(G_FILE* file, long offset, int origin);
GIDEROS_API long g_ftell(G_FILE* file);
GIDEROS_API int g_setvbuf(G_FILE* file, char* buf, int mode, size_t size);
GIDEROS_API int g_fflush(G_FILE* file);
GIDEROS_API G_FILE* g_tmpfile();
GIDEROS_API int g_fscanf(G_FILE* file, const char* format, ...);
GIDEROS_API int g_fprintf(G_FILE* file, const char* format, ...);

GIDEROS_API extern G_FILE* g_stdin;
GIDEROS_API extern G_FILE* g_stdout;
GIDEROS_API extern G_FILE* g_stderr;

GIDEROS_API const char* g_pathForFile(const char* filename);

#ifdef __cplusplus
}
#endif

#endif
