//
//  Macros.h
//  Macros
//
//  Created by DTan on 6/6/10.
//  Copyright 2010 null. All rights reserved.
//

/** A handy macro that calls release on a object if it's non-zero, and then sets 
	the object to nil if the retain count of that object in <= 0.
*/
#define releaseAndNil(objectToRelease)\
		{\
			if (objectToRelease != nil)\
			{\
				[objectToRelease release];\
				objectToRelease = nil;\
			}\
		}

/** A handy macro to set a new value on an object that also 
	calls retain on the new value being passed.
*/
#define setRetain(objectToSet,newObject)\
		{\
			if (objectToSet != newObject)\
			{\
				[newObject retain];\
				releaseAndNil (objectToSet);\
				objectToSet = newObject;\
			}\
		}

/** A handy macro to set a new value on an object by copying it.
	Note: the "new" object being passed in must conform to the "NSCopying" protocol.
*/
#define setCopy(objectToSet,newObject)\
		{\
			if (newObject != nil &&\
				objectToSet != newObject &&\
				[newObject conformsToProtocol: @protocol (NSCopying)])\
			{\
				releaseAndNil (objectToSet);\
				objectToSet = [newObject copy];\
			}\
		}

/** A handy macro to declare method(s) for a singleton class.
	To use this add the line "declareSingleton(class name)" in the class definition.
	Then put the implementSingleton (class name) macro along with the class's implementation code. 
 */
#define declareSingleton(ClassName)\
    +(ClassName*)instance;\
    +(void)clearInstance;

#define implementSingleton(ClassName)\
    static ClassName* instance;\
    +(ClassName*)instance\
    {\
        @synchronized (self)\
        {\
            if (!instance)\
                instance = [[ClassName alloc] init];\
        }\
        return instance;\
    }\
    +(void)clearInstance\
    {\
        @synchronized(self)\
        {\
            if(instance)\
                instance = nil;\
        }\
    }

#ifdef DEBUG
    #define CONDITIONLOG(condition, xx, ...) { if ((condition)) { \
                                                 NSLog(xx, ##__VA_ARGS__); \
                                               } \
                                             } ((void)0)
#else
    #define CONDITIONLOG(condition, xx, ...) ((void)0)
#endif // #ifdef DEBUG

#define PRINT_RETAIN(name, obj) \
NSLog(@"%@: retainCount %u", name, [obj retainCount]);

