//
//  MTLParseAdapterTests.m
//  MTLParseAdapterTests
//
//  Created by Mike Walker on 02/06/2015.
//  Copyright (c) 2014 Mike Walker. All rights reserved.
//

#import <MTLParseAdapter/MTLParseAdapter.h>
#import <Parse/Parse.h>

#import "TestObject.h"

SpecBegin(MTLParseAdapter)

describe(@"MTLParseAdapter", ^{
    describe(@"converting a single object", ^{
        describe(@"converting from a domain object to a Parse object", ^{
            __block TestObject *object;
            __block PFObject *parseObject;

            beforeEach(^{
                object = [[TestObject alloc] init];
                object.name = @"name";
                object.number = @5;
                object.integerNumber = 10;

                object.nestedObject = [[TestObject alloc] init];
                object.nestedObject.name = @"name2";

                object.objectId = @"id";
                object.parseClassName = @"className";
                object.createdAt = [NSDate date];
                object.updatedAt = [NSDate dateWithTimeIntervalSinceNow:-1000];

                parseObject = [MTLParseAdapter parseObjectFromModel:object];
            });

            it(@"should have the same values for core Obj-C datatypes", ^{
                expect(parseObject[@"name"]).to.equal(@"name");
            });

            it(@"should respect +JSONKeyPathsByPropertyKey", ^{
                expect(parseObject[@"number"]).to.beNil;
                expect(parseObject[@"numberWithDifferentJSONKey"]).to.equal(@5);
            });

            it(@"should auto-box non-object types", ^{
                expect(parseObject[@"integerNumber"]).to.equal(@10);
            });

            it(@"should properly use value transformers", ^{
                expect(parseObject[@"nestedObject"]).to.beInstanceOf(PFObject.class);
                expect(parseObject[@"nestedObject"][@"name"]).to.equal(@"name2");
            });

            context(@"when a property is a special Parse property", ^{
                it(@"should not be set in the object dictionary", ^{
                    expect(parseObject[@"objectId"]).to.beNil;
                    expect(parseObject[@"parseClassName"]).to.beNil;
                    expect(parseObject[@"createdAt"]).to.beNil;
                    expect(parseObject[@"updatedAt"]).to.beNil;
                });

                it(@"should set the appropriate PFObject property", ^{
                    expect(parseObject.objectId).to.equal(@"id");
                    expect(parseObject.parseClassName).to.equal(@"className");
                    expect(parseObject.createdAt).to.equal(object.createdAt);
                    expect(parseObject.updatedAt).to.equal(object.updatedAt);
                });
            });

            context(@"when there is no parseClassName set", ^{
                it(@"should default to the model class name", ^{
                    TestObject *obj = [[TestObject alloc] init];
                    PFObject *parseObj = [MTLParseAdapter parseObjectFromModel:obj];
                    expect(parseObj.parseClassName).to.equal(@"TestObject");
                });
            });
        });

        describe(@"converting from a Parse object to a domain object", ^{
            __block TestObject *object;
            __block PFObject *parseObject;

            beforeEach(^{
                NSDictionary *params = @{
                    @"name": @"Dan",
                    @"numberWithDifferentJSONKey": @8,
                    @"integerNumber": @9,
                    @"nestedObject": [PFObject objectWithClassName:@"TestParseObject"]
                };
                parseObject = [PFObject objectWithClassName:@"TestParseObject"
                                                 dictionary:params];

                parseObject.objectId = @"objectId";

                object = (TestObject *)[MTLParseAdapter modelOfClass:TestObject.class fromParseObject:parseObject];
            });

            it(@"should have the same values for core Obj-C datatypes", ^{
                expect(object.name).to.equal(@"Dan");
            });

            it(@"should respect +JSONKeyPathsByPropertyKey", ^{
                expect(object.number).to.equal(@8);
            });

            it(@"should auto-unbox non-object types", ^{
                expect(object.integerNumber).to.equal(9);
            });

            it(@"should properly use value transformers", ^{
                expect(object.nestedObject).to.beInstanceOf(TestObject.class);
            });

            context(@"when a property is a special Parse property", ^{
                it(@"should not be set in the object dictionary", ^{
                    expect(parseObject[@"objectId"]).to.beNil;
                    expect(parseObject[@"parseClassName"]).to.beNil;
                    expect(parseObject[@"createdAt"]).to.beNil;
                    expect(parseObject[@"updatedAt"]).to.beNil;
                });

                it(@"should set the appropriate PFObject property", ^{
                    expect(parseObject.objectId).to.equal(@"objectId");
                    expect(parseObject.parseClassName).to.equal(@"TestParseObject");
                    expect(parseObject.createdAt).to.equal(object.createdAt);
                    expect(parseObject.updatedAt).to.equal(object.updatedAt);
                });
            });

            context(@"when there is no parseClassName set", ^{
                it(@"should default to the model class name", ^{
                    TestObject *obj = [[TestObject alloc] init];
                    PFObject *parseObj = [MTLParseAdapter parseObjectFromModel:obj];
                    expect(parseObj.parseClassName).to.equal(@"TestObject");
                });
            });

            context(@"when there is no model class given", ^{
                it(@"should infer class name from Parse class name", ^{
                    parseObject = [PFObject objectWithClassName:NSStringFromClass(TestObject.class)];
                    object = (TestObject *)[MTLParseAdapter modelFromParseObject:parseObject];
                    expect(object).to.beInstanceOf(TestObject.class);
                });
            });
        });
    });
});

SpecEnd
