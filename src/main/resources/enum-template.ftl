<@cppFormatter>
<#if !class.type.isEnum>
<#assign fileName = ''/>
<#else>
<#assign fileName = class.type.cppFullName?replace('::', '_')+"Enum.h"/>
#ifndef ${fileName?replace('.', '_')?upper_case}
#define ${fileName?replace('.', '_')?upper_case}

<#assign cppEnum = class.type.cppFullName?split("::")?last + "Enum"/>
<#list class.type.cppFullName?split("::") as namespace>
<#if namespace_has_next>namespace ${namespace} {</#if>
</#list>namespace ${cppEnum} {

typedef enum {
NULL_VALUE = -1,
<#list class.content.enumKeys as key>
${key}<#if key_has_next>,</#if>
</#list>
} ${cppEnum};

<#list class.type.cppFullName?split("::") as namespace>
}
</#list>
#endif
</#if>
</@cppFormatter>