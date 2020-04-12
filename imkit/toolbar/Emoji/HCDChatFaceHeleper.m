//
//  HCDChatFaceHeleper.m
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import "HCDChatFaceHeleper.h"
#import "HCDChatFace.h"

@interface NSString (T)
- (NSString *)trim;
@end

@implementation NSString (T)
- (NSString *)trim {
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end



static HCDChatFaceHeleper * faceHeleper = nil;

static const NSString *kWXFaces = @"微笑, 撇嘴, 色, 发呆, 得意, 流泪, 害羞, 闭嘴, 睡, 大哭, 尴尬, 发怒, 调皮, 呲牙,惊讶, 难过, 冷汗, 抓狂, 吐, 偷笑, 愉快, 白眼, 饥饿, 困, 惊恐, 流汗, 憨笑, 悠闲,奋斗, 咒骂, 疑问, 嘘, 晕, 衰, 骷髅, 敲打, 再见, 擦汗, 抠鼻, 鼓掌, 坏笑, 左哼哼,右哼哼, 哈欠, 鄙视, 委屈, 快哭了, 阴险, 亲亲, 可怜, 菜刀, 西瓜, 啤酒, 咖啡, 猪头, 玫瑰, 凋谢, 嘴唇, 爱心, 心碎, 蛋糕, 炸弹, 便便, 月亮, 太阳,拥抱, 强, 弱, 握手, 胜利, 抱拳, 勾引, 拳头, OK, 跳跳,发抖, 怄火, 转圈, 嘿哈, 捂脸, 奸笑, 机智, 皱眉,  耶, 红包, 發, 福";

static const NSString *totalFaces = @"微笑, 撇嘴, 色, 发呆, 得意, 流泪, 害羞, 闭嘴, 睡, 大哭, 尴尬, 发怒, 调皮, 呲牙,惊讶, 难过, 酷, 冷汗, 抓狂, 吐, 偷笑, 愉快, 白眼, 傲慢, 饥饿, 困, 惊恐, 流汗, 憨笑, 悠闲,  +奋斗, 咒骂, 疑问, 嘘, 晕, 疯了, 衰, 骷髅, 敲打, 再见, 擦汗, 抠鼻, 鼓掌, 糗大了, 坏笑, 左哼哼,右哼哼, 哈欠, 鄙视, 委屈, 快哭了, 阴险, 亲亲, 吓, 可怜, 菜刀, 西瓜, 啤酒, 篮球, 乒乓, 咖啡,饭, 猪头, 玫瑰, 凋谢, 嘴唇, 爱心, 心碎, 蛋糕, 闪电, 炸弹, 刀, 足球, 瓢虫, 便便, 月亮, 太阳,礼物, 拥抱, 强, 弱, 握手, 胜利, 抱拳, 勾引, 拳头, 差劲, 爱你, NO, OK, 爱情, 飞吻, 跳跳,发抖, 怄火, 转圈, 磕头, 回头, 跳绳, 投降, 激动, 乱舞, 献吻, 左太极, 右太极, 机智, 皱眉, 红包, 囧, 奋斗, 嘿哈, 捂脸, 奸笑, 耶, 發,福";
@implementation HCDChatFaceHeleper


+ (HCDChatFaceHeleper * )sharedFaceHelper {
    if (!faceHeleper) {
        faceHeleper = [[HCDChatFaceHeleper alloc] init];
    }
    return faceHeleper;
}




#pragma mark - Public Methods
- (NSArray<HCDChatFace *>*)getFaceArrayByGroupID:(NSString *)groupID {
    if ([groupID isEqualToString:@"normal_face"]) {
        return [self getNormalFaceArray];
    } else if ([groupID isEqualToString:@"unicode_emoji"]) {
        return [self getUnicodeEmojiArray];
    }
    return nil;
}

- (NSArray<HCDChatFace *>*)getUnicodeEmojiArray {
    NSMutableArray *array = [NSMutableArray new];
    NSMutableArray * localAry = [[NSMutableArray alloc] initWithObjects:
                                 [HCDChatFace emojiWithCode:0x1F60a],
                                 [HCDChatFace emojiWithCode:0x1F603],
                                 [HCDChatFace emojiWithCode:0x1F609],
                                 [HCDChatFace emojiWithCode:0x1F62e],
                                 [HCDChatFace emojiWithCode:0x1F60b],
                                 [HCDChatFace emojiWithCode:0x1F60e],
                                 [HCDChatFace emojiWithCode:0x1F621],
                                 [HCDChatFace emojiWithCode:0x1F616],
                                 [HCDChatFace emojiWithCode:0x1F633],
                                 [HCDChatFace emojiWithCode:0x1F61e],
                                 [HCDChatFace emojiWithCode:0x1F62d],
                                 [HCDChatFace emojiWithCode:0x1F610],
                                 [HCDChatFace emojiWithCode:0x1F607],
                                 [HCDChatFace emojiWithCode:0x1F62c],
                                 [HCDChatFace emojiWithCode:0x1F606],
                                 [HCDChatFace emojiWithCode:0x1F631],
                                 [HCDChatFace emojiWithCode:0x1F385],
                                 [HCDChatFace emojiWithCode:0x1F634],
                                 [HCDChatFace emojiWithCode:0x1F615],
                                 [HCDChatFace emojiWithCode:0x1F637],
                                 [HCDChatFace emojiWithCode:0x1F62f],
                                 [HCDChatFace emojiWithCode:0x1F60f],
                                 [HCDChatFace emojiWithCode:0x1F611],
                                 [HCDChatFace emojiWithCode:0x1F496],
                                 [HCDChatFace emojiWithCode:0x1F494],
                                 [HCDChatFace emojiWithCode:0x1F319],
                                 [HCDChatFace emojiWithCode:0x1f31f],
                                 [HCDChatFace emojiWithCode:0x1f31e],
                                 [HCDChatFace emojiWithCode:0x1F308],
                                 [HCDChatFace emojiWithCode:0x1F60d],
                                 [HCDChatFace emojiWithCode:0x1F61a],
                                 [HCDChatFace emojiWithCode:0x1F48b],
                                 [HCDChatFace emojiWithCode:0x1F339],
                                 [HCDChatFace emojiWithCode:0x1F342],
                                 [HCDChatFace emojiWithCode:0x1F44d],
                                 [HCDChatFace emojiWithCode:0x1F602],
                                 [HCDChatFace emojiWithCode:0x1F604],
                                 [HCDChatFace emojiWithCode:0x1F613],
                                 [HCDChatFace emojiWithCode:0x1F614],
                                 [HCDChatFace emojiWithCode:0x1F618],
                                 [HCDChatFace emojiWithCode:0x1F61c],
                                 [HCDChatFace emojiWithCode:0x1F61d],
                                 [HCDChatFace emojiWithCode:0x1F620],
                                 [HCDChatFace emojiWithCode:0x1F622],
                                 [HCDChatFace emojiWithCode:0x1F623],
                                 [HCDChatFace emojiWithCode:0x1F628],
                                 [HCDChatFace emojiWithCode:0x1F62a],
                                 [HCDChatFace emojiWithCode:0x1F630],
                                 [HCDChatFace emojiWithCode:0x1F632],
                                 [HCDChatFace emojiWithCode:0x1F645],
                                 [HCDChatFace emojiWithCode:0x1F646],
                                 [HCDChatFace emojiWithCode:0x1F647],
                                 [HCDChatFace emojiWithCode:0x1F64c],
                                 [HCDChatFace emojiWithCode:0x1F6a5],
                                 [HCDChatFace emojiWithCode:0x1F6a7],
                                 [HCDChatFace emojiWithCode:0x1F6b2],
                                 [HCDChatFace emojiWithCode:0x1F6b6],
                                 [HCDChatFace emojiWithCode:0x1F302],
                                 [HCDChatFace emojiWithCode:0x1F319],
                                 nil];
    [array addObjectsFromArray:localAry];

    return array;

}

- (NSArray<HCDChatFace *>*)getNormalFaceArray {

    NSArray *array = [kWXFaces componentsSeparatedByString:@","];
    NSMutableArray *data = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSString *name in array) {
        HCDChatFace *face = [[HCDChatFace alloc] init];
        NSString *imageName = [NSString stringWithFormat:@"[%@]", name.trim];
        face.faceName = imageName;
        [data addObject:face];
    }
    return data;
}

