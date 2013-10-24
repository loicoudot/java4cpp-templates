#include <stdlib.h>
#include <map>
#include <string>
#include "jni.h"
#include "jvm_launcher.h"
#include "java4cpp_runtime.h"
#include "java_exceptions.h"

// classes cache TODO: move to templates
typedef std::map<std::string, jclass> ClassMap;
ClassMap classMap;

// methods cache TODO: move to templates
typedef std::map<std::string, jmethodID> SignatureMethodMap;
typedef std::map<jclass, SignatureMethodMap> MethodMap;
MethodMap methodMap;
MethodMap staticMethodMap;

// fields cache TODO: move to templates
typedef std::map<std::string, jfieldID> SignatureFieldMap;
typedef std::map<jclass, SignatureFieldMap> FieldMap;
FieldMap fieldMap;

JNIEnv *Java4CppRuntime::attachCurrentThread()
{
   if(getJVM())
   {
      JNIEnv *javaEnv;
      getJVM()->AttachCurrentThread((void**)&javaEnv, NULL);
      return javaEnv;
   }
   return NULL;
}

void Java4CppRuntime::handleJavaException(JNIEnv *javaEnv)
{
   if(!javaEnv)
      return;

   jthrowable exc = javaEnv->ExceptionOccurred();
   if( exc )
   {
      javaEnv->ExceptionClear();
      convertJThrowableToException(javaEnv, exc);
   }
}

jclass Java4CppRuntime::getClass(JNIEnv *javaEnv, const char* cls)
{
   ClassMap::iterator clsIter = classMap.find(cls);

   if( clsIter != classMap.end() )
      return clsIter->second;

   jclass localRefCls = javaEnv->FindClass(cls);
   if( localRefCls == NULL )
      return NULL;

   jclass globalRefCls = (jclass)javaEnv->NewGlobalRef(localRefCls);
   javaEnv->DeleteLocalRef(localRefCls);

   classMap[cls] = globalRefCls;
   return globalRefCls;
}

jmethodID Java4CppRuntime::getMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature)
{
   SignatureMethodMap& signatures = methodMap[cls];
   SignatureMethodMap::iterator sgnIter = signatures.find(std::string(name)+signature);
   if( sgnIter != signatures.end() )
      return sgnIter->second;

   jmethodID localRefMid = javaEnv->GetMethodID(cls, name, signature);

   signatures[std::string(name)+signature] = localRefMid;
   return localRefMid;
}

jmethodID Java4CppRuntime::getStaticMethodID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature)
{
   SignatureMethodMap& signatures = staticMethodMap[cls];
   SignatureMethodMap::iterator sgnIter = signatures.find(std::string(name)+signature);
   if( sgnIter != signatures.end() )
      return sgnIter->second;

   jmethodID localRefMid = javaEnv->GetStaticMethodID(cls, name, signature);

   signatures[std::string(name)+signature] = localRefMid;
   return localRefMid;
}

jfieldID Java4CppRuntime::getFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature)
{
   SignatureFieldMap& signatures = fieldMap[cls];
   SignatureFieldMap::iterator sgnIter = signatures.find(name);
   if( sgnIter != signatures.end() )
      return sgnIter->second;

   jfieldID localRefFid = javaEnv->GetFieldID(cls, name, signature);

   signatures[name] = localRefFid;
   return localRefFid;
}

jfieldID Java4CppRuntime::getStaticFieldID(JNIEnv *javaEnv, jclass cls, const char* name, const char* signature)
{
   SignatureFieldMap& signatures = fieldMap[cls];
   SignatureFieldMap::iterator sgnIter = signatures.find(name);
   if( sgnIter != signatures.end() )
      return sgnIter->second;

   jfieldID localRefFid = javaEnv->GetStaticFieldID(cls, name, signature);

   signatures[name] = localRefFid;
   return localRefFid;
}
