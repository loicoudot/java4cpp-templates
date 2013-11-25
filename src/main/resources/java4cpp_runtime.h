#ifndef JAVA4CPP_RUNTIME_H
#define JAVA4CPP_RUNTIME_H

#include "jni.h"

class Java4CppRuntime
{
public:
   static JNIEnv *attachCurrentThread();
   static void handleJavaException(JNIEnv *javaEnv);

   static jclass getClass(JNIEnv *javaEnv, const char* cls);
   static jmethodID getMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
   static jmethodID getStaticMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
};

#endif
