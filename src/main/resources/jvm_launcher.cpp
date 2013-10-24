/*
 * jvm_launcher.cpp
 *
 *  Created on: 12 oct. 2013
 *      Author: Loic Oudot
 */
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <dlfcn.h>
#include <stdexcept>

#include "jvm_launcher.h"

#define CLASS_PATH "-Djava.class.path="

typedef std::vector<std::string> JvmOptions;

JavaVM* _pVMJvm = NULL;
std::string _jrePath;
JvmOptions _options;
JvmOptions _classPath;

typedef jint (*JNI_GetCreatedJavaVMs_t)(JavaVM **, jsize, jsize *);
typedef jint (*JNI_CreateJavaVM_t)(JavaVM **pvm, void **penv, void *args);


void jw_setJrePath(const char* jrePath)
{
   _jrePath = jrePath;
}

void jw_clearOptions()
{
   _options.clear();
}

void jw_addOption(const char* option)
{
   _options.push_back(option);
}

void jw_addOptionsFromFile(const char* fileName)
{
   std::ifstream file( fileName );
   if( file.good() )
   {
      std::string option;
      while( std::getline(file, option) )
      {
         if( !option.empty() && option.at(0) != '#')
         {
            _options.push_back( option );
         }
      }
   }
}

void jw_clearClassPath()
{
   _classPath.clear();
}

void jw_addClassPath(const char* path)
{
   if( std::find(_classPath.begin(), _classPath.end(), path) != _classPath.end() )
      return;

   _classPath.push_back(path);
}

void setClassPath()
{
   std::string classPath = CLASS_PATH;

   // find classpath in options
   for(JvmOptions::iterator it = _options.begin(); it != _options.end(); ++it)
   {
      if( it->find(CLASS_PATH) != std::string::npos )
      {
         classPath = *it;
         _options.erase(it);
         break;
      }
   }

   for(JvmOptions::iterator it = _classPath.begin(); it != _classPath.end(); ++it)
   {
      if( classPath.find(*it) == std::string::npos )
      {
         if( classPath != CLASS_PATH )
            classPath += ";";
         classPath += *it;
      }
   }

   _options.push_back(classPath);
}

void initJVM()
{
   if( _pVMJvm != NULL )
      return;

   JNIEnv* pVMEnv = NULL;
	void *handle = dlopen(_jrePath.c_str(), RTLD_NOW);
	if( handle == NULL )
		throw std::runtime_error("initJVM: unable to load libjvm.");

	JNI_GetCreatedJavaVMs_t JNI_GetCreatedJavaVMs = (JNI_GetCreatedJavaVMs_t)dlsym(handle, "JNI_GetCreatedJavaVMs");
	if( JNI_GetCreatedJavaVMs == NULL )
		JNI_GetCreatedJavaVMs = (JNI_GetCreatedJavaVMs_t)dlsym(handle, "JNI_GetCreatedJavaVMs_Impl");
	if( JNI_GetCreatedJavaVMs == NULL )
		throw std::runtime_error("initJVM: unable to find method JNI_GetCreatedJavaVMs.");

	// try to get an already created JVM
	jsize nbVMs = 0;
	JNI_GetCreatedJavaVMs(&_pVMJvm, 1, &nbVMs);
	if( nbVMs == 0 )
	{
		 // Else : create a new JVM
		setClassPath();
		long nbOptions = (long)_options.size();
		JavaVMOption *aOptions = new JavaVMOption[nbOptions];
		for( long i = 0; i < nbOptions; ++i )
			aOptions[i].optionString = (char*)_options[i].c_str();

		JavaVMInitArgs oVMArgs;
		memset(&oVMArgs, 0, sizeof(oVMArgs));
		oVMArgs.version = JNI_VERSION_1_6;
		oVMArgs.nOptions = nbOptions;
		oVMArgs.options = aOptions;

		JNI_CreateJavaVM_t JNI_CreateJavaVM = (JNI_CreateJavaVM_t)dlsym(handle, "JNI_CreateJavaVM");
		if( JNI_CreateJavaVM == NULL )
			JNI_CreateJavaVM = (JNI_CreateJavaVM_t)dlsym(handle, "JNI_CreateJavaVM_Impl");
		if( JNI_CreateJavaVM == NULL )
			throw std::runtime_error("initJVM: unable to find method JNI_CreateJavaVM.");

		jint result = JNI_CreateJavaVM(&_pVMJvm, (void**)&pVMEnv, (void*)&oVMArgs);
		if( result != 0 ) {
			std::ostringstream oss;
			oss << "initJVM: can't create new JVM (" << result << ").";
			 throw std::runtime_error(oss.str());
		}

		delete[] aOptions;
	}
}

JavaVM* getJVM()
{
   if( _pVMJvm == NULL )
      initJVM();

   if( _pVMJvm == NULL )
      throw std::runtime_error("getJVM: no JVM.");

   return _pVMJvm;
}

//--------------------------------------------------------------------
// End of file
//--------------------------------------------------------------------
