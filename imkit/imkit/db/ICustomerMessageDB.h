//
//  ICustomerMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessageDB.h"

@interface ICustomerMessageDB : NSObject<IMessageDB>
@property(nonatomic, assign) int64_t storeID;
@property(nonatomic, assign) int64_t sellerID;
@property(nonatomic, assign) int64_t customerAppID;
@property(nonatomic, assign) int64_t customerID;
@property(nonatomic) NSMutableDictionary *attachments;
@end
