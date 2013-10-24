#ifndef JAVA_EXCEPTIONS_H
#define JAVA_EXCEPTIONS_H

#include "jni.h"

void convertJThrowableToException( JNIEnv *javaEnv, jthrowable exc);

#endif
