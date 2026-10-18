#import "Licensebox.h"
@interface Fixture : NSObject <LBLicenseboxCallbacks>{NSDictionary*_r;}
- (id)initWithRequest:(NSDictionary*)r;
@end
@implementation Fixture
- (id)initWithRequest:(NSDictionary*)r{if((self=[super init]))_r=[r retain];return self;}
- (void)dealloc{[_r release];[super dealloc];}
- (double)licenseboxClock{return [[_r objectForKey:@"now"]doubleValue];}
- (NSString*)licenseboxMachineBinding{return [_r objectForKey:@"binding"]?:@"";}
- (void)licenseboxSignInURL:(NSString*)url userCode:(NSString*)code{(void)url;(void)code;}
@end
int main(void){@autoreleasepool{NSError*error=nil;NSData*input=[[NSFileHandle fileHandleWithStandardInput]readDataToEndOfFile];NSDictionary*r=[NSJSONSerialization JSONObjectWithData:input options:0 error:&error];NSString*op=[r objectForKey:@"op"],*p=[r objectForKey:@"product"];id v=nil;
if([op isEqual:@"derive"])v=[LBLicensebox deriveBindingForProduct:p source:[r objectForKey:@"source"] rawID:[r objectForKey:@"raw_id"] error:&error];
else if([op isEqual:@"native"])v=[LBLicensebox nativeBindingForProduct:p error:&error];
else if([op isEqual:@"verify"])v=[LBLicensebox verifyLease:[r objectForKey:@"token"] product:p keys:[r objectForKey:@"keys"] now:[[r objectForKey:@"now"]doubleValue] error:&error];
else{Fixture*fixture=[[[Fixture alloc]initWithRequest:r]autorelease];NSMutableDictionary*opts=[NSMutableDictionary dictionaryWithObjectsAndKeys:[r objectForKey:@"server"],@"server",[r objectForKey:@"directory"],@"directory",@"conformance",@"version",nil];if([r objectForKey:@"ca_bundle"])[opts setObject:[r objectForKey:@"ca_bundle"] forKey:@"ca_bundle"];LBLicensebox*c=[[LBLicensebox alloc]initWithProduct:p keys:[r objectForKey:@"keys"] options:opts callbacks:fixture error:&error];
if(c){if([op isEqual:@"heartbeat"])v=[c heartbeatModule:[r objectForKey:@"module"]?:@"core" error:&error];else if([op isEqual:@"heartbeat-repeat"]){v=[c heartbeatModule:@"core" error:&error];if(!error)v=[c heartbeatModule:@"core" error:&error];}else if([op isEqual:@"heartbeat-after-require"]){v=[c requireModule:@"core" error:&error];if(!error)v=[c heartbeatModule:@"core" error:&error];}else if([op isEqual:@"lease"])v=[c lease:&error];else if([op isEqual:@"require"])v=[c requireModule:[r objectForKey:@"module"]?:@"core" error:&error];else if([op isEqual:@"repeat"]){v=[c requireModule:@"core" error:&error];if(!error)v=[c requireModule:@"core" error:&error];}else if([op isEqual:@"status"])v=[c status:&error];else if([op isEqual:@"sign_in"])v=[c signInWithTimeout:3 error:&error];else if([op isEqual:@"logout"]){[c logout:&error];v=[NSNull null];}else if([op isEqual:@"modules"])v=[c modules:&error];else if([op isEqual:@"requests"])v=[c requests:&error];else if([op isEqual:@"request"])v=[c requestModules:@[@"export"] note:@"café – test" error:&error];else if([op isEqual:@"access-link"])v=[c accessLink:&error];else if([op isEqual:@"record"]){[c recordCommand:@"export" success:YES elapsed:.125 error:&error];if(!error)[c recordCommand:@"export" success:NO elapsed:.025 error:&error];v=[NSNull null];}[c close:NULL];[c release];}}
NSDictionary*a=error?@{@"ok":@(NO),@"error":[[error userInfo]objectForKey:@"code"]?:@"protocol_error"}:@{@"ok":@(YES),@"value":v?:[NSNull null]};NSData*out=[NSJSONSerialization dataWithJSONObject:a options:0 error:NULL];[[NSFileHandle fileHandleWithStandardOutput]writeData:out];puts("");return 0;}}
