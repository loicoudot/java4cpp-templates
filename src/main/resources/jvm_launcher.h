/*
 * jvm_launcher.h
 *
 * Managing the instanciation of the JVM in the native process
 *
 *  Created on: 12 oct. 2013
 *      Author: Loic Oudot
 */

#ifndef JVM_LAUNCHER_H_
#define JVM_LAUNCHER_H_

#include "jni.h"

// Sets the path where to find the JNI library (inside a JRE or a JDK installation on the computer)
void jw_setJrePath(const char* jrePath);

// Methods for managing the internal list of options to pass during the creation of the JVM.
// - Once the JVM is running (after getJVM()), these methods are no longer used.
// - If a JVM already exist in the process, the list of options is ignored.
void jw_clearOptions();
void jw_addOption(const char* option);
void jw_addOptionsFromFile(const char* fileName);

// Methods for managing the internal class path of the JVM (the -Djava.class.path option).
// - Once the JVM is running (after getJVM()), these methods are no longer used.
// - If a JVM already exist in the process, the internal class path is ignored.
void jw_clearClassPath();
void jw_addClassPath(const char* path);

// Return the JVM instance of the process.
// - If no JVM is running in the process, a new one is instanciated by passing the internal list of options and class path defined above.
// - If a JVM already exist in the process, this instance is returned and the internal list of options and class path is ignored.
JavaVM* getJVM();

#endif
