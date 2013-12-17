<#include "common.ftl"/>
<@cppFormatter>
<#assign fileName><@fileName class/>.cpp</#assign>
<@initIncludes ['"'+class.type.cppFullName?replace('::', '_')+'.h"', '"java4cpp_runtime.h"', '"jvm_launcher.h"', '<stdexcept>']/>
<#list class.dependencies as dependency>
<#if dependency.type.owner != class>
<@addInclude '"'+dependency.type.owner.type.cppFullName?replace('::', '_')+'.h"'/>
</#if>
</#list>
<#if class.type.isEnum><@addInclude '<map>'/></#if>
<#list class.content.nestedClass as nestedClass><#if nestedClass.type.isEnum><@addInclude '<map>'/></#if></#list>
<@printInclude/>

<@classImplementation class/>
</@cppFormatter>

<#macro headerDefinition class content>
<#assign separator=" :"/><#t/>
<#if class.content.superclass??>${separator} ${class.content.superclass.type.cppFullName}(${content})<#assign separator=","/><#t/>
<#else><#if class.type.isCheckedException>${separator} std::exception()<#assign separator=","/></#if></#if><#t/>
<#list class.content.interfaces?sort_by(["type", "cppFullName"]) as interface>${separator} ${interface.cppFullName}(${content})<#assign separator=","/><#t/></#list><#t/>
</#macro>

<#macro classImplementation class>
<#list class.content.nestedClass as nestedClass>
<@classImplementation nestedClass/>
</#list>
jclass ${class.type.cppFullName}::j4c_getClass() {
	static jclass globalRefCls = NULL;
	if( !globalRefCls ) {
		JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	   	jclass localRefCls = javaEnv->FindClass("${class.type.javaName?replace('.', '/')}");
		Java4CppRuntime::handleJavaException(javaEnv);
		globalRefCls = (jclass)javaEnv->NewGlobalRef(localRefCls);
		javaEnv->DeleteLocalRef(localRefCls);
	}
	return globalRefCls;
}

jobject ${class.type.cppFullName}::getJavaObject() const
{
	return _obj;
}

void ${class.type.cppFullName}::setJavaObject(jobject obj)
{
	if(_obj == obj) return;
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	if( _obj != NULL && javaEnv ) javaEnv->DeleteGlobalRef(_obj);
   	if(  obj != NULL && javaEnv ) {
   		jclass cls = j4c_getClass();
		if(javaEnv->IsInstanceOf(obj, cls) == JNI_FALSE) 
			throw std::runtime_error("can't cast to \"${class.type.javaName}\"");
   		_obj = javaEnv->NewGlobalRef(obj);
   	}
   	else _obj = NULL;
   	<#if class.content.superclass??>${class.content.superclass.type.cppFullName}::setJavaObject(obj);</#if>
   	<#list class.content.interfaces?sort_by(["type", "cppFullName"]) as interface>${interface.cppFullName}::setJavaObject(obj);</#list>
}

<#if class.type.isEnum>
${class.type.cppFullName}::${class.type.cppShortName}(${class.type.cppType} arg1)
{
	_obj = NULL;
   if( arg1 != ${class.type.cppFullName}<#if !class.type.isInnerClass>Enum</#if>::NULL_VALUE )
   {
	   JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
      jclass cls = j4c_getClass();
      static jmethodID mid = javaEnv->GetStaticMethodID(cls, "valueOf", "(Ljava/lang/String;)${class.type.javaSignature}");
      jstring jarg1 = javaEnv->NewStringUTF(getEnumString(arg1));
      jobject jresult = javaEnv->CallStaticObjectMethod(cls, mid, jarg1);
      Java4CppRuntime::handleJavaException(javaEnv);
      setJavaObject(jresult);
      javaEnv->DeleteLocalRef(jresult);
      javaEnv->DeleteLocalRef(jarg1);
   }
}
</#if>

${class.type.cppFullName}::${class.type.cppShortName}(jobject obj)<@headerDefinition class "obj"/>
{
	_obj = NULL;
	setJavaObject(obj);
}

${class.type.cppFullName}::${class.type.cppShortName}(const ${class.type.cppFullName}& other)<@headerDefinition class "other"/>
{
	_obj = NULL;
	setJavaObject(other._obj);
}

${class.type.cppFullName}& ${class.type.cppFullName}::operator=(const ${class.type.cppFullName}& other)
{
	_obj = other._obj;
    return *this;
}

${class.type.cppFullName}::~${class.type.cppShortName}()<#if class.type.isThrowable> throw()</#if>
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	if(javaEnv && _obj) javaEnv->DeleteGlobalRef(_obj);
}

