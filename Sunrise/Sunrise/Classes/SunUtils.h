//
//  SunUtils.h
//  Sunrise
//
//  Created by Shawn Xu on 7/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SunUtils : NSObject

+ (SunUtils *)sharedInstance;
- (NSString *)calc:(double)i la:(double)la lo:(double)lo alt:(double)alt;

@end
