//
//  QMMusicPlayer.m
//  QQMusic
//
//  Created by AenyMo on 16/4/12.
//  Copyright © 2016年 AenyMo. All rights reserved.
//

#import "QMMusicPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "QMPlayerTimer.h"

#import "QMMusics.h"

static QMMusicPlayer *instance = nil;

@interface QMMusicPlayer () <AVAudioPlayerDelegate>

/** 播放器 */
@property (nonatomic, strong) AVAudioPlayer *player;

/** 定时器 */
@property (nonatomic, strong) QMPlayerTimer *timer;

@end

@implementation QMMusicPlayer

- (NSArray *)musics {
    
    if (_musics == nil) {
        //
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Musics.plist" ofType:nil];
        
        NSArray *music = [NSArray arrayWithContentsOfFile:filePath];
        
        NSMutableArray *tmp = [NSMutableArray array];
        
        for (NSDictionary *dict in music) {
            //
            QMMusics *music = [QMMusics musicsWithDict:dict];
            
            [tmp addObject:music];
        }
        
        _musics = tmp;
        
    }
    return _musics;
}


- (void)setPlayingIndex:(NSInteger)playingIndex {
    
    if (_playingIndex == playingIndex) {
        return;
    }
    
//    _playingIndex = playingIndex;
    //判断是否越界
    if (playingIndex >= (NSInteger)self.musics.count) {
        //
        playingIndex = 0;
        
    } else if (playingIndex < 0) {
        
        playingIndex = self.musics.count - 1;
    }
    
    //切换到下一曲/上一曲
    [self playWithIndexNumber:playingIndex];
}

#pragma mark - 单例创建播放器
/** 通过单例创建播放器 */
+ (instancetype)shareMusicPlayer {
    
    if (instance == nil) {
        //
        //创建播放器对象
        instance = [[self alloc] init];
    }
    
    return instance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        //
        //创建定时器
        self.timer = [QMPlayerTimer sharePlayerTimer];
    }
    return self;
}

#pragma mark - 音乐播放
/** 通过索引播放音乐 */
- (BOOL)playWithIndexNumber:(NSInteger)IndexNumber {
    
    //判断是否是同一首歌
    if (IndexNumber == _playingIndex) {
        //
        return YES;
    }
    
    //从bundle中加载音乐 (bundle: app的包文件夹中)
    QMMusics *music = self.musics[IndexNumber];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:music.filename ofType:nil];
    
    //将路径转换成URL,并且处理中文路径问题
    NSURL *url = [NSURL fileURLWithPath:[filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *error = nil;
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    self.player.delegate = self;
    

    [self.timer startTimer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QMMusicPlayerPlayingChanged" object:nil userInfo:@{@"playingModel" : music}];
    
    //播放音乐
    if ([self play]) {
        //
        //不能用set方法,不然会造成死循环 (记录当前正在播放的歌曲)
        _playingIndex = IndexNumber;
    }
    
    
    return error ? NO : YES;
}



- (BOOL)pause {
    
    //如果正在播放
    if ([self.player isPlaying]) {
        //暂停
        [self.player pause];
        
#warning 要使用观察者模式, 必须通过 set方法 或者 KVC 来改变 属性的值
        [self setValue:@(kQMMusicPlayerStatusPause) forKeyPath:@"status"];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)play {
    
    //如果没有播放
    if (![self.player isPlaying]) {
        //播放
        [self.player play];
        
#warning 要使用观察者模式, 必须通过 set方法 或者 KVC 来改变 属性的值
        [self setValue:@(kQMMusicPlayerStatusPlaying) forKeyPath:@"status"];
        
        return YES;
    }
    return NO;
}

//下一曲
- (void)nextOne {
    
    self.playingIndex++;
}

//上一曲
- (void)preOne {
    
    self.playingIndex--;
}


#pragma mark - 重写get方法
- (NSTimeInterval)totalTime {
    
    return self.player.duration;
}

- (NSTimeInterval)currentTime {
    
    return self.player.currentTime;
}


#pragma mark - 重写set方法
- (void)setCurrentTime:(NSTimeInterval)currentTime {
    
    self.player.currentTime = currentTime;
}

#pragma mark - 代理方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    //自动播放下一首
    [self nextOne];
}

@end
