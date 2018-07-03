//
//  EPeerMessageDB.h
//  gobelieve
//
//  Created by houxh on 2018/1/17.
//

#import <Foundation/Foundation.h>
#import "SQLPeerMessageDB.h"
@interface EPeerMessageDB : SQLPeerMessageDB
+(EPeerMessageDB*)instance;
@end
