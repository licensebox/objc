#import <Foundation/Foundation.h>
#include <licensebox_json.h>
@protocol LBLicenseboxCallbacks <NSObject>
@optional
- (void)licenseboxSignInURL:(NSString *)url userCode:(NSString *)code;
- (double)licenseboxClock;
- (NSString *)licenseboxMachineBinding;
- (BOOL)licenseboxCancelled;
@end
@interface LBLicensebox : NSObject {
@private
 lb_client *_client;
 id<LBLicenseboxCallbacks> _callbacks;
 NSRecursiveLock *_lock;
 NSException *_callbackFailure;
 BOOL _busy;
}
- (instancetype)initWithProduct:(NSString *)product keys:(NSDictionary *)keys options:(NSDictionary *)options callbacks:(id<LBLicenseboxCallbacks>)callbacks error:(NSError **)error;
- (BOOL)close:(NSError **)error;
- (id)lease:(NSError **)error;
- (id)heartbeatModule:(NSString *)module error:(NSError **)error;
- (id)requireModule:(NSString *)module error:(NSError **)error;
- (id)status:(NSError **)error;
- (id)signInWithTimeout:(double)timeout error:(NSError **)error;
- (BOOL)logout:(NSError **)error;
- (id)modules:(NSError **)error;
- (id)requests:(NSError **)error;
- (id)requestModules:(NSArray *)modules note:(NSString *)note error:(NSError **)error;
- (NSString *)accessLink:(NSError **)error;
- (BOOL)recordCommand:(NSString *)command success:(BOOL)success elapsed:(double)elapsed error:(NSError **)error;
+ (NSString *)deriveBindingForProduct:(NSString *)product source:(NSString *)source rawID:(NSString *)raw error:(NSError **)error;
+ (NSString *)nativeBindingForProduct:(NSString *)product error:(NSError **)error;
+ (id)verifyLease:(NSString *)token product:(NSString *)product keys:(NSDictionary *)keys now:(double)now error:(NSError **)error;
@end
