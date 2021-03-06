//
//  TKCalendarMonthView.m
//  Created by Devin Ross on 6/10/10.
//
/*
 
 tapku.com || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "TKCalendarMonthView.h"
#import "TKCalendarMonthTiles.h"
#import "NSDate+TKCategory.h"
#import "TKGlobal.h"
#import "UIImage+TKCategory.h"

#define kSun NSLocalizedString(@"dim.", @"")
#define kMon NSLocalizedString(@"lun.", @"")
#define kTue NSLocalizedString(@"mar.", @"")
#define kWed NSLocalizedString(@"mer.", @"")
#define kThu NSLocalizedString(@"jeu.", @"")
#define kFri NSLocalizedString(@"ven.", @"")
#define kSat NSLocalizedString(@"sam.", @"")

@interface TKCalendarMonthView (private)
@property (readonly) UIScrollView *tileBox;
@property (readonly) UIImageView *topBackground;
@property (readonly) UILabel *monthYear;
@property (readonly) UIButton *leftArrow;
@property (readonly) UIButton *rightArrow;
@property (readonly) UIImageView *shadow;

- (NSDate*) firstOfMonthFromDate:(NSDate*)date;
- (NSDate*) nextMonthFromDate:(NSDate*)date;
- (NSDate*) previousMonthFromDate:(NSDate*)date;

@end

@implementation TKCalendarMonthView (privateMeth)

- (NSDate*) firstOfMonthFromDate:(NSDate*)date{

    TKDateInformation info = [date dateInformation];
	info.day = 1;
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
    
	return [NSDate dateFromDateInformation:info];
    
}

- (NSDate*) nextMonthFromDate:(NSDate*)date{
	
    TKDateInformation info = [date dateInformation];
	info.month++;
	if(info.month>12){
		info.month = 1;
		info.year++;
	}
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
	
	return [NSDate dateFromDateInformation:info];
	
}

- (NSDate*) previousMonthFromDate:(NSDate*)date{
	
	TKDateInformation info = [date dateInformation];
	info.month--;
	if(info.month<1){
		info.month = 12;
		info.year--;
	}
	
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
	return [NSDate dateFromDateInformation:info];
	
}

@end

@implementation TKCalendarMonthView
@synthesize delegate,dataSource;

- (id) init{
	return [self initWithSundayAsFirst:NO];
}

- (id) initWithSundayAsFirst:(BOOL)s{
	
	sunday = s;
	
	currentTile = [[[TKCalendarMonthTiles alloc] initWithMonth:[self firstOfMonthFromDate:[NSDate date]] 
														 marks:nil startDayOnSunday:sunday] autorelease];
	[currentTile setTarget:self action:@selector(tile:)];

	if (![super initWithFrame:CGRectMake(0.0, 0.0, self.tileBox.bounds.size.width, self.tileBox.bounds.size.height + self.tileBox.frame.origin.y)])
        return nil;
	
	[currentTile retain];
	
	[self addSubview:self.topBackground];
	[self.tileBox addSubview:currentTile];
	[self addSubview:self.tileBox];
	
	NSDate *date = [NSDate date];
	
    self.monthYear.text = [NSString stringWithFormat:@"%@ %@",[[date month] capitalizedString],[date year]];
	[self addSubview:self.monthYear];
	
	[self addSubview:self.leftArrow];
	[self addSubview:self.rightArrow];
	
	[self addSubview:self.shadow];
    
	self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
	
	self.backgroundColor = [UIColor whiteColor];
	
	NSArray *array;
	if(sunday)
		array = [NSArray arrayWithObjects:kSun,kMon,kTue,kWed,kThu,kFri,kSat,nil];
	else
		array = [NSArray arrayWithObjects:kMon,kTue,kWed,kThu,kFri,kSat,kSun,nil];
	int i = 0;
    
    for (NSString *string in array){
		
        // Lun Mar ... Dim
		UILabel *jourLabel = [[UILabel alloc] initWithFrame:CGRectMake(ceilf(self.frame.size.width/7.0) * i, 30, ceilf(self.frame.size.width/7.0), 15)];
        [jourLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin)];
		[jourLabel setText:string];
		[jourLabel setTextAlignment:NSTextAlignmentCenter];
		[jourLabel setFont:[UIFont systemFontOfSize:11]];
		[jourLabel setBackgroundColor:[UIColor clearColor]];
		[jourLabel setTextColor:[UIColor colorWithRed:59/255. green:73/255. blue:88/255. alpha:1]];
        [self addSubview:jourLabel];
        [jourLabel release];
		
		i++;
        
	}
	
	return self;
}

- (void) changeMonthAnimation:(UIView*)sender{
	
	BOOL isNext = (sender.tag == 1);
    
	NSDate *nextMonth = isNext ? [self nextMonthFromDate:currentTile.monthDate] : [self previousMonthFromDate:currentTile.monthDate];
	
	NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:nextMonth startOnSunday:sunday];
	
	NSArray *ar = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject] forMonth:nextMonth];
    
	TKCalendarMonthTiles *newTile = [[TKCalendarMonthTiles alloc] initWithMonth:nextMonth marks:ar startDayOnSunday:sunday];
	[newTile setTarget:self action:@selector(tile:)];
	
	int overlap =  0;
	
	if(isNext){
		overlap = [newTile.monthDate isEqualToDate:[dates objectAtIndex:0]] ? 0 : 44;
	}else{
		overlap = [currentTile.monthDate compare:[dates lastObject]] !=  NSOrderedDescending ? 44 : 0;
	}
	
	float y = isNext ? currentTile.bounds.size.height - overlap : newTile.bounds.size.height * -1 + overlap;
	
    NSLog(@"overlap: %i", overlap);
    
	newTile.frame = CGRectMake(0, y, newTile.frame.size.width, newTile.frame.size.height);

    [self.tileBox addSubview:newTile];
	[self.tileBox bringSubviewToFront:currentTile];

	self.userInteractionEnabled = NO;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDidStopSelector:@selector(animationEnded)];
	[UIView setAnimationDuration:0.4];
	
	currentTile.alpha = 0.0;
    
	if (isNext){
		
		currentTile.frame = CGRectMake(0, -1 * currentTile.bounds.size.height + overlap, currentTile.frame.size.width, currentTile.frame.size.height);
		
        newTile.frame = CGRectMake(0, 1, newTile.frame.size.width, newTile.frame.size.height);
		
        self.tileBox.frame = CGRectMake(self.tileBox.frame.origin.x, self.tileBox.frame.origin.y, self.tileBox.frame.size.width, newTile.frame.size.height);
	
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);
		
		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
		
	} else {
		
		newTile.frame = CGRectMake(0, 1, newTile.frame.size.width, newTile.frame.size.height);
		
        self.tileBox.frame = CGRectMake(self.tileBox.frame.origin.x, self.tileBox.frame.origin.y, self.tileBox.frame.size.width, newTile.frame.size.height);
		
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);
		
        currentTile.frame = CGRectMake(0,  newTile.frame.size.height - overlap, currentTile.frame.size.width, currentTile.frame.size.height);
		
		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
	
    }
	
    // Changement de hauteur du calendrier:
    //NSLog(@"newTile: %f", newTile.frame.size.height);
    
	[delegate calendarMonthViewDidResize:self];
	
	[UIView commitAnimations];
	
	oldTile = currentTile;
	currentTile = newTile;

	// Mois et année: < Aout 2013 >
    monthYear.text = [NSString stringWithFormat:@"%@ %@",[[nextMonth month] capitalizedString],[nextMonth year]];
    
}

- (void) changeMonth:(UIButton *)sender{
	
	if([delegate respondsToSelector:@selector(calendarMonthView:monthWillChange:)])
		[delegate calendarMonthView:self monthWillChange:currentTile.monthDate];
	
	[self changeMonthAnimation:sender];
	
	if([delegate respondsToSelector:@selector(calendarMonthView:monthDidChange:)])
		[delegate calendarMonthView:self monthDidChange:currentTile.monthDate];

}

- (void) animationEnded{

    self.userInteractionEnabled = YES;
	
    // Animation de changement de mois fini, on reload la tableview
    if([delegate respondsToSelector:@selector(calendarMonthView:didSelectDate:)])
        [delegate calendarMonthView:self didSelectDate:[currentTile dateSelected]];
    
    [oldTile release];
	oldTile = nil;
    
}

- (NSDate*) dateSelected{
	return [currentTile dateSelected];
}

- (NSDate*) monthDate{
	return [currentTile monthDate];
}

- (void) selectDate:(NSDate*)date{
	
	TKDateInformation info = [date dateInformation];
	NSDate *month = [self firstOfMonthFromDate:date];
	
	if([month isEqualToDate:[currentTile monthDate]]){
		
        [currentTile selectDay:info.day];
		return;
        
	}else {
		
		NSDate *month = [self firstOfMonthFromDate:date];
		NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:month startOnSunday:sunday];
		NSArray *data = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject] forMonth:month];
        
		TKCalendarMonthTiles *newTile = [[TKCalendarMonthTiles alloc] initWithMonth:month 
																			  marks:data 
																   startDayOnSunday:sunday];
		[newTile setTarget:self action:@selector(tile:)];
		[currentTile removeFromSuperview];
		[currentTile release];
		currentTile = newTile;
		[self.tileBox addSubview:currentTile];
        
		self.tileBox.frame = CGRectMake(0, 44, newTile.frame.size.width, newTile.frame.size.height);

        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);

		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
        
		self.monthYear.text = [NSString stringWithFormat:@"%@ %@",[[month month] capitalizedString],[month year]];
		
		[currentTile selectDay:info.day];
		
		[delegate calendarMonthViewDidResize:self];
        
	}
}

- (void)reload {
    
	NSDate *month = [self monthDate];
	NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:[currentTile monthDate] startOnSunday:sunday];
	NSArray *ar = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject] forMonth:month];
	
	TKCalendarMonthTiles *refresh = [[[TKCalendarMonthTiles alloc] initWithMonth:[currentTile monthDate] marks:ar startDayOnSunday:sunday] autorelease];
	[refresh setTarget:self action:@selector(tile:)];
	
	[self.tileBox addSubview:refresh];
	[currentTile removeFromSuperview];
	[currentTile release];
	currentTile = [refresh retain];
	[delegate calendarMonthViewDidResize:self];
	
}

- (void)tile:(NSArray*)ar {
    
    // Click sur une case
	
	if([ar count] < 2){
		
		NSDate *d = [currentTile monthDate];
		TKDateInformation info = [d dateInformation];
		info.day = [[ar objectAtIndex:0] intValue];
		
		NSDate *select = [NSDate dateFromDateInformation:info];
		
		if([delegate respondsToSelector:@selector(calendarMonthView:didSelectDate:)])
			[delegate calendarMonthView:self didSelectDate:select];
		 
	}else{
		
		int direction = [[ar lastObject] intValue];
		UIButton *b = direction > 1 ? self.rightArrow : self.leftArrow;
		
		[self changeMonthAnimation:b];
		
		int day = [[ar objectAtIndex:0] intValue];
		//[currentTile selectDay:day];
	
		// thanks rafael
		TKDateInformation info = [[currentTile monthDate] dateInformation];
		info.day = day;
		NSDate *dateForMonth = [NSDate  dateFromDateInformation:info]; 
		[currentTile selectDay:day];
		
		if([delegate respondsToSelector:@selector(calendarMonthView:monthDidChange:)])
			[delegate calendarMonthView:self monthDidChange:dateForMonth];
	
    }
	
}


- (UIImageView *)topBackground {
	
    /*
	if(topBackground==nil){
		topBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grid_Top_Bar.png"]];
	}
	
	return topBackground;
	 */
	
	return nil;
}

