

#import <Foundation/Foundation.h>

typedef enum{
	
	IMHttpOperationFailToCreateConnect,    // 创建连接失败
	IMHttpOperationServerNotFound,         // 未找到服务器
	IMHttpOperationTimeout,                // 连接超时
	IMHttpOperationServerUnknown,          // 服务器发生未知错误
	IMHttpOperationUnknown                 // 未知错误
	
}IMHttpOperationError;

@class IMHttpOperation;

typedef void (^SuccessBlock)(IMHttpOperation*commObj, NSURLResponse *response, NSData *data);
typedef void (^FailBlock)(IMHttpOperation*commObj, IMHttpOperationError error);

#pragma mark -
#pragma mark TAHttpOperation Http通信操作类

@interface IMHttpOperation : NSOperation {
@protected
	BOOL                executing;
    BOOL                finished;
	NSURLConnection     *urlConnection;
	NSMutableData       *responseData;
	NSUInteger          timeoutInterval;
}

@property(nonatomic, copy)NSString *targetURL;
@property(nonatomic, copy)NSString *method;
@property(nonatomic, copy)NSDictionary *headers;
@property(nonatomic, copy)NSData *postBody;
@property(nonatomic, copy)SuccessBlock successCB;
@property(nonatomic, copy)FailBlock failCB;
@property(nonatomic)NSURLResponse *responseHeader;

-(id)initWithTimeoutInterval : (double)dblTimeout;


+(IMHttpOperation*)httpOperationWithTimeoutInterval : (double)dblTimeout;


+(NSString*)descriptionOfError: (IMHttpOperationError) error;

@end
