<#include "common.ftl"/>
<@cppFormatter>
<#-- Sets the name of the generated file -->
<#assign fileNameNoExtension><@fileName class/></#assign>
<#assign fileName = fileNameNoExtension+'.h'/>
#ifndef ${fileName?replace('.', '_')?upper_case}
#define ${fileName?replace('.', '_')?upper_case}

<#-- Adds includes from the runtime and Java4Cpp -->
<@initIncludes ['"java4cpp_defs.h"', '"jni.h"']/>
<#if class.isThrowable><@addIncludes ['<stdexcept>', '<string>']/></#if>
<@addIncludes class.includes/>
<#-- Enumerations need to include theirs values -->
<#if class.isEnum && !class.isInnerClass><@addInclude '"'+fileNameNoExtension+'Enum.h"'/></#if>
<#-- Try to use forward declaration as much as possible for the class dependencies -->
<#assign forwards = []>
<#list class.dependencies as dependency>
<#if dependency.owner != class>
<#-- ... we include the owner class of the superclass if any -->
<#if class.superclass?? && dependency = class.superclass><@addInclude '"'+dependency.owner.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... we include the owner class of enumerations and interfaces -->
<#else><#if dependency.isEnum || class.interfaces?seq_contains(dependency)><@addInclude '"'+dependency.owner.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... we include the owner class for inner class dependency -->
<#else><#if dependency.isInnerClass><@addInclude '"'+dependency.owner.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... other dependencies can be declared as forwards -->
<#else><#assign forwards = forwards + [dependency]></#if>
</#if></#if></#if></#list>
<@printInclude/>

<#-- Regroups and print forward declaration by namespace -->
<#assign currentNamespace = []>
<#list forwards?sort_by("cppFullName") as dependency>
<#list dependency.cppFullName?split("::") as namespace>
<#if currentNamespace?size &gt; namespace_index && (currentNamespace[namespace_index] != namespace)>
<#list 1..(currentNamespace?size-namespace_index) as decrement>}
<#if currentNamespace?size = 1><#assign currentNamespace = []>
<#else><#assign currentNamespace = currentNamespace[0..(currentNamespace?size-2)]></#if>
</#list>
</#if> 
<#if currentNamespace?size &lt;= namespace_index>
<#if namespace_has_next>namespace ${namespace} {<#assign currentNamespace = currentNamespace + [namespace]><#else>class ${namespace};</#if>
</#if>
</#list>
</#list>
<#list currentNamespace as namespace>
}
</#list>

<#-- Open namespace -->
<#list class.cppFullName?split("::") as namespace>
<#if namespace_has_next>namespace ${namespace} {</#if>
</#list>
<#-- Write class definition -->
<@classDefinition class/>

<#-- Close namespace -->
<#list class.cppFullName?split("::") as namespace>
<#if namespace_has_next>}</#if>
</#list>
#endif
</@cppFormatter>

<#-- Macro for generating class definition (need recursivity)-->
<#macro classDefinition class>
class _JAVA4CPPCLASS ${class.cppShortName}<#assign separator=": public"/>
<#if class.superclass??>${separator} ${class.superclass.cppFullName}<#assign separator=", public"/><#t>
<#else><#if class.isThrowable>${separator} std::exception<#assign separator=", public"/></#if></#if><#t>
<#list class.interfaces?sort_by("cppFullName") as interface>${separator} ${interface.cppFullName}<#assign separator=", public"/></#list><#t>
{
public:
	<#-- Generate nested enumarations -->
	<#list class.nestedClass?sort_by("cppFullName") as nestedClass>
	<#if nestedClass.isEnum><@classDefinition nestedClass/>
	
	</#if>
	</#list>
	<#-- Generate nested classes -->
	<#list class.nestedClass?sort_by("cppFullName") as nestedClass>
	<#if !nestedClass.isEnum><@classDefinition nestedClass/>
	
	</#if>
	</#list>
	<#-- Generate getters for static fields -->
	<#list class.fields?sort_by("cppName") as field>
	static ${field.type.cppReturnType} get${field.cppName?cap_first}();
	</#list>
	jobject getJavaObject() const;
	void setJavaObject(jobject obj);

	<#-- Generate contructors -->
	<@sortConstructors/>
	<#list constructorList?keys?sort as constructor>
	explicit ${class.cppShortName}(${constructor});
	</#list>
	explicit ${class.cppShortName}(jobject obj)<#if class.isThrowable> throw()</#if>;
	${class.cppShortName}(const ${class.cppFullName}& other)<#if class.isThrowable> throw()</#if>;
	${class.cppFullName}& operator=(const ${class.cppFullName}& other)<#if class.isThrowable> throw()</#if>;
	virtual ~${class.cppShortName}()<#if class.isThrowable> throw()</#if>;
	<#if class.isThrowable>virtual const char* what() const throw();</#if>
	<#if class.isCloneable>${class.cppReturnType} clone();</#if>
public:
	<#-- Inner enumerations are declared inside -->
	<#if class.isInnerClass && class.isEnum>
	typedef enum {
		<#list class.enumKeys as key>
		${key}<#if key_has_next>,</#if>
		</#list>
	} ${class.cppShortName}Enum;
   
	</#if>
	<#-- Generate methods -->
	<@sortMethods/>
	<#list methodList?keys?sort as method>
	<#if methodList[method].isStatic>static<#else>virtual</#if> ${methodList[method].returnType.cppReturnType} ${method};
	</#list>
	<#-- Generate enumerations helpers -->
	<#if class.isEnum><@addInclude '<map>'/>
	${class.cppFullName} get(${class.cppType} arg1);
	//static std::string getEnumString(${class.cppType} arg1);
	</#if>
private:
	jobject _obj;
	<#if class.isThrowable>mutable std::string _msg;</#if>
};

</#macro>