- (UILabel *)monthYear {
	
    if(monthYear==nil){

        monthYear = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tileBox.frame.size.width, 38)];
		monthYear.textAlignment = NSTextAlignmentCenter;
		monthYear.backgroundColor = [UIColor clearColor];
		monthYear.font = [UIFont boldSystemFontOfSize:22];
		monthYear.textColor = [UIColor colorWithRed:59/255. green:73/255. blue:88/255. alpha:1];
        
	}
    
	return monthYear;
    
}

- (UIButton *)leftArrow {
    
	if(leftArrow==nil){
        
		leftArrow = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		leftArrow.tag = 0;
		[leftArrow addTarget:self action:@selector(changeMonth:) forControlEvents:UIControlEventTouchUpInside];
		[leftArrow setImage:[UIImage imageWithName:@"left_arrow.png"] forState:(UIControlStateNormal)];
		leftArrow.frame = CGRectMake(0, 0, 48, 38);
        
	}
	return leftArrow;
    
}
- (UIButton *) rightArrow{
    
	if(rightArrow==nil){

        rightArrow = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		rightArrow.tag = 1;
		[rightArrow addTarget:self action:@selector(changeMonth:) forControlEvents:UIControlEventTouchUpInside];
		rightArrow.frame = CGRectMake(self.frame.size.width-45, 0, 48, 38);
		[rightArrow setImage:[UIImage imageWithName:@"right_arrow.png"] forState:0];
		
	}
    
	return rightArrow;
    
}

- (UIScrollView *)tileBox {
    
	if(tileBox==nil){
		tileBox = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 44, [[UIScreen mainScreen] bounds].size.width, currentTile.frame.size.height)];
	}
    
	return tileBox;
    
}

- (UIImageView *)shadow {
    
	if(shadow==nil){
		shadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"calendar_Shadow.png"]];
	}
	return shadow;
    
}

- (void)dealloc {
	[shadow release];
	[topBackground release];
	[leftArrow release];
	[monthYear release];
	[rightArrow release];
	[tileBox release];
	[currentTile release];
    [super dealloc];
}


@end
