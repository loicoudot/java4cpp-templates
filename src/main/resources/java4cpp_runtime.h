#ifndef JAVA4CPP_RUNTIME_H
#define JAVA4CPP_RUNTIME_H

#include <string>
#include "java4cpp_defs.h"
#include "jni.h"

class _JAVA4CPPCLASS Java4CppRuntime {
  public:
    // Gestion JNIEnv
    static JNIEnv *attachCurrentThread();
    static void handleJavaException(JNIEnv *javaEnv);

    // Gestion de la conversion std::string <=> String
    static jstring newStringNative(JNIEnv *javaEnv, const std::string& str);
    static std::string getStringNativeChars(JNIEnv *javaEnv, jstring jstr);

    static jclass getClass(JNIEnv *javaEnv, const char* cls);
    static jmethodID getMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jmethodID getStaticMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jfieldID getFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
    static jfieldID getStaticFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature);
};

#endif
