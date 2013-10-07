<#include "common.ftl"/>
<@cppFormatter>
<#assign fileName><@fileName class/>.cpp</#assign>
<@initIncludes ['"'+class.cppFullName?replace('::', '_')+'.h"', '"java4cpp_runtime.h"', '"javawrapper.h"']/>
<#list class.dependencies as dependency>
<#if dependency.owner != class>
<@addInclude '"'+dependency.owner.cppFullName?replace('::', '_')+'.h"'/>
</#if>
</#list>
<#if class.isEnum><@addInclude '<map>'/></#if>
<#list class.nestedClass as nestedClass><#if nestedClass.isEnum><@addInclude '<map>'/></#if></#list>
<@printInclude/>

<@classImplementation class/>
</@cppFormatter>

<#macro headerDefinition class content>
<#assign separator=" :"/><#t>
<#if class.superclass??>${separator} ${class.superclass.cppFullName}(${content})<#assign separator=","/><#t>
<#else><#if class.isCheckedException>${separator} std::exception()<#assign separator=","/></#if></#if><#t>
<#list class.interfaces?sort_by("cppFullName") as interface>${separator} ${interface.cppFullName}(${content})<#assign separator=","/><#t></#list><#t>
</#macro>

<#macro classImplementation class>
<#list class.nestedClass as nestedClass>
<@classImplementation nestedClass/>
</#list>
jobject ${class.cppFullName}::getJavaObject() const
{
	return _obj;
}

void ${class.cppFullName}::setJavaObject(jobject obj)
{
	if(_obj == obj) return;
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	if( _obj != NULL && javaEnv ) javaEnv->DeleteGlobalRef(_obj);
   if(  obj != NULL && javaEnv ) _obj = javaEnv->NewGlobalRef(obj);
   else _obj = NULL;
   <#if class.superclass??>${class.superclass.cppFullName}::setJavaObject(obj);</#if>
   <#list class.interfaces?sort_by("cppFullName") as interface>${interface.cppFullName}::setJavaObject(obj);</#list>
}

${class.cppFullName}::${class.cppShortName}(jobject obj)<#if class.isThrowable> throw()</#if><@headerDefinition class "obj"/>
{
	_obj = NULL;
	setJavaObject(obj);
}

${class.cppFullName}::${class.cppShortName}(const ${class.cppFullName}& other)<#if class.isThrowable> throw()</#if><@headerDefinition class "other"/>
{
	_obj = NULL;
	setJavaObject(other._obj);
}

${class.cppFullName}& ${class.cppFullName}::operator=(const ${class.cppFullName}& other)<#if class.isThrowable> throw()</#if>
{
	_obj = other._obj;
    return *this;
}

${class.cppFullName}::~${class.cppShortName}()<#if class.isThrowable> throw()</#if>
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	if(javaEnv && _obj) javaEnv->DeleteGlobalRef(_obj);
}

<@sortConstructors/>
<#list constructorList?keys?sort as cppSignature>
<#assign constructor = constructorList[cppSignature]/>
${class.cppFullName}::${class.cppShortName}(${cppSignature})<@headerDefinition class "NULL"/>
{
	_obj = NULL;
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = Java4CppRuntime::getClass(javaEnv, "${class.javaName?replace('.', '/')}");
	jmethodID mid = Java4CppRuntime::getMethodID(javaEnv, cls, "<init>", "(<#list constructor.parameters as parameter>${parameter.javaSignature}</#list>)V");
	<#list constructor.parameters as parameter>${parameter.functions.cpp2java("jarg"+(parameter_index+1), "arg"+(parameter_index+1))}</#list>
	jobject o = javaEnv->NewObject(cls, mid<#list constructor.parameters as parameter>, jarg${parameter_index+1}</#list>);
	Java4CppRuntime::handleJavaException(javaEnv);
	setJavaObject(o);
	javaEnv->DeleteLocalRef(o);
	<#list constructor.parameters as parameter><#if parameter.functions.cpp2javaClean??>${parameter.functions.cpp2javaClean("arg"+(parameter_index+1), "jarg"+(parameter_index+1))}</#if></#list>
}

</#list>

<#if class.isThrowable>const char* ${class.cppFullName}::what() const throw()
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();

    jclass clsWritter = Java4CppRuntime::getClass(javaEnv, "java/io/StringWriter");
    jmethodID constructorWritter = Java4CppRuntime::getMethodID(javaEnv, clsWritter, "<init>", "()V");
    jobject writter = javaEnv->NewObject(clsWritter, constructorWritter);

    jclass clsPrint = Java4CppRuntime::getClass(javaEnv, "java/io/PrintWriter");
    jmethodID constructorPrint = Java4CppRuntime::getMethodID(javaEnv, clsPrint, "<init>", "(Ljava/io/Writer;)V");
    jobject printWriter = javaEnv->NewObject(clsPrint, constructorPrint, writter);

    jclass clsThrowable = Java4CppRuntime::getClass(javaEnv, "java/lang/Throwable");
    jmethodID printStackTrace = Java4CppRuntime::getMethodID(javaEnv, clsThrowable, "printStackTrace", "(Ljava/io/PrintWriter;)V");
    javaEnv->CallVoidMethod(_obj, printStackTrace, printWriter);

    jmethodID toString = Java4CppRuntime::getMethodID(javaEnv, clsWritter, "toString", "()Ljava/lang/String;");
    jstring jresult = (jstring)javaEnv->CallObjectMethod(writter, toString);
 
 	jboolean isCopy = JNI_FALSE;
	const char* msg = javaEnv->GetStringUTFChars( jresult, &isCopy );
	_msg.assign(msg);
	javaEnv->ReleaseStringUTFChars( jresult, msg );
 
    javaEnv->DeleteLocalRef(jresult);
    javaEnv->DeleteLocalRef(printWriter);
    javaEnv->DeleteLocalRef(writter);
	
	return _msg.c_str();
}
</#if>

