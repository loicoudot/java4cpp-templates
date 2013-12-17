<#-- The name of the corresponding file for the C++ wrapper without extension -->
<#macro fileName class>${class.type.cppFullName?replace('::', '_')}</#macro>

<#-- Includes helpers -->
<#macro initIncludes includes><#assign allIncludes = includes/></#macro>
<#macro addInclude include><#assign allIncludes = allIncludes + [include]/></#macro>
<#macro addIncludes includes><#assign allIncludes = allIncludes + includes/></#macro>
<#macro printInclude><#list allIncludes?sort as include>
<#if include[0] != '"'>#include ${include}</#if>
</#list>
<#list allIncludes?sort as include>
<#if include[0] == '"'>#include ${include}</#if>
</#list>
</#macro>

<#macro parameters parameters><#list parameters as parameter>${parameter.type.cppType} arg${parameter_index+1}<#if parameter_has_next>, </#if></#list></#macro>

<#macro sortConstructors class><#assign constructorList = {}/>
<#list class.content.constructors as constructor>
<#assign cppSignature><@parameters constructor.parameters/></#assign>
<#if cppSignature == "const "+class.type.cppFullName+"& arg1" || constructorList[constructor]??>// Skipping duplicate constructor: ${cppSignature}
<#else><#assign constructorList = constructorList + {cppSignature:constructor}/></#if>
</#list>
</#macro>

<#macro sortMethods class><#assign methodList = {}/> 
<#list class.content.methods as method>
<#assign cppSignature>${method.cppName}(<@parameters method.parameters/>)</#assign>
<#if methodList[cppSignature]??>// Skipping duplicate method: ${cppSignature}
<#else><#assign methodList = methodList + {cppSignature:method}/></#if>
</#list>
</#macro>