- (NSArray<HCDChatFace *>*)getTotalFaceArray{
    NSArray *array = [totalFaces componentsSeparatedByString:@","];
        NSMutableArray *data = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSString *name in array) {
        HCDChatFace *face = [[HCDChatFace alloc] init];
        NSString *imageName = [NSString stringWithFormat:@"[%@]", name.trim];
        face.faceName = imageName;
        [data addObject:face];
    }
    return data;
}

#pragma mark - Getter
- (NSMutableArray<HCDChatFaceGroup *> *)faceGroupArray {
    if (_faceGroupArray == nil) {
        _faceGroupArray = [[NSMutableArray alloc] init];
        
        HCDChatFaceGroup *emojiGroup = [[HCDChatFaceGroup alloc] init];
        emojiGroup.faceType = HCDFaceTypeEmoji;
        emojiGroup.groupID = @"unicode_emoji";
        emojiGroup.groupImageName = @"EmotionsEmojiHL";
        emojiGroup.facesArray = [self getUnicodeEmojiArray];
        [_faceGroupArray addObject:emojiGroup];
        
        HCDChatFaceGroup *group = [[HCDChatFaceGroup alloc] init];
        group.faceType = HCDFaceTypeEmoji;
        group.groupID = @"normal_face";
        group.groupImageName = @"EmotionsEmojiHL";
        group.facesArray = nil;
        [_faceGroupArray addObject:group];
        

        HCDChatFaceGroup *totalGroup = [[HCDChatFaceGroup alloc] init];
        totalGroup.faceType = HCDFaceTypeEmoji;
        totalGroup.groupID = @"total_face";
        totalGroup.groupImageName = @"EmotionsEmojiHL";
        totalGroup.facesArray = [self getTotalFaceArray];
        [_faceGroupArray addObject:totalGroup];
    }
    return _faceGroupArray;
}

-(HCDChatFaceGroup*)totalFaceGroup {
    return [self.faceGroupArray objectAtIndex:2];
}
-(HCDChatFaceGroup*)unicodeEmojiFaceGroup {
    return [self.faceGroupArray objectAtIndex:0];
}

-(BOOL)isSurrogatePair:(NSString*)s {
    if (s.length != 2) {
        return NO;
    }
    const unichar hs = [s characterAtIndex:0];
    if (0xd800 <= hs && hs <= 0xdbff) {
        const unichar ls = [s characterAtIndex:1];
        const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
        if (0x1d000 <= uc && uc <= 0x1f77f) {
            return YES;
        }
    }
    return NO;
}

@end
