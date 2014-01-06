<#include "common.ftl"/>
<@cppFormatter>
<#if class.parameters??>
<#assign fileName = ''/>
<#else>
<#-- Sets the name of the generated file -->
<#assign fileNameNoExtension><@fileName class/></#assign>
<#assign fileName = fileNameNoExtension+'.h'/>
#ifndef ${fileName?replace('.', '_')?upper_case}
#define ${fileName?replace('.', '_')?upper_case}

<#-- Adds includes from the runtime and Java4Cpp -->
<@initIncludes ['"jni.h"']/>
<#if class.type.isThrowable><@addIncludes ['<stdexcept>', '<string>']/></#if>
<@addIncludes class.includes/>
<#-- Enumerations need to include theirs values -->
<#if class.type.isEnum && !class.type.isInnerClass><@addInclude '"'+fileNameNoExtension+'Enum.h"'/></#if>
<#-- Try to use forward declaration as much as possible for the class dependencies -->
<#assign forwards = []/>
<#list class.dependencies as dependency>
<#if dependency.type.owner != class>
<#-- ... we include the owner class of the superclass if any -->
<#if class.content.superclass?? && dependency = class.content.superclass><@addInclude '"'+dependency.type.owner.type.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... we include the owner class of enumerations and interfaces -->
<#else><#if dependency.type.isEnum || class.content.interfaces?seq_contains(dependency)><@addInclude '"'+dependency.type.owner.type.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... we include the owner class for inner class dependency -->
<#else><#if dependency.type.isInnerClass><@addInclude '"'+dependency.type.owner.type.cppFullName?replace('::', '_')+'.h"'/>
<#-- ... other dependencies can be declared as forwards -->
<#else><#assign forwards = forwards + [dependency]/></#if>
</#if></#if></#if></#list>
<@printInclude/>

<#-- Regroups and print forward declaration by namespace -->
<#assign currentNamespace = []/>
<#list forwards?sort_by(["type", "cppFullName"]) as dependency>
<#list dependency.type.cppFullName?split("::") as namespace>
<#if currentNamespace?size &gt; namespace_index && (currentNamespace[namespace_index] != namespace)>
<#list 1..(currentNamespace?size-namespace_index) as decrement>}
<#if currentNamespace?size = 1><#assign currentNamespace = []/>
<#else><#assign currentNamespace = currentNamespace[0..(currentNamespace?size-2)]/></#if>
</#list>
</#if> 
<#if currentNamespace?size &lt;= namespace_index>
<#if namespace_has_next>namespace ${namespace} {<#assign currentNamespace = currentNamespace + [namespace]/><#else>class ${namespace};</#if>
</#if>
</#list>
</#list>
<#list currentNamespace as namespace>
}
</#list>

<#-- Open namespace -->
<#list class.type.cppFullName?split("::") as namespace>
<#if namespace_has_next>namespace ${namespace} {</#if>
</#list>
<#-- Write class definition -->
<@classDefinition class/>

<#-- Close namespace -->
<#list class.type.cppFullName?split("::") as namespace>
<#if namespace_has_next>}</#if>
</#list>
#endif
</#if>
</@cppFormatter>

<#-- Macro for generating class definition (need recursivity)-->
<#macro classDefinition class>
class ${class.type.cppShortName}<#assign separator=": public"/>
<#if class.content.superclass??>${separator} ${class.content.superclass.type.cppFullName}<#assign separator=", public"/><#t/>
<#else><#if class.type.isThrowable>${separator} std::exception<#assign separator=", public"/></#if></#if><#t/>
<#list class.content.interfaces?sort_by(["type", "cppFullName"]) as interface>${separator} ${interface.type.cppFullName}<#assign separator=", public"/></#list><#t/>
{
public:
	<#-- Inner enumerations are declared inside -->
	<#if class.type.isInnerClass && class.type.isEnum>
	typedef enum {
		NULL_VALUE = -1,
		<#list class.content.enumKeys as key>
		${key}<#if key_has_next>,</#if>
		</#list>
	} ${class.type.cppShortName}Enum;
   
	</#if>
	<#-- Generate nested enumarations -->
	<#list class.content.nestedClass?sort_by(["type", "cppFullName"]) as nestedClass>
	<#if nestedClass.type.isEnum><@classDefinition nestedClass/>
	
	</#if>
	</#list>
	<#-- Generate nested classes -->
	<#list class.content.nestedClass?sort_by(["type", "cppFullName"]) as nestedClass>
	<#if !nestedClass.type.isEnum><@classDefinition nestedClass/>
	
	</#if>
	</#list>
	<#-- Generate getters for static fields -->
	<#list class.content.staticFields?sort_by("cppName") as field>
	static ${field.type.type.cppReturnType} get${field.cppName?cap_first}();
	</#list>
	jobject getJavaObject() const;
	void setJavaObject(jobject obj);

	<#-- Generate contructors -->
	<@sortConstructors class/>
	<#list constructorList?keys?sort as constructor>
	explicit ${class.type.cppShortName}(${constructor});
	</#list>
	explicit ${class.type.cppShortName}(jobject obj);
	<#if class.type.isEnum>explicit ${class.type.cppShortName}(${class.type.cppType} arg1);</#if>
	${class.type.cppShortName}(const ${class.type.cppFullName}& other);
	${class.type.cppFullName}& operator=(const ${class.type.cppFullName}& other);
	virtual ~${class.type.cppShortName}()<#if class.type.isThrowable> throw()</#if>;
	<#if class.type.isThrowable>virtual const char* what() const throw();</#if>
	<#if class.type.isCloneable>${class.type.cppReturnType} clone();</#if>
public:
	<#-- Generate methods -->
	<@sortMethods class/>
	<#list methodList?keys?sort as method>
	<#if methodList[method].isStatic>static<#else>virtual</#if> ${methodList[method].returnType.type.cppReturnType} ${method};
	</#list>
	<#-- Generate enumerations helpers -->
	<#if class.type.isEnum>
	static const char* getEnumString(${class.type.cppType} arg1);
	</#if>
private:
	static jclass j4c_getClass();
	
	jobject _obj;
	<#if class.type.isThrowable>mutable std::string _msg;</#if>
};

</#macro>
