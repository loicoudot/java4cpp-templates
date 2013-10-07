#include <stdlib.h>
#include <map>
#include "jni.h"
#include "java4cpp_runtime.h"
#include "javawrapper.h"
#include "java_exceptions.h"

// Cache des classes
typedef std::map<std::string, jclass> ClassMap;
ClassMap classMap;

// Cache des methods
typedef std::map<std::string, jmethodID> SignatureMethodMap;
typedef std::map<jclass, SignatureMethodMap> MethodMap;
MethodMap methodMap;
MethodMap staticMethodMap;

// Cache des fields
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
   {
      return NULL;
   }

   jclass globalRefCls = (jclass)javaEnv->NewGlobalRef(localRefCls);
   javaEnv->DeleteLocalRef(localRefCls);
   if( globalRefCls == NULL )
   {
       return NULL;
   }

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
   if( localRefMid == NULL )
   {
       return NULL;
   }

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
   if( localRefMid == NULL )
   {
     return NULL;
   }

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
   if( localRefFid == NULL )
   {
      return NULL;
   }

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
   if( localRefFid == NULL )
   {
     return NULL;
   }

   signatures[name] = localRefFid;
   return localRefFid;
}

jstring Java4CppRuntime::newStringNative(JNIEnv *javaEnv, const std::string& str)
{
   jstring result;
   jbyteArray bytes;

   int len = str.size();
   if( javaEnv->EnsureLocalCapacity(2) < 0 )
      return NULL;

   jclass classe = Java4CppRuntime::getClass(javaEnv, "Ljava/lang/String;");
   jmethodID MID_String_init = Java4CppRuntime::getMethodID(javaEnv, classe, "<init>", "([B)V");

   bytes = javaEnv->NewByteArray(len);
   if( bytes != NULL )
   {
      javaEnv->SetByteArrayRegion(bytes, 0, len, (jbyte *)(str.c_str()));
      result = (jstring)javaEnv->NewObject(classe, MID_String_init, bytes);
      javaEnv->DeleteLocalRef(bytes);
      return result;
   }
   return NULL;
}

std::string Java4CppRuntime::getStringNativeChars(JNIEnv *javaEnv, jstring jstr)
{
   std::string str;
   jbyteArray bytes;
   jthrowable exc;

   char *result = 0;
   if( javaEnv->EnsureLocalCapacity(2) < 0 )
      return str;

   jclass classe = Java4CppRuntime::getClass(javaEnv, "Ljava/lang/String;");
   jmethodID MID_String_getBytes = Java4CppRuntime::getMethodID(javaEnv, classe, "getBytes", "()[B");

   bytes = (jbyteArray)javaEnv->CallObjectMethod(jstr, MID_String_getBytes);
   exc = javaEnv->ExceptionOccurred();
   if( !exc )
   {
      jint len = javaEnv->GetArrayLength(bytes);
      result = (char *)malloc(len + 1);
      if( result == 0 )
      {
         javaEnv->DeleteLocalRef(bytes);
         return str;
      }
      javaEnv->GetByteArrayRegion(bytes, 0, len, (jbyte *)result);
      result[len] = 0;
   }
   else
   {
      javaEnv->ExceptionClear();
      javaEnv->DeleteLocalRef(exc);
   }
   javaEnv->DeleteLocalRef(bytes);

   if( result )
   {
      str = result;
      free(result);
   }
   return str;
}

jobject Java4CppRuntime::newEnum(JNIEnv *javaEnv, const char* value, const char* enumType)
{
   jclass cls = Java4CppRuntime::getClass(javaEnv, enumType);
   jfieldID fid = javaEnv->GetStaticFieldID(cls, value, enumType);
   return javaEnv->GetStaticObjectField(cls, fid);
}

int Java4CppRuntime::nativeEnum(JNIEnv *javaEnv, jobject enume, const char* enumType)
{
   if( !enume ) return 0;
   jclass cls = Java4CppRuntime::getClass(javaEnv, enumType);
   jmethodID mid = Java4CppRuntime::getMethodID(javaEnv, cls, "ordinal", "()I");
   jint jresult = javaEnv->CallIntMethod(enume, mid);
   return (int)jresult;
}
