//
//  IPeerMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessageDB.h"

//PeerMessageDB adapter
@interface IPeerMessageDB : NSObject<IMessageDB>
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic) NSMutableDictionary *attachments;
@property(nonatomic, assign) BOOL secret;

-(id)initWithSecret:(BOOL)secret;
@end
