java4cpp-templates
==================

Common mappings and templates files for java4cpp project

Gets full informations directly on the [java4cpp-core](https://github.com/loicoudot/java4cpp-core/wiki) page project.

## Mappings ##

This artifact contains the `base-mappings.xml` file that define 
common reserved keywords and specific mapping 
for `java.lang.Class` and `java.lang.Throwable` to avoid unecessary proxies generation.

It can be used in the `mappingsFile` parameter of java4cpp-maven-plugin 
or in the `java4cpp.mappingsFile` system properties.

## Templates ##

This artifact contains the `base-templates.xml` file that define a comprehensive 
environement for using the generated C++ proxies files inside your C++ project.

It can be used in the `templatesFile` parameter of java4cpp-maven-plugin 
or in the `java4cpp.templatesFile` system properties.

This artifact contains also `string-templates.xml` for transparently converting 
the `java.lang.String` class in `std:string` object.

## Using the proxies ##

Once java4cpp generate the proxies, il also adds some files for the runtime execution.
The most usefull file is `jvm-launcher.h` that lets you define the path 
of your installed JRE/JDK, and add some parameters to the JVM like the classpath for exemple.

```cpp
#include "java4cpp/jvm_launcher.h"
#include "java4cpp/java_classes.h"

int main(void)
{
	// Launch a JVM in the current process
	jw_setJrePath("/Library/Java/JavaVirtualMachines/1.7.0.jdk/Contents/Home/jre/lib/server/libjvm.dylib");
	jw_addClassPath("../jars/java4cpp-sample-1.0.0.jar");
	// Create a java.lang.Double instance in the JVM and return a C++ proxy 
	java::util::Double proxy(12.0);
}
```
 