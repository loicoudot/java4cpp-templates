#ifndef JAVA_EXCEPTIONS_H
#define JAVA_EXCEPTIONS_H

#include "java4cpp_defs.h"
#include "jni.h"

_JAVA4CPPFUNC void convertJThrowableToException( JNIEnv *javaEnv, jthrowable exc);

#endif
