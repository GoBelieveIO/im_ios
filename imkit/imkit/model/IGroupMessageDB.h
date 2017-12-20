//
//  IGroupMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessageDB.h"

@interface IGroupMessageDB : NSObject<IMessageDB>
@property(nonatomic, assign) int64_t groupID;
@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic) NSMutableDictionary *attachments;
@end
