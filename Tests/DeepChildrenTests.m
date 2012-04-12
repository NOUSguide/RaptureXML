//
//  DeepChildrenTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface DeepChildrenTests : SenTestCase {
}

@end



@implementation DeepChildrenTests

- (void)testQuery {
    RXMLElement *rxml = [RXMLElement elementWithFilepath:@"players.xml"];
    __block NSInteger i = 0;
    
    // count the players
    RXMLElement *players = [rxml childWithPath:@"players"];
    NSArray *children = [players childrenWithTagName:@"player"];
    
    [rxml iterateElements:children usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
    STAssertEquals(i, 9, nil);
}

- (void)testDeepChildQuery {
    RXMLElement *rxml = [RXMLElement elementWithFilepath:@"players.xml"];
    
    // count the players
    RXMLElement *coachingYears = [rxml childWithPath:@"players.coach.experience.years"];
    
    STAssertEquals([coachingYears.text integerValue], 1, nil);
}

- (void)testDeepChildQueryWithWildcard {
    RXMLElement *rxml = [RXMLElement elementWithFilepath:@"players.xml"];
    
    // count the players
    RXMLElement *coachingYears = [rxml childWithPath:@"players.coach.experience.teams.*"];
    
    // first team returned
    STAssertEquals([coachingYears.text integerValue], 53, nil);
}

- (void)testAllChildren {
    RXMLElement *rxml = [[RXMLElement elementWithFilepath:@"players.xml"] childWithPath:@"players"];
    NSArray *children = rxml.children;
    __block NSInteger coachCount = 0;
    __block NSInteger playerCount = 0;
    
    STAssertTrue(children.count > 0, nil);
    
    [rxml iterateElements:children usingBlock:^(RXMLElement *element) {
        if ([element.tagName isEqualToString:@"coach"]) {
            coachCount++;
        } else if ([element.tagName isEqualToString:@"player"]) {
            playerCount++;
        }
    }];
    
    STAssertEquals(coachCount, 1, nil);
    STAssertEquals(playerCount, 9, nil);
}

@end
