#import "Licensebox.h"
@interface ThrowingCallbacks:NSObject <LBLicenseboxCallbacks>
@end
@implementation ThrowingCallbacks
- (NSString*)licenseboxMachineBinding{[NSException raise:@"ExpectedCallbackFailure" format:@"synthetic failure"];return nil;}
@end
int main(void){@autoreleasepool{NSString*d=[NSTemporaryDirectory()stringByAppendingPathComponent:[[NSProcessInfo processInfo]globallyUniqueString]];for(int i=0;i<100;i++){NSError*e=nil;LBLicensebox*c=[[LBLicensebox alloc]initWithProduct:@"demo" keys:@{@"test-key":@"A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg"} options:@{@"directory":d} callbacks:nil error:&e];NSCAssert(c!=nil,@"create failed");NSCAssert([c close:&e],@"close failed");NSCAssert([c status:&e]==nil,@"closed accepted");[c release];}NSError*e=nil;ThrowingCallbacks*cb=[[[ThrowingCallbacks alloc]init]autorelease];LBLicensebox*c=[[LBLicensebox alloc]initWithProduct:@"demo" keys:@{@"test-key":@"AxGMH70lcToRW2eI_-0sCzJ7pL3sgo8XVaF4sk42v8I"} options:@{@"directory":[d stringByAppendingString:@"-callback"],@"server":@"http://127.0.0.1:1"} callbacks:cb error:&e];NSCAssert(c!=nil,@"create failed");NSCAssert([c signInWithTimeout:.1 error:&e]==nil,@"callback failure ignored");NSCAssert([[[e userInfo]objectForKey:@"code"]isEqual:@"callback_failed"],@"wrong callback failure");[c close:NULL];[c release];return 0;}}
