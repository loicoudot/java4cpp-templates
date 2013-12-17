<#assign fileName = 'java_classes.h'/>
#ifndef JAVA_CLASSES_H
#define JAVA_CLASSES_H

<#list classes?sort_by(["type", "cppFullName"]) as class>
#include "${class.type.cppFullName?replace('::', '_')}.h"
</#list>

#endif

