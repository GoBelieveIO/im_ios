//
//  EPeerMessageDB.h
//  gobelieve
//
//  Created by houxh on 2018/1/17.
//

#import <Foundation/Foundation.h>
#import "SQLPeerMessageDB.h"
#import "IMessageDB.h"

@interface EPeerMessageDB : SQLPeerMessageDB<IMessageDB>
+(EPeerMessageDB*)instance;

@end
