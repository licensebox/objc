#import "Licensebox.h"
#include <math.h>
static BOOL fail(NSError **error,NSString*code,NSString*detail){if(error)*error=[NSError errorWithDomain:@"Licensebox" code:1 userInfo:@{@"code":code,NSLocalizedDescriptionKey:detail?:code}];return NO;}
static NSString* name(lb_result rc){return [NSString stringWithUTF8String:lb_result_code(rc)];}
static NSData* json(id v,NSError**e){return [NSJSONSerialization dataWithJSONObject:v options:0 error:e];}
static BOOL clean(NSString*s){return s&&[s rangeOfString:[NSString stringWithFormat:@"%C",(unichar)0]].location==NSNotFound;}
@interface LBLicensebox (Internal)
- (void)notifyURL:(const char*)url code:(const char*)code;
- (double)clockValue;
- (int)bindingValue:(char*)out capacity:(size_t)capacity;
- (int)cancelValue;
- (id)call:(NSString*)op arguments:(NSDictionary*)args error:(NSError**)error;
@end
static void signin(void*x,const char*u,const char*c){[(LBLicensebox*)x notifyURL:u code:c];}
static double clock_cb(void*x){return [(LBLicensebox*)x clockValue];}
static int binding(void*x,char*out,size_t cap){return [(LBLicensebox*)x bindingValue:out capacity:cap];}
static int cancel_cb(void*x){return [(LBLicensebox*)x cancelValue];}
@implementation LBLicensebox
- (void)remember:(NSException*)exception{if(!_callbackFailure)_callbackFailure=[exception retain];}
- (void)notifyURL:(const char*)u code:(const char*)c{@try{[_callbacks licenseboxSignInURL:[NSString stringWithUTF8String:u] userCode:[NSString stringWithUTF8String:c]];}@catch(NSException*e){[self remember:e];}}
- (double)clockValue{@try{double n=[_callbacks licenseboxClock];if(!isfinite(n))[NSException raise:@"InvalidClock" format:@"Clock must be finite"];return n;}@catch(NSException*e){[self remember:e];return 0;}}
- (int)bindingValue:(char*)out capacity:(size_t)cap{@try{NSString*s=[_callbacks licenseboxMachineBinding];if(!clean(s)||strlen([s UTF8String])>=cap)[NSException raise:@"InvalidBinding" format:@"Invalid machine binding"];strcpy(out,[s UTF8String]);return 0;}@catch(NSException*e){[self remember:e];return 1;}}
- (int)cancelValue{if(_callbackFailure)return 1;@try{return [_callbacks respondsToSelector:@selector(licenseboxCancelled)]&&[_callbacks licenseboxCancelled];}@catch(NSException*e){[self remember:e];return 1;}}
- (instancetype)initWithProduct:(NSString*)p keys:(NSDictionary*)keys options:(NSDictionary*)options callbacks:(id<LBLicenseboxCallbacks>)callbacks error:(NSError**)error {
 if(!(self=[super init]))return nil;_callbacks=[callbacks retain];_lock=[[NSRecursiveLock alloc]init];
 if(!clean(p)){fail(error,@"invalid_argument",nil);[self release];return nil;}
 NSMutableDictionary*o=[NSMutableDictionary dictionaryWithDictionary:options?:@{}];[o setObject:p forKey:@"product"];[o setObject:keys forKey:@"keys"];
 NSData*data=json(o,error);if(!data){[self release];return nil;}NSMutableData*terminated=[NSMutableData dataWithData:data];[terminated appendBytes:"" length:1];
 lb_callbacks cb={self,[_callbacks respondsToSelector:@selector(licenseboxSignInURL:userCode:)]?signin:NULL,[_callbacks respondsToSelector:@selector(licenseboxClock)]?clock_cb:NULL,[_callbacks respondsToSelector:@selector(licenseboxMachineBinding)]?binding:NULL,cancel_cb};
 lb_result rc=lb_client_create_json([terminated bytes],&cb,&_client);if(rc||_callbackFailure){fail(error,_callbackFailure?@"callback_failed":name(rc),[_callbackFailure reason]);[self release];return nil;}return self;
}
- (void)dealloc{if(_client)lb_client_destroy(_client);[_callbacks release];[_lock release];[_callbackFailure release];[super dealloc];}
- (BOOL)close:(NSError**)error{[_lock lock];if(_busy){[_lock unlock];return fail(error,@"invalid_argument",@"Callbacks must not reenter client");}if(_client){lb_client_destroy(_client);_client=NULL;}[_lock unlock];return YES;}
- (id)call:(NSString*)op arguments:(NSDictionary*)args error:(NSError**)error {
 [_lock lock];if(_busy){[_lock unlock];fail(error,@"invalid_argument",@"Callbacks must not reenter client");return nil;}if(!_client){[_lock unlock];fail(error,@"closed",nil);return nil;}@try{
 NSData*d=json(args,error);if(!d)return nil;NSMutableData*a=[NSMutableData dataWithData:d];[a appendBytes:"" length:1];char*out=NULL;_busy=YES;lb_result rc=lb_client_call_json(_client,[op UTF8String],[a bytes],&out);_busy=NO;
 if(_callbackFailure){lb_free(out);fail(error,@"callback_failed",[_callbackFailure reason]);[_callbackFailure release];_callbackFailure=nil;return nil;}
 if(rc){lb_free(out);const char*c=lb_error_code(_client);NSString*code=(rc==LB_INVALID_ARGUMENT||!c||!strcmp(c,"ok"))?name(rc):[NSString stringWithUTF8String:c];fail(error,code,[NSString stringWithUTF8String:lb_error_message(_client)]);return nil;}
 if(!out){fail(error,@"protocol_error",nil);return nil;}NSData*data=[NSData dataWithBytes:out length:strlen(out)];lb_free(out);return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
 }@finally{_busy=NO;[_lock unlock];}
}
- (id)lease:(NSError**)e{return [self call:@"lease" arguments:@{} error:e];}
- (id)heartbeatModule:(NSString*)m error:(NSError**)e{return [self call:@"heartbeat" arguments:@{@"module":m} error:e];}
- (id)requireModule:(NSString*)m error:(NSError**)e{return [self call:@"require" arguments:@{@"module":m} error:e];}
- (id)status:(NSError**)e{return [self call:@"status" arguments:@{} error:e];}
- (id)signInWithTimeout:(double)t error:(NSError**)e{return [self call:@"sign_in" arguments:@{@"timeout":@(t)} error:e];}
- (BOOL)logout:(NSError**)e{return [self call:@"logout" arguments:@{} error:e]!=nil;}
- (id)modules:(NSError**)e{return [self call:@"modules" arguments:@{} error:e];}
- (id)requests:(NSError**)e{return [self call:@"requests" arguments:@{} error:e];}
- (id)requestModules:(NSArray*)m note:(NSString*)n error:(NSError**)e{return [self call:@"request" arguments:@{@"modules":m,@"note":n?:@""} error:e];}
- (NSString*)accessLink:(NSError**)e{return [self call:@"access-link" arguments:@{} error:e];}
- (BOOL)recordCommand:(NSString*)c success:(BOOL)s elapsed:(double)t error:(NSError**)e{return [self call:@"record" arguments:@{@"command":c,@"success":@(s),@"elapsed":@(t)} error:e]!=nil;}
+ (NSString*)deriveBindingForProduct:(NSString*)p source:(NSString*)s rawID:(NSString*)r error:(NSError**)e {
 while([r length]&&[r characterAtIndex:[r length]-1]==0)r=[r substringToIndex:[r length]-1];if(!clean(p)||!clean(s)||!clean(r)){fail(e,@"identity_unavailable",nil);return nil;}
 char out[128];lb_result rc=lb_derive_binding([p UTF8String],[s UTF8String],[r UTF8String],out,sizeof(out));if(rc){fail(e,name(rc),nil);return nil;}return [NSString stringWithUTF8String:out];
}
+ (NSString*)nativeBindingForProduct:(NSString*)p error:(NSError**)e{if(!clean(p)){fail(e,@"invalid_argument",nil);return nil;}char out[128];lb_result rc=lb_native_binding([p UTF8String],out,sizeof(out));if(rc){fail(e,name(rc),nil);return nil;}return [NSString stringWithUTF8String:out];}
+ (id)verifyLease:(NSString*)t product:(NSString*)p keys:(NSDictionary*)k now:(double)n error:(NSError**)e {
 if(!clean(t)||!clean(p)){fail(e,@"invalid_argument",nil);return nil;}NSData*d=json(k,e);if(!d)return nil;NSMutableData*a=[NSMutableData dataWithData:d];[a appendBytes:"" length:1];char*out=NULL;lb_result rc=lb_verify_lease_json([t UTF8String],[p UTF8String],[a bytes],n,&out);if(rc){lb_free(out);fail(e,name(rc),nil);return nil;}NSData*v=[NSData dataWithBytes:out length:strlen(out)];lb_free(out);return [NSJSONSerialization JSONObjectWithData:v options:NSJSONReadingAllowFragments error:e];
}
@end