<#if class.isCloneable>
${class.cppReturnType} ${class.cppFullName}::clone()
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = Java4CppRuntime::getClass(javaEnv, "${class.javaName?replace('.', '/')}");
	jmethodID mid = Java4CppRuntime::getMethodID(javaEnv, cls, "clone", "()L${class.javaName?replace('.', '/')};");
	jobject jresult = javaEnv->CallObjectMethod(_obj, mid);
	Java4CppRuntime::handleJavaException(javaEnv);
	${class.cppReturnType} copy(jresult);
	javaEnv->DeleteLocalRef(jresult);
	return copy;
}
</#if>

<#list class.fields?sort_by("cppName") as field>
${field.type.cppReturnType} ${class.cppFullName}::get${field.cppName?cap_first}() {
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = Java4CppRuntime::getClass(javaEnv, "${class.javaName?replace('.', '/')}");
	jfieldID fid = Java4CppRuntime::getStaticFieldID(javaEnv, cls, "${field.javaName}", "${field.type.javaSignature}");
   ${field.type.jniSignature} jvar = javaEnv->GetStatic${field.type.jniMethodName}Field(cls, fid);
   ${field.type.functions.java2cpp("jvar", "var")}
   return var;
}

</#list>

<@sortMethods/>
<#list methodList?keys?sort as cppSignature>
<#assign method = methodList[cppSignature]/>
${method.returnType.cppReturnType} ${class.cppFullName}::${cppSignature}
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = Java4CppRuntime::getClass(javaEnv, "${class.javaName?replace('.', '/')}");
	jmethodID mid = Java4CppRuntime::get<#if method.isStatic>Static</#if>MethodID(javaEnv, cls, "${method.javaName}", "(<#list method.parameters as parameter>${parameter.javaSignature}</#list>)${method.returnType.javaSignature}");
 	<#list method.parameters as parameter>${parameter.functions.cpp2java("jarg"+(parameter_index+1), "arg"+(parameter_index+1))}</#list>
	<#if method.returnType.cppReturnType!="void">${method.returnType.jniSignature} jresult = (${method.returnType.jniSignature})</#if><#t>
	<#if method.isStatic>javaEnv->CallStatic${method.returnType.jniMethodName}Method(cls, mid<#else><#t>
	javaEnv->Call${method.returnType.jniMethodName}Method(_obj, mid</#if><#t>
	<#list method.parameters as parameter>, jarg${parameter_index+1}<#lt></#list>);
   Java4CppRuntime::handleJavaException(javaEnv); 
	<#list method.parameters as parameter><#if parameter.functions.cpp2javaClean??>${parameter.functions.cpp2javaClean("arg"+(parameter_index+1), "jarg"+(parameter_index+1))}</#if></#list>
	<#if method.returnType.cppReturnType!="void">${method.returnType.functions.java2cpp("result", "jresult")}
	return result;</#if> 
}

</#list>
<#if class.isEnum>
${class.cppFullName} ${class.cppFullName}::get(${class.cppType} arg1)
{
   static std::map<${class.cppType}, ${class.cppFullName}> cache;
   JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
   std::map<${class.cppType}, ${class.cppShortName}>::iterator itFind = cache.find(arg1);
   if( itFind != cache.end() ) return itFind->second;
   jclass cls = Java4CppRuntime::getClass(javaEnv, "${class.javaName?replace('.', '/')}");
   jmethodID mid = Java4CppRuntime::getStaticMethodID(javaEnv, cls, "values", "()[${class.javaSignature}");
   jobjectArray jresult = (jobjectArray)javaEnv->CallStaticObjectMethod(cls, mid);
   Java4CppRuntime::handleJavaException(javaEnv);
   ${class.cppFullName} result = ${class.cppFullName}(jresult);
   cache.insert(std::make_pair(arg1, result));
   javaEnv->DeleteLocalRef(jresult);
   return result;
}
/*
std::string ${class.cppFullName}::getEnumString(${class.cppType} arg1)
{
   static std::map<long, std::string> map;
   if( !map.size() )
   {
      <#list class.enumKeys as key>
      map[${key_index}] = "${key}";
      </#list>
   }
   return map[(long)arg1];
}
*/
</#if>
</#macro>