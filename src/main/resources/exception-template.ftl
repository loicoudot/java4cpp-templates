<@cppFormatter>
<#assign fileName = 'java_exceptions.cpp'/>
#include "java_exceptions.h"
#include "stdexcept"
#include "java4cpp_runtime.h"
#include "java_lang_Throwable.h"
<#list classes?sort_by('cppFullName') as class>
<#if class.isThrowable>#include "${class.owner.cppFullName?replace('::', '_')}.h"</#if>
</#list>

void convertJThrowableToException( JNIEnv *javaEnv, jthrowable exc)
{
   jclass cls = Java4CppRuntime::getClass(javaEnv, "java/lang/Class");
   jclass exceptionClass = javaEnv->GetObjectClass(exc);
   jmethodID mid = Java4CppRuntime::getMethodID(javaEnv, cls, "getName", "()Ljava/lang/String;");
   jstring jresult = (jstring)javaEnv->CallObjectMethod(exceptionClass, mid);
   const char *str = javaEnv->GetStringUTFChars(jresult, 0);
   std::string className(str);
   javaEnv->ReleaseStringUTFChars(jresult, str);
   Java4CppRuntime::handleJavaException(javaEnv);
   <#list classes?sort_by('cppFullName') as class>
   <#if class.isThrowable>
   if (className == "${class.javaName}") {   
      ${class.cppFullName} throwable(exc);
      throw throwable;
   }
   </#if>
   </#list>
   throw java::lang::Throwable(exc);
}
</@cppFormatter>