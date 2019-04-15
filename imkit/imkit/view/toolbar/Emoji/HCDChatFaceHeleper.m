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

@end
