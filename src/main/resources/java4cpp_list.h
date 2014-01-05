#ifndef JAVA4CPP_LIST_H
#define JAVA4CPP_LIST_H

#include "java4cpp_runtime.h"
#include "jni.h"

namespace java4cpp {

   template<typename T>
   class list
   {
   public:
	   list(jobject object) {
		   _obj = NULL;
		   setJavaObject(object);
	   }

	   jclass j4c_getClass() {
	      static jclass globalRefCls = NULL;
	      if( !globalRefCls ) {
	         JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	         jclass localRefCls = javaEnv->FindClass("java/util/List");
	         Java4CppRuntime::handleJavaException(javaEnv);
	         globalRefCls = (jclass)javaEnv->NewGlobalRef(localRefCls);
	         javaEnv->DeleteLocalRef(localRefCls);
	      }
	      return globalRefCls;
	   }

	   void setJavaObject(jobject obj)
	   {
	      if(_obj == obj) return;
	      JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	      if( _obj != NULL && javaEnv ) javaEnv->DeleteGlobalRef(_obj);
	      if(  obj != NULL && javaEnv ) {
	         jclass cls = j4c_getClass();
	         if(javaEnv->IsInstanceOf(obj, cls) == JNI_FALSE)
	         throw std::runtime_error("can't cast to \"java.util.List\"");
	         _obj = javaEnv->NewGlobalRef(obj);
	      }
	      else _obj = NULL;

	   }

	   jobject getJavaObject() const {
		   return _obj;
	   }

	   T get(int idx) {
		   return T();
	   }

   private:
	   jobject _obj;
   };

}

#endif
