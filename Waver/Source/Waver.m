//
//  Waver.m
//  Waver
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#import "Waver.h"

@interface Waver ()

@property (nonatomic) CGFloat phase;
@property (nonatomic) CGFloat amplitude;
@property (nonatomic) NSMutableArray * waves;
@property (nonatomic) CGFloat waveHeight;
@property (nonatomic) CGFloat waveWidth;
@property (nonatomic) CGFloat waveMid;
@property (nonatomic) CGFloat maxAmplitude;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation Waver

- (id)init
{
    if(self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
}

- (void)setup
{
    self.waves = [NSMutableArray new];
    
    self.frequency = 1.2f;
    
    self.amplitude = 0.8f;
    self.idleAmplitude = 0.01f;
    
    self.numberOfWaves = 4;
    self.phaseShift = -0.25f;
    self.density = 0.8f;
    
    self.waveColor = [UIColor whiteColor];
    self.mainWaveWidth = 2.0f;
    self.decorativeWavesWidth = 1.5f;
    
    self.waveHeight = CGRectGetHeight(self.bounds) - 100;
    self.waveWidth  = CGRectGetWidth(self.bounds);
    self.waveMid    = self.waveWidth / 2.0f;
    self.maxAmplitude = self.waveHeight - 4.0f;
}

- (void)setWaverLevelCallback:(void (^)(Waver * waver))waverLevelCallback {
    _waverLevelCallback = waverLevelCallback;
    
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(invokeWaveCallback)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    for(int i=0; i < self.numberOfWaves; i++) {
        CAShapeLayer *waveline = [CAShapeLayer layer];
        waveline.lineCap       = kCALineCapButt;
        waveline.lineJoin      = kCALineJoinRound;
        waveline.strokeColor   = [[UIColor clearColor] CGColor];
        waveline.fillColor     = [[UIColor clearColor] CGColor];
        [waveline setLineWidth:(i==0 ? self.mainWaveWidth : self.decorativeWavesWidth)];
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
        UIColor *color = [self.waveColor colorWithAlphaComponent:(i == 0 ? 1.0 : 1.0 * multiplier * 0.4)];
        waveline.strokeColor = color.CGColor;
        
        CALayer * layer = [CALayer layer];
        layer.frame = self.bounds;
        [self.layer addSublayer:layer];
        
        NSMutableArray *colors = [NSMutableArray arrayWithObjects:(id)[UIColor colorWithRed:255.0/255.0 green:46.0/255.0 blue:137.0/255.0 alpha:1].CGColor,(id)[UIColor colorWithRed:0.0/255.0 green:163.0/255.0 blue:255.0/255.0 alpha:1].CGColor, nil];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = self.bounds;
        //        gradientLayer.startPoint = CGPointMake(0, 0.5);
        //        gradientLayer.endPoint = CGPointMake(1, 0.5);
        
        gradientLayer.startPoint = CGPointMake(0.5, 0);
        gradientLayer.endPoint = CGPointMake(0.5, 1);
        [gradientLayer setColors:[NSArray arrayWithArray:colors]];
        [layer addSublayer:gradientLayer];
        
        [layer addSublayer:waveline];
        [layer setMask:waveline];
        [self.waves addObject:waveline];
    }
}

- (void)invokeWaveCallback {
    self.waverLevelCallback(self);
}

- (void)setLevel:(CGFloat)level
{
    _level = level;
    if (_level >= 0.5) {
        _level = 0.5;
    }
    self.phase += self.phaseShift; // Move the wave
    
    self.amplitude = fmax( level, self.idleAmplitude);
    [self updateMeters];
}


- (void)updateMeters {
    self.waveHeight = CGRectGetHeight(self.bounds);
    self.waveWidth  = CGRectGetWidth(self.bounds);
    self.waveMid    = self.waveWidth / 2.0f;
    self.maxAmplitude = self.waveHeight - 4.0f;
    
    UIGraphicsBeginImageContext(self.frame.size);
    
    for(int i=0; i < self.numberOfWaves; i++) {
        
        UIBezierPath *wavelinePath = [UIBezierPath bezierPath];
        
        // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
        
        
        for(CGFloat x = 0; x<self.waveWidth + self.density; x += self.density) {
            
            //Thanks to https://github.com/stefanceriu/SCSiriWaveformView
            // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
            CGFloat scaling = -pow(x / self.waveMid  - 1, 2) + 1; // make center bigger
            
            CGFloat y = scaling * self.maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / self.waveWidth) * self.frequency + self.phase) + (self.waveHeight * 0.5);
            
            if (x==0) {
                [wavelinePath moveToPoint:CGPointMake(x, y)];
            }
            else {
                [wavelinePath addLineToPoint:CGPointMake(x, y)];
            }
        }
        
        CAShapeLayer *waveline = [self.waves objectAtIndex:i];
        
        waveline.path = [wavelinePath CGPath];
    }
    
    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [_displayLink invalidate];
}

@end
