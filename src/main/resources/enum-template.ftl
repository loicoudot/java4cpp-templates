<@cppFormatter>
<#if !class.isEnum>
<#assign fileName = ''>
<#else>
<#assign fileName = class.cppFullName?replace('::', '_')+"Enum.h">
#ifndef ${fileName?replace('.', '_')?upper_case}
#define ${fileName?replace('.', '_')?upper_case}

<#assign cppEnum = class.cppFullName?split("::")?last + "Enum"/>
<#list class.cppFullName?split("::") as namespace>
<#if namespace_has_next>namespace ${namespace} {</#if>
</#list>namespace ${cppEnum} {

typedef enum {
NULL_VALUE = -1,
<#list class.enumKeys as key>
${key}<#if key_has_next>,</#if>
</#list>
} ${cppEnum};

<#list class.cppFullName?split("::") as namespace>
}
</#list>
#endif
</#if>
</@cppFormatter>