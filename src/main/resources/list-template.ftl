<@cppFormatter>
<#if !class.parameters??>
<#assign fileName = 'java4cpp_listOfObject.h'/>
<#else>
<#-- Sets the name of the generated file -->
<#assign fileName = 'java4cpp_listOf'+class.parameters[0].type.cppShortName+'.h'/>
#ifndef ${fileName?replace('.', '_')?upper_case}
#define ${fileName?replace('.', '_')?upper_case}

#include "java4cpp_list.h"
#include "${class.parameters[0].type.cppFullName?replace('::', '_')}.h"

template<>
${class.parameters[0].type.cppFullName} java4cpp::list<${class.parameters[0].type.cppFullName}>::get(int idx) {
    return 0;
}


#endif
</#if>
</@cppFormatter>
