#ifndef JAVA4CPP_RUNTIME_H
#define JAVA4CPP_RUNTIME_H

#include "java4cpp_defs.h"
#include "jni.h"

class _JAVA4CPPCLASS Java4CppRuntime {
  public:
    static JNIEnv *attachCurrentThread();
    static void handleJavaException(JNIEnv *javaEnv);

    static jclass getClass(JNIEnv *javaEnv, const char* cls);
    static jmethodID getMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jmethodID getStaticMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jfieldID getFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jfieldID getStaticFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
};

#endif
