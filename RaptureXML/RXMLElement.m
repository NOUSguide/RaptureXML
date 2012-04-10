// ================================================================================================
//  RXMLElement.m
//  Fast processing of XML files
//
// ================================================================================================
//  Created by John Blanco on 9/23/11.
//  Version 1.4
//  
//  Copyright (c) 2011 John Blanco
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// ================================================================================================
//

#import "RXMLElement.h"
//#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface RXMLElement () {
    xmlDocPtr _document;
    xmlNodePtr _node;
}

- (void)setupWithData:(NSData *)data;

@end

@implementation RXMLElement 

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithString:(NSString *)xmlString encoding:(NSStringEncoding)encoding {
    if ((self = [super init])) {
        NSData *data = [xmlString dataUsingEncoding:encoding];
        
        [self setupWithData:data];
    }
    
    return self;    
}

- (id)initWithFilepath:(NSString *)filename {
    if ((self = [super init])) {
        NSString *fullPath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:filename];
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        
        [self setupWithData:data];
    }
    
    return self;    
}

- (id)initWithFilename:(NSString *)filename extension:(NSString *)extension {
    if ((self = [super init])) {
        NSString *fullPath = [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:extension];
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        
        [self setupWithData:data];
    }
    
    return self;    
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        [self setupWithData:data];
    }
    
    return self;    
}

- (id)initWithData:(NSData *)data {
    if ((self = [super init])) {
        [self setupWithData:data];
    }
    
    return self;    
}

- (id)initWithNode:(xmlNodePtr)node {
    if ((self = [super init])) {
        _document = nil;
        _node = node;
    }
    
    return self;        
}

+ (id)elementWithString:(NSString *)attributeXML_ encoding:(NSStringEncoding)encoding {
    return [[RXMLElement alloc] initWithString:attributeXML_ encoding:encoding];    
}

+ (id)elementWithFilepath:(NSString *)filename {
    return [[RXMLElement alloc] initWithFilepath:filename];    
}

+ (id)elementWithFilename:(NSString *)filename extension:(NSString *)extension {
    return [[RXMLElement alloc] initWithFilename:filename extension:extension];
}

+ (id)elementWithURL:(NSURL *)url {
    return [[RXMLElement alloc] initWithURL:url];
}

+ (id)elementWithData:(NSData *)data {
    return [[RXMLElement alloc] initWithData:data];
}

+ (id)elementWithNode:(xmlNodePtr)node {
    return [[RXMLElement alloc] initWithNode:node];
}

