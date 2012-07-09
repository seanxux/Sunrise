//
//  SunUtils.m
//  Sunrise
//
//  Created by Shawn Xu on 7/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//    用語の説明
//
//    天文薄明:
//    天体の見え方に太陽の影響が残る時間帯。
//    航海薄明:
//    周りの景色がぼんやり見えている時間帯。
//    市民薄明:
//    太陽が隠れても外で活動できる時間帯。
//    日出:
//    太陽の上端が水平線から見えた時。
//    日没:
//    太陽の上端が完全に水平線に没した時。
//    南中:
//    太陽高度が最も高く、真南(真北)に位置する時。
//    高度:
//    水平を0度にした角度。
//    方位:
//    北(南)を0度にした角度。

#import "SunUtils.h"

@implementation SunUtils

+ (SunUtils *)sharedInstance
{
    static SunUtils *instance;
    
    if (instance == nil) {
        instance = [[SunUtils alloc] init];
    }
    return instance;
}

// sin function using degree
double sind(double d)
{
    return sin(d*M_PI/180) ; 
}
// cos function using degree
double cosd(double d)
{
    return cos(d*M_PI/180) ; 
}
// tan function using degree
double tand(double d) 
{
    return tan(d*M_PI/180) ; 
}
// calculate Julius year (year from 2000/1/1, for variable "t")
double jy(double yy, double mm, double dd, double h, double m, double s, double i) 
{ // yy/mm/dd h:m:s, i: time difference
    yy -= 2000 ;
    if(mm <= 2) {
        mm += 12 ;
        yy-- ; 
    }
    double k = 365 * yy + 30 * mm + dd - 33.5 - i / 24 + floor(3 * (mm + 1) / 5) 
    + floor(yy / 4) - floor(yy / 100) + floor(yy / 400);
    k += ((s / 60 + m) / 60 + h) / 24 ; // plus time
    k += (65 + yy) / 86400 ; // plus delta T
    return k / 365.25 ;
}
// solar position1 (celestial longitude, degree)
double spls(double t) { // t: Julius year
    double l = 280.4603 + 360.00769 * t 
    + (1.9146 - 0.00005 * t) * sind(357.538 + 359.991 * t)
    + 0.0200 * sind(355.05 +  719.981 * t)
    + 0.0048 * sind(234.95 +   19.341 * t)
    + 0.0020 * sind(247.1  +  329.640 * t)
    + 0.0018 * sind(297.8  + 4452.67  * t)
    + 0.0018 * sind(251.3  +    0.20  * t)
    + 0.0015 * sind(343.2  +  450.37  * t)
    + 0.0013 * sind( 81.4  +  225.18  * t)
    + 0.0008 * sind(132.5  +  659.29  * t)
    + 0.0007 * sind(153.3  +   90.38  * t)
    + 0.0007 * sind(206.8  +   30.35  * t)
    + 0.0006 * sind( 29.8  +  337.18  * t)
    + 0.0005 * sind(207.4  +    1.50  * t)
    + 0.0005 * sind(291.2  +   22.81  * t)
    + 0.0004 * sind(234.9  +  315.56  * t)
    + 0.0004 * sind(157.3  +  299.30  * t)
    + 0.0004 * sind( 21.1  +  720.02  * t)
    + 0.0003 * sind(352.5  + 1079.97  * t)
    + 0.0003 * sind(329.7  +   44.43  * t) ;
    while(l >= 360) { l -= 360 ; }
    while(l < 0) { l += 360 ; }
    return l ;
}
// solar position2 (distance, AU)
double spds(double t) { // t: Julius year
    double r = (0.007256 - 0.0000002 * t) * sind(267.54 + 359.991 * t)
    + 0.000091 * sind(265.1 +  719.98 * t)
    + 0.000030 * sind( 90.0)
    + 0.000013 * sind( 27.8 + 4452.67 * t)
    + 0.000007 * sind(254   +  450.4  * t)
    + 0.000007 * sind(156   +  329.6  * t);
    r = pow(10,r) ;
    return r ;
}
// solar position3 (declination, degree)
double spal(double t) { // t: Julius year
    double ls = spls(t) ;
    double ep = 23.439291 - 0.000130042 * t ;
    double al = atan(tand(ls) * cosd(ep)) * 180 / M_PI;
    if((ls >= 0)&&(ls < 180)) {
        while(al < 0) { al += 180 ; }
        while(al >= 180) { al -= 180 ; } }
    else {
        while(al < 180) { al += 180 ; }
        while(al >= 360) { al -= 180 ; } }
    return al ;
}
// solar position4 (the right ascension, degree)
double spdl(double t) { // t: Julius year
    double ls = spls(t) ;
    double ep = 23.439291 - 0.000130042 * t ;
    double dl = asin(sind(ls) * sind(ep)) * 180 / M_PI ;
    return dl ;
}
// Calculate sidereal hour (degree)
double sh(double t, double h, double m, double s, double l, double i) { // t: julius year, h: hour, m: minute, s: second,
    // l: longitude, i: time difference
    double d = ((s / 60 + m) / 60 + h) / 24 ; // elapsed hour (from 0:00 a.m.)
    double th = 100.4606 + 360.007700536 * t + 0.00000003879 * t * t - 15 * i ;
    th += l + 360 * d ;
    while(th >= 360) { th -= 360 ; }
    while(th < 0) { th += 360 ; }
    return th ;
}
// Calculating the seeming horizon altitude "sa"(degree)
double eandp(double alt, double ds) { // subfunction for altitude and parallax
    double e = 0.035333333 * sqrt(alt) ;
    double p = 0.002442818 / ds ;
    return p - e ;
}
double sa(double alt, double ds) { // alt: altitude (m), ds: solar distance (AU)
    double s = 0.266994444 / ds ;
    double r = 0.585555555 ;
    double k = eandp(alt,ds) - s - r ;
    return k ;
}
// Calculating solar alititude (degree) {
double soal(double la, double th, double al, double dl) { // la: latitude, th: sidereal hour,
    // al: solar declination, dl: right ascension
    double h = sind(dl) * sind(la) + cosd(dl) * cosd(la) * cosd(th - al) ;
    h = asin(h) * 180 / M_PI ;
    return h;
}
// Calculating solar direction (degree) {
double sodr(double la, double th, double al, double dl) { // la: latitude, th: sidereal hour,
    // al: solar declination, dl: right ascension
    double t = th - al ;
    double dc = - cosd(dl) * sind(t) ;
    double dm = sind(dl) * sind(la) - cosd(dl) * cosd(la) * cosd(t) ;
    double dr = 0.0;
    if(dm == 0) {
        double st = sind(t) ;
        if(st > 0) dr = -90 ;
        if(st == 0) dr = 9999 ;
        if(st < 0) dr = 90 ;
    }
    else {
        dr = atan(dc / dm) * 180 / M_PI ;
        if(dm <0) dr += 180 ;
    }
    if(dr < 0) dr += 360 ;
    return dr ;
}

