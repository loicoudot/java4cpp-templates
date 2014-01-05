<#assign fileName = 'java_classes.h'/>
#ifndef JAVA_CLASSES_H
#define JAVA_CLASSES_H

<#list symbols?sort as symbol>
<#if symbol?ends_with('.h')>#include "${symbol}"</#if>
</#list>

#endif

