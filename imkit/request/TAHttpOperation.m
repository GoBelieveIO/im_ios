/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#import "TAHttpOperation.h"

#pragma mark -
#pragma mark TAHttpOperation Http动作类


@interface IMHttpOperation()
- (void)setFinished:(BOOL)isFinished;

- (void)completeOperation;

- (void)willExecSuccessBlock;

- (void)willExecFailBlock;

- (void)willStartConnection;

@property(nonatomic, retain)NSTimer *timeoutCheck;
@end

@implementation IMHttpOperation

-(id)initWithTimeoutInterval : (double)dblTimeout{

	if(self = [super init]){
		executing = NO;
        finished = NO;
		
        timeoutInterval = 60;
        responseData = [[NSMutableData alloc]init];
        if(dblTimeout > 1.0){
            timeoutInterval = (unsigned int)(dblTimeout);
        }else{
            timeoutInterval = 1;
        }
		
		self.targetURL = @"";
		self.method = @"";
		self.postBody = nil;
	}
	return self;
}

+(IMHttpOperation*)httpOperationWithTimeoutInterval : (double)dblTimeout{
    IMHttpOperation* newComm = [[IMHttpOperation alloc]initWithTimeoutInterval:dblTimeout];
    return newComm;
}

-(void)dealloc{
	NSAssert(!self.timeoutCheck, @" ");
	self.targetURL = nil;
	self.method = nil;
	self.postBody = nil;
}

-(void)reset {
    self.successCB = nil;
    self.failCB = nil;
}

-(void)cancel{
    if (self.isFinished){
		return;
	}
	[super cancel];
    
	if (urlConnection) {
		[urlConnection cancel];
		
        if (self.isExecuting){
			self.executing = NO;
		}
        if (!self.isFinished){
			self.finished = YES;
		}
    }
    [self reset];
	
	if(self.timeoutCheck){
		[self.timeoutCheck invalidate];
		self.timeoutCheck = nil;
	}
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)start {
   // Always check for cancellation before launching the task.
   if ([self isCancelled])
   {
      // Must move the operation to the finished state if it is canceled.
       self.finished = YES;
       return;
   }

   // If the operation is not canceled, begin executing the task.
   self.executing = YES;
   [self startRequest];
}

- (void)startRequest {
	NSAssert([[NSThread currentThread]isMainThread], @"must run in main thread");

	@autoreleasepool {
		//The default timeout interval is 60 seconds.
		//In iOS versions prior to iOS 6, the minimum (and default) timeout interval for any request containing a request body was 240 seconds.
		NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.targetURL]
																  cachePolicy:NSURLRequestUseProtocolCachePolicy
															  timeoutInterval:timeoutInterval
										   ];
        
		if (NULL == urlRequest) {
			//delay callback to next run loop
			[self performSelectorOnMainThread: @selector(execCreateConnectDidFail)
								   withObject: nil
								waitUntilDone: NO];
			return;
		}


		[urlRequest setHTTPMethod:self.method];
      
		if (self.headers != nil) {
			[urlRequest setAllHTTPHeaderFields:self.headers];
		}

		if(NULL == self.postBody){
			NSData* data = [[NSData alloc] init];
			[urlRequest setHTTPBody:data];
		}else{
			[urlRequest setHTTPBody:self.postBody];
		}

		urlConnection = [[NSURLConnection alloc]initWithRequest:urlRequest
													   delegate:self
											   startImmediately:NO];
        
		if(NULL == urlConnection){
			//delay callback to next run loop
			[self performSelectorOnMainThread:@selector(execCreateConnectDidFail)
                                   withObject:nil
                                waitUntilDone:NO];
			return;
		}else{
			
			self.timeoutCheck = [NSTimer scheduledTimerWithTimeInterval: 1.0
															target: self
														  selector: @selector(checkHttpTimeout:)
														  userInfo: [NSMutableArray arrayWithObject:
																	 [NSNumber numberWithUnsignedInteger:0]
																	 ]
														   repeats: YES];
			
			
			[self willStartConnection];
			
			[urlConnection start];
		}
	}
}

-(void)checkHttpTimeout:(NSTimer*)timer{
	NSAssert(urlConnection, @" ");
	
	NSMutableArray* checkCount = [timer userInfo];
	NSUInteger ui = [(NSNumber*)[checkCount objectAtIndex:0] unsignedIntegerValue];
	
	++ui;

	if(ui < timeoutInterval){
		[checkCount removeAllObjects];
		[checkCount addObject:[NSNumber numberWithUnsignedInteger:ui]
		 ];
		return;
	}

	FailBlock block = self.failCB;
	
	[self cancel];
	
	if(block != nil) {
		block(self, IMHttpOperationTimeout);
	}
}

/*
 创建连接错误时的处理
 */
-(void)execCreateConnectDidFail{// it's on main thread now
	NSAssert(!self.timeoutCheck, @" ");
    [self willExecFailBlock];
    
	if(self.failCB){
	    self.failCB(self, IMHttpOperationFailToCreateConnect);
    }
	[self completeOperation];
}
/*
 尝试执行连接成功时的处理（即使成功，但可能超时检测或手头取消已经抢在前面处理过了，他们处理过后，通信对象的communicating都返回NO）
 */
-(void)execConnectDidFinish{// it's on main thread now
	[self.timeoutCheck invalidate];
	self.timeoutCheck = nil;
	
    [self willExecSuccessBlock];
    
	if(self.successCB){
        self.successCB(self, self.responseHeader, responseData);
    }
    [self completeOperation];
}
/*
 尝试执行连接错误时的处理（即使错误，但可能超时检测或手头取消已经抢在前面处理过了，他们处理过后，通信对象的communicating都返回NO）
 */
-(void)execConnectDidFail{// it's on main thread now
	//TALogD(@"TAHttpOperation %p, ConnectDidFail", self);
	
    [self.timeoutCheck invalidate];
	self.timeoutCheck = nil;
	
    [self willExecFailBlock];
    
	if(self.failCB){
	    self.failCB(self, IMHttpOperationServerNotFound);
    }
	[self completeOperation];
}

+(NSString*)descriptionOfError: (IMHttpOperationError) error{
	switch (error) {
		case IMHttpOperationFailToCreateConnect:
			return @"无法连接对象";
			
		case IMHttpOperationServerNotFound:
			return @"未找到服务器";
			
		case IMHttpOperationTimeout:
			return @"连接超时";
			
		case IMHttpOperationServerUnknown:
			return @"服务器发生未知错误";

		default:
			return @"未知错误";
	}
}

- (void)willStartConnection{
	
}

- (void)willExecSuccessBlock{
    
}

- (void)willExecFailBlock{
    
}

- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)completeOperation {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

@end

@implementation IMHttpOperation(NSURLConnectionDelegate)
#pragma mark -
#pragma mark NSURLConnection相关代理在 TACommHttp 中的实现
// 即将接收数据
- (void)connection:(NSURLConnection*)connection 
didReceiveResponse:(NSURLResponse *)response{
    self.responseHeader = response;
}

// 正在接收数据
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data{
	[responseData appendData:data];
}

// 通信结束：成功
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	[self execConnectDidFinish];
}

// 通信结束：失败
- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error{
	[self execConnectDidFail];
}

@end
