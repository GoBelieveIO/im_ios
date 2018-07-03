//
//  IUser.h
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import <Foundation/Foundation.h>


@interface IUser : NSObject
@property(nonatomic) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy) NSString *identifier;
@end
