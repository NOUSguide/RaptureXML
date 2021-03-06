//
//  DeepTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface DeepTests : SenTestCase {
}

@end



@implementation DeepTests

- (void)testQuery {
    RXMLElement *rxml = [RXMLElement elementWithFilepath:@"players.xml"];
    __block NSInteger i;
    
    // count the players
    i = 0;
    
    [rxml iteratePath:@"players.player" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
    STAssertEquals(i, 9, nil);

    // count the first players' names
    i = 0;
    
    [rxml iteratePath:@"players.player.name" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
    STAssertEquals(i, 1, nil);

    // count the coaches
    i = 0;
    
    [rxml iteratePath:@"players.coach" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
    STAssertEquals(i, 1, nil);
    
    // count players with number >= 29
    i = 0;
    
    [rxml iterateChildrenMatchingXPathQuery:@"//player[number(@number) >= 29]" usingBlock:^(RXMLElement *element) {
        i++;
    }];
    
    STAssertEquals(i, 4, nil);
    
    [rxml iterateChildrenMatchingXPathQuery:@"//teams/team" usingBlock:^(RXMLElement *element) {
        STAssertTrue(element.attributes.allKeys.count == 2, nil);
    }];
}

@end
