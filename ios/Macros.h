#include <jsi/jsilib.h>
#include <jsi/jsi.h>

#ifndef Macros_h
#define Macros_h

#define JSI_HOST_FUNCTION(NAME, ARGS_COUNT)                                   \
            jsi::Function::createFromHostFunction(              \
                *runtime_,                                      \
                jsi::PropNameID::forUtf8(*runtime_, NAME),      \
                ARGS_COUNT,                                     \
                [=](jsi::Runtime &runtime,                      \
                    const jsi::Value &thisArg,                  \
                    const jsi::Value *args,                     \
                    size_t count) -> jsi::Value


#define STR_FROM_ARGS(index)                                  \
args[index].asString(runtime).utf8(runtime);

#define PAIR(first, second)                                  \
std::make_pair<jsi::Value, std::string>(first, second);

#define BOOL_FROM_ARGS(index)                                  \
args[index].getBool();

#define NUM_FROM_ARGS(index)                                  \
args[index].asNumber();


#define TASK_START(...)                                             \
auto callback = make_shared<jsi::Value>(callbackHolder.asObject(runtime)); \
auto task = [&runtime, callback, invoker = jsCallInvoker_, __VA_ARGS__]()

#define TASK_END()                                             \
pool->queueWork(task);                                          \
return jsi::Value::undefined();

#define IF_ASYNC(index, ...)                                \
const jsi::Value &callbackHolder = args[index];                \
if (callbackHolder.isObject() && callbackHolder.asObject(runtime).isFunction(runtime))

#define INVOKE_CALLBACK(value)                                           \
callback->asObject(runtime).asFunction(runtime).call(runtime, value);

#define INVOKE_ASYNC(...)                                             \
invoker->invokeAsync([&runtime, callback, __VA_ARGS__]()              \

#define STARTS_WITH(first, second)                                             \
first.find(second) == 0

#define NOT_STARTS_WITH(first, second)                                             \
first.find(second) != 0

#define ANDROID_DATA_PROVIDER_FUNCTION(...) \
DataProvider dataProvider = [__VA_ARGS__, sd = sdCardDir_, an = android](const std::shared_ptr<ValueCallback>& callback, bool useFastImplementation)

#define IIO(index, ...)                                                                             \
const jsi::Value &callbackHolder = args[index];                                                     \
if (callbackHolder.isObject() && callbackHolder.asObject(runtime).isFunction(runtime)) {           \
    auto callback = make_shared<jsi::Value>(callbackHolder.asObject(runtime));                     \
    auto task = [&runtime, callback, invoker = jsCallInvoker_, __VA_ARGS__]() {                     \
                                                                                                    \
    };                                                                                              \
    pool->queueWork(task);                                                                          \
    return jsi::Value::undefined();                                                                  \
}

#endif