// la: 緯度
// lo: 経度
// alt: 標高
- (NSString *)calc:(double)i la:(double)la lo:(double)lo alt:(double)alt
{
    int yy = 2012;
    int mm = 12;
    int dd = 8;
    
    double t = jy(yy,mm,dd-1,23,59,0,i) ;
    double th = sh(t,23,59,0,lo,i) ;
    double ds = spds(t) ;
    double ls = spls(t) ;
    double alp = spal(t) ;
    double dlt = spdl(t) ;
    double pht = soal(la,th,alp,dlt) ;
    double pdr = sodr(la,th,alp,dlt) ;
    
    NSMutableString *ans = [[NSMutableString alloc] init];
    
    for(int hh=0; hh<24; hh++) {
        for(int m=0; m<60; m++) {
            t = jy(yy,mm,dd,hh,m,0,i) ;
            th = sh(t,hh,m,0,lo,i) ;
            ds = spds(t) ;
            ls = spls(t) ;
            alp = spal(t) ;
            dlt = spdl(t) ;
            double ht = soal(la,th,alp,dlt) ;
            double dr = sodr(la,th,alp,dlt) ;
            double tt = eandp(alt,ds) ;
            double t1 = tt - 18 ;
            double t2 = tt - 12 ;
            double t3 = tt - 6 ;
            double t4 = sa(alt,ds) ;
            // Solar check 
            // 0: non, 1: astronomical twilight start , 2: voyage twilight start,
            // 3: citizen twilight start, 4: sun rise, 5: meridian, 6: sun set,
            // 7: citizen twilight end, 8: voyage twilight end,
            // 9: astronomical twilight end
            if((pht<t1)&&(ht>t1)) {
                [ans appendFormat:@"%d時%d分 天文薄明始まり\n", hh, m];
                NSLog(@"%d時%d分 天文薄明始まり", hh, m);
            }
            
            if((pht<t2)&&(ht>t2)) {
                [ans appendFormat:@"%d時%d分 航海薄明始まり\n", hh, m];
                NSLog(@"%d時%d分 航海薄明始まり", hh, m);
            }
            if((pht<t3)&&(ht>t3)) {
                [ans appendFormat:@"%d時%d分 市民薄明始まり\n", hh, m];
                NSLog(@"%d時%d分 市民薄明始まり", hh, m);
            }
            if((pht<t4)&&(ht>t4)) {
                [ans appendFormat:@"%d時%d分 日出(方位%f度)\n", hh, m, floor(dr)];
                NSLog(@"%d時%d分 日出(方位%f度)", hh, m, floor(dr));
            }
            if((pdr<180)&&(dr>180)) {
                [ans appendFormat:@"%d時%d分 南中(高度%f度)\n", hh, m, floor(ht)];
                NSLog(@"%d時%d分 南中(高度%f度)", hh, m, floor(ht));
            }
            if((pht>t4)&&(ht<t4)) {
                [ans appendFormat:@"%d時%d分 日没(方位%f度)\n", hh, m, floor(dr)];
                NSLog(@"%d時%d分 日没(方位%f度)", hh, m, floor(dr));
            }
            if((pht>t3)&&(ht<t3)) {
                [ans appendFormat:@"%d時%d分 市民薄明終わり\n", hh, m];
                NSLog(@"%d時%d分 市民薄明終わり", hh, m);
            }
            if((pht>t2)&&(ht<t2)) {
                [ans appendFormat:@"%d時%d分 航海薄明終わり\n", hh, m];
                NSLog(@"%d時%d分 航海薄明終わり", hh, m);
            }
            if((pht>t1)&&(ht<t1)) {
                [ans appendFormat:@"%d時%d分 航海薄明終わり\n", hh, m];
                NSLog(@"%d時%d分 天文薄明終わり", hh, m);
            }
            pht = ht ;
            pdr = dr ;
        }
    }
    return [ans autorelease];
}

@end
