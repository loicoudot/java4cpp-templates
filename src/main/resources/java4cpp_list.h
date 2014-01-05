#ifndef JAVA4CPP_LIST_H
#define JAVA4CPP_LIST_H

#include "java4cpp_runtime.h"
#include "jni.h"

namespace java4cpp {

   template<typename T, class A = std::allocator<T> >
   class list
   {
   public:
      typedef A                           allocator_type;
      typedef T                           value_type;
      typedef T                           reference;
      typedef const T                     const_reference;
      typedef T*                          pointer;
      typedef const T*                    const_pointer;
      typedef typename A::size_type       size_type;
      typedef typename A::difference_type difference_type;

	   list(jobject object) {
		   _obj = NULL;
		   setJavaObject(object);
	   }

	   jclass j4c_getClass() const {
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

	   size_type size() const {
	      JNIEnv *javaEnv = Java4CppRuntime::attachCurrentThread();
	      static jmethodID jsize = Java4CppRuntime::getMethodID(javaEnv, j4c_getClass(), "size", "()I");
	      return (size_type)javaEnv->CallIntMethod(_obj, jsize);
	   }


	   T get(int idx) {
		   return T();
	   }

   private:
	   jobject _obj;
   };

}

#endif