<@sortConstructors class/>
<#list constructorList?keys?sort as cppSignature>
<#assign constructor = constructorList[cppSignature]/>
${class.type.cppFullName}::${class.type.cppShortName}(${cppSignature})<@headerDefinition class "NULL"/>
{
	_obj = NULL;
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = j4c_getClass();
	static jmethodID mid = javaEnv->GetMethodID(cls, "<init>", "(<#list constructor.parameters as parameter>${parameter.type.javaSignature}</#list>)V");
	<#list constructor.parameters as parameter>${parameter.type.functions.cpp2java("arg"+(parameter_index+1), "jarg"+(parameter_index+1))}</#list>
	jobject o = javaEnv->NewObject(cls, mid<#list constructor.parameters as parameter>, jarg${parameter_index+1}</#list>);
	Java4CppRuntime::handleJavaException(javaEnv);
	setJavaObject(o);
	javaEnv->DeleteLocalRef(o);
	<#list constructor.parameters as parameter><#if parameter.type.functions.cpp2javaClean??>${parameter.type.functions.cpp2javaClean("jarg"+(parameter_index+1))}</#if></#list>
}

</#list>

<#if class.type.isThrowable>const char* ${class.type.cppFullName}::what() const throw()
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

<#if class.type.isCloneable>
${class.type.cppReturnType} ${class.type.cppFullName}::clone()
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = j4c_getClass();
	static jmethodID mid = javaEnv->GetMethodID(cls, "clone", "()L${class.type.javaName?replace('.', '/')};");
	jobject jresult = javaEnv->CallObjectMethod(_obj, mid);
	Java4CppRuntime::handleJavaException(javaEnv);
	${class.type.cppReturnType} copy(jresult);
	javaEnv->DeleteLocalRef(jresult);
	return copy;
}
</#if>

<#list class.content.staticFields?sort_by(["type", "cppName"]) as field>
${field.type.cppReturnType} ${class.type.cppFullName}::get${field.cppName?cap_first}() {
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = j4c_getClass();
	jfieldID fid = javaEnv->GetStaticFieldID(cls, "${field.javaName}", "${field.type.javaSignature}");
   ${field.type.jniSignature} jvar = javaEnv->GetStatic${field.type.jniMethodName}Field(cls, fid);
   ${field.type.functions.java2cpp("jvar", "var")}
   return var;
}

</#list>

<@sortMethods class/>
<#list methodList?keys?sort as cppSignature>
<#assign method = methodList[cppSignature]/>
${method.returnType.type.cppReturnType} ${class.type.cppFullName}::${cppSignature}
{
	JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	jclass cls = j4c_getClass();
	static jmethodID mid = javaEnv->Get<#if method.isStatic>Static</#if>MethodID(cls, "${method.javaName}", "(<#list method.parameters as parameter>${parameter.type.javaSignature}</#list>)${method.returnType.type.javaSignature}");
 	<#list method.parameters as parameter>${parameter.type.functions.cpp2java("arg"+(parameter_index+1), "jarg"+(parameter_index+1))}</#list>
	<#if method.returnType.type.cppReturnType!="void">${method.returnType.type.jniSignature} jresult = (${method.returnType.type.jniSignature})</#if><#t/>
	<#if method.isStatic>javaEnv->CallStatic${method.returnType.type.jniMethodName}Method(cls, mid<#else><#t/>
	javaEnv->Call${method.returnType.type.jniMethodName}Method(_obj, mid</#if><#t/>
	<#list method.parameters as parameter>, jarg${parameter_index+1}<#lt/></#list>);
   Java4CppRuntime::handleJavaException(javaEnv); 
	<#list method.parameters as parameter><#if parameter.type.functions.cpp2javaClean??>${parameter.type.functions.cpp2javaClean("jarg"+(parameter_index+1))}</#if></#list>
	<#if method.returnType.type.cppReturnType!="void">${method.returnType.type.functions.java2cpp("jresult", "result")}
	return result;</#if> 
}

</#list>
<#if class.type.isEnum>
const char* ${class.type.cppFullName}::getEnumString(${class.type.cppType} arg1)
{
   static std::map<long, const char*> map;
   if( !map.size() )
   {
   	  map[-1] = "NULL_VALUE";
      <#list class.content.enumKeys as key>
      map[${key_index}] = "${key}";
      </#list>
   }
   return map[(long)arg1];
}

</#if>
</#macro>