- (void)dealloc {
    if (_document != nil) {
        xmlFreeDoc(_document);
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject
////////////////////////////////////////////////////////////////////////

- (NSString *)description {
    return [self text];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Getter
////////////////////////////////////////////////////////////////////////

- (NSDictionary *)attributes {
    xmlAttr *attribute = _node->properties;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    while (attribute != NULL) {
        NSString *attributeName = nil;
        NSString *attributeValue = nil;
        
        if (attribute->name && attribute->children && attribute->children->type == XML_TEXT_NODE && attribute->children->content) {
            attributeName = [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
            attributeValue = [NSString stringWithCString:(const char *)attribute->children->content encoding:NSUTF8StringEncoding];
            
            if (attributeName != nil && attributeValue != nil) {
                [attributes setObject:attributeValue forKey:attributeName];
            }
        }
        
        attribute = attribute->next;
    }
    
    return [attributes copy];
}

- (NSString *)tagName {
    return [NSString stringWithUTF8String:(const char *)_node->name];
}

- (NSString *)text {
    xmlChar *key = xmlNodeGetContent(_node);
    NSString *text = (key ? [NSString stringWithUTF8String:(const char *)key] : @"");
    xmlFree(key);
    
    return text;
}

- (NSInteger)textAsInteger {
    return [self.text integerValue];
}

- (double)textAsDouble {
    return [self.text doubleValue];
}

- (NSString *)attribute:(NSString *)attributeName {
    const unsigned char *attributeValueC = xmlGetProp(_node, (const xmlChar *)[attributeName cStringUsingEncoding:NSUTF8StringEncoding]);        
    
    if (attributeValueC != NULL) {
        return [NSString stringWithUTF8String:(const char *)attributeValueC];
    }
    
    return nil;
}

- (NSString *)attribute:(NSString *)attributeName inNamespace:(NSString *)xmlNamespace {
    const unsigned char *attributeValueC = xmlGetNsProp(_node, (const xmlChar *)[attributeName cStringUsingEncoding:NSUTF8StringEncoding], (const xmlChar *)[xmlNamespace cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (attributeValueC != NULL) {
        return [NSString stringWithUTF8String:(const char *)attributeValueC];
    }
    
    return nil;
}

- (NSInteger)attributeAsInteger:(NSString *)attributeName {
    return [[self attribute:attributeName] integerValue];
}

- (NSInteger)attributeAsInteger:(NSString *)attributeName inNamespace:(NSString *)xmlNamespace {
    return [[self attribute:attributeName inNamespace:xmlNamespace] integerValue];
}

- (double)attributeAsDouble:(NSString *)attributeName {
    return [[self attribute:attributeName] doubleValue];
}

- (double)attributeAsDouble:(NSString *)attributeName inNamespace:(NSString *)xmlNamespace {
    return [[self attribute:attributeName inNamespace:xmlNamespace] doubleValue];
}

- (BOOL)isValid {
    return _document != nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Child Nodes
////////////////////////////////////////////////////////////////////////

- (RXMLElement *)childWithTagName:(NSString *)tagName {
    NSArray *components = [tagName componentsSeparatedByString:@"."];
    xmlNodePtr currentNode = _node;
    
    // navigate down
    for (NSString *currentTagName in components) {
        const xmlChar *tagNameC = (const xmlChar *)[currentTagName cStringUsingEncoding:NSUTF8StringEncoding];
        
        if ([currentTagName isEqualToString:@"*"]) {
            currentNode = currentNode->children;
            
            while (currentNode != NULL && currentNode->type != XML_ELEMENT_NODE) {
                currentNode = currentNode->next;
            }
        } else {
            currentNode = currentNode->children;
            while (currentNode != NULL) {
                if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0) {
                    break;
                }
                
                currentNode = currentNode->next;
            }
        }
        
        if (currentNode == NULL) {
            break;
        }
    }
    
    if (currentNode != NULL) {
        return [RXMLElement elementWithNode:currentNode];
    }
    
    return nil;
}

- (RXMLElement *)childWithTagName:(NSString *)tagName inNamespace:(NSString *)xmlNamespace {
    NSArray *components = [tagName componentsSeparatedByString:@"."];
    xmlNodePtr currentNode = _node;
    const xmlChar *namespaceC = (const xmlChar *)[xmlNamespace cStringUsingEncoding:NSUTF8StringEncoding];
    
    // navigate down
    for (NSString *currentTagName in components) {
        const xmlChar *tagNameC = (const xmlChar *)[currentTagName cStringUsingEncoding:NSUTF8StringEncoding];
        
        if ([currentTagName isEqualToString:@"*"]) {
            currentNode = currentNode->children;
            
            while (currentNode != NULL && currentNode->type != XML_ELEMENT_NODE && xmlStrcmp(currentNode->ns->href, namespaceC) == 0) {
                currentNode = currentNode->next;
            }
        } else {
            currentNode = currentNode->children;
            while (currentNode != NULL) {
                if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0 && xmlStrcmp(currentNode->ns->href, namespaceC) == 0) {
                    break;
                }
                
                currentNode = currentNode->next;
            }
        }
        
        if (currentNode == NULL) {
            break;
        }
    }
    
    if (currentNode != NULL) {
        return [RXMLElement elementWithNode:currentNode];
    }
    
    return nil;
}

- (NSArray *)childrenWithTagName:(NSString *)tagName {
    const xmlChar *tagNameC = (const xmlChar *)[tagName cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *children = [NSMutableArray array];
    xmlNodePtr currentNode = _node->children;
    
    while (currentNode != NULL) {
        if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0) {
            [children addObject:[RXMLElement elementWithNode:currentNode]];
        }
        
        currentNode = currentNode->next;
    }
    
    return [children copy];
}

- (NSArray *)childrenWithTagName:(NSString *)tagName inNamespace:(NSString *)xmlNamespace {
    const xmlChar *tagNameC = (const xmlChar *)[tagName cStringUsingEncoding:NSUTF8StringEncoding];
    const xmlChar *namespaceC = (const xmlChar *)[xmlNamespace cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *children = [NSMutableArray array];
    xmlNodePtr currentNode = _node->children;
    
    while (currentNode != NULL) {
        if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0 && xmlStrcmp(currentNode->ns->href, namespaceC) == 0) {
            [children addObject:[RXMLElement elementWithNode:currentNode]];
        }
        
        currentNode = currentNode->next;
    }
    
    return [children copy];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Block Iterations
////////////////////////////////////////////////////////////////////////

- (void)iteratePath:(NSString *)path usingBlock:(RXMLBlock)block {
    if (block == nil) {
        return;
    }
    
    NSArray *components = [path componentsSeparatedByString:@"."];
    xmlNodePtr currentNode = _node;
    
    // navigate down
    for (NSUInteger i=0; i < components.count; ++i) {
        NSString *currentTagName = [components objectAtIndex:i];
        
        if ([currentTagName isEqualToString:@"*"]) {
            currentNode = currentNode->children;
            
            // different behavior depending on if this is the end of the query or midstream
            if (i < (components.count - 1)) {
                // midstream
                do {
                    if (currentNode->type == XML_ELEMENT_NODE) {
                        RXMLElement *element = [RXMLElement elementWithNode:currentNode];
                        NSString *restOfQuery = [[components subarrayWithRange:NSMakeRange(i + 1, components.count - i - 1)] componentsJoinedByString:@"."];
                        
                        [element iteratePath:restOfQuery usingBlock:block];
                    }
                    
                    currentNode = currentNode->next;
                } while (currentNode != nil);
                
            }
        } else {
            const xmlChar *tagNameC = (const xmlChar *)[currentTagName cStringUsingEncoding:NSUTF8StringEncoding];
            
            currentNode = currentNode->children;
            while (currentNode != NULL) {
                if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0) {
                    break;
                }
                
                currentNode = currentNode->next;
            }
        }
        
        if (currentNode == NULL) {
            break;
        }
    }
    
    if (currentNode != NULL) {
        // enumerate
        NSString *childTagName = [components lastObject];
        
        do {
            if (currentNode->type == XML_ELEMENT_NODE) {
                RXMLElement *element = [RXMLElement elementWithNode:currentNode];
                block(element);
            }
            
            if ([childTagName isEqualToString:@"*"]) {
                currentNode = currentNode->next;
            } else {
                const xmlChar *tagNameC = (const xmlChar *)[childTagName cStringUsingEncoding:NSUTF8StringEncoding];
                
                while ((currentNode = currentNode->next) != NULL) {
                    if (currentNode->type == XML_ELEMENT_NODE && xmlStrcmp(currentNode->name, tagNameC) == 0) {
                        break;
                    }                    
                }
            }
        } while (currentNode != NULL);
    }
}

- (void)iterateElements:(NSArray *)elements usingBlock:(RXMLBlock)block {
    if (block != nil) {
        for (RXMLElement *element in elements) {
            block(element);
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - XPath
////////////////////////////////////////////////////////////////////////

- (NSArray *)childrenMatchingXPathQuery:(NSString *)query {
    xmlXPathContextPtr context = xmlXPathNewContext(_document);
    
    if (context == NULL) {
		return nil;
    }
    
    xmlXPathObjectPtr object = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], context);
    if(object == NULL) {
		return nil;
    }
	
	xmlNodeSetPtr nodes = object->nodesetval;
	if (nodes == NULL) {
		return nil;
	}
	
	NSMutableArray *resultNodes = [NSMutableArray array];
	
    for (NSInteger i = 0; i < nodes->nodeNr; i++) {
		RXMLElement *element = [RXMLElement elementWithNode:nodes->nodeTab[i]];
        
		if (element != NULL) {
			[resultNodes addObject:element];
		}
	}
    
    xmlXPathFreeObject(object);
    xmlXPathFreeContext(context); 
    
    return resultNodes;
}

- (void)iterateChildrenMatchingXPathQuery:(NSString *)query usingBlock:(RXMLBlock)block {
    NSArray *children = [self childrenMatchingXPathQuery:query];
    
    [self iterateElements:children usingBlock:block];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setupWithData:(NSData *)data {
    _document = xmlReadMemory([data bytes], (int)[data length], "", nil, XML_PARSE_RECOVER);
    
    if ([self isValid]) {
        _node = xmlDocGetRootElement(_document);
        
        if (_node == NULL) {
            xmlFreeDoc(_document);
            _document = nil;
        }
    }
}

@end
