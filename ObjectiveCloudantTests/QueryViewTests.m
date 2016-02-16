//
//  QueryViewTests.m
//  ObjectiveCloudant
//
//  Created by Rhys Short on 15/02/2016.
//  Copyright (c) 2016 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <XCTest/XCTest.h>
#import <ObjectiveCloudant/ObjectiveCloudant.h>
#import "TestHelpers.h"

@interface QueryViewTests : XCTestCase
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) CDTDatabase *database;
@end

@implementation QueryViewTests

- (void)setUp
{
    [super setUp];

    self.url = @"http://localhost:5984";
    self.username = nil;
    self.password = nil;

    // These tests require their own database as they modify content; create one

    self.dbName = @"objectivecouch-test";

    CDTCouchDBClient *client = [CDTCouchDBClient clientForURL:[NSURL URLWithString:self.url]
                                                     username:self.username
                                                     password:self.password];
    self.database = client[self.dbName];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.
    [super tearDown];
}

- (void)testfailsWithKeyandKeysSet
{
    XCTestExpectation *completionFailed =
        [self expectationWithDescription:@"Keys and Key property set"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.key = @"key";
    op.keys = @[ @"keys" ];

    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testfailsMissingDdoc
{
    XCTestExpectation *completionFailed = [self expectationWithDescription:@"missing ddoc"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.viewName = @"diet";
    op.key = @"key";
    op.keys = @[ @"keys" ];

    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testfailsMissingViewNAME
{
    XCTestExpectation *completionFailed = [self expectationWithDescription:@"Missing view name"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.key = @"key";
    op.keys = @[ @"keys" ];

    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testCorrectlyQueryViewNoOptions
{
    XCTestExpectation *requestCompleted =
        [self expectationWithDescription:@"Succesfully view query"];
    XCTestExpectation *viewRowBlockCalled = [self expectationWithDescription:@"Document Found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlockCalled fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(10, numberOfDocs);
}

- (void)testCorrectlyQueryViewLimit1
{
    XCTestExpectation *requestCompleted =
        [self expectationWithDescription:@"Succesfully view query"];
    XCTestExpectation *viewRowBlockCalled = [self expectationWithDescription:@"Document Found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.limit = 1;

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      [viewRowBlockCalled fulfill];
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testCorrectlyQueryViewDescending
{
    NSArray *expectedOrderOfKeys = @[
        @"omnivore",
        @"omnivore",
        @"omnivore",
        @"omnivore",
        @"herbivore",
        @"herbivore",
        @"herbivore",
        @"herbivore",
        @"carnivore",
        @"carnivore",
    ];

    XCTestExpectation *requestCompleted =
        [self expectationWithDescription:@"Succesfully view query"];
    XCTestExpectation *viewRowBlockCalled = [self expectationWithDescription:@"Document Found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.descending = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    NSMutableArray<NSString *> *orderedKeys = [NSMutableArray array];

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlockCalled fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);

      [orderedKeys addObject:doc[@"key"]];
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(10, numberOfDocs);
    XCTAssertEqualObjects(expectedOrderOfKeys, orderedKeys);
}

- (void)testfailsWithGroupingOnNonGroupableView
{
    XCTestExpectation *completionFailed = [self expectationWithDescription:@"Grouping on view"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.group = YES;

    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testCorrectlyQueryViewInculdingDocs
{
    XCTestExpectation *requestCompleted =
        [self expectationWithDescription:@"Succesfully view query"];
    XCTestExpectation *viewRowBlockCalled = [self expectationWithDescription:@"Document Found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.includeDocs = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlockCalled fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
      // Make sure the doc field is present.
      XCTAssertNotNil(doc[@"doc"]);

    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(10, numberOfDocs);
}

- (void)testCorrectlyQueryViewSkipDocs
{
    XCTestExpectation *requestCompleted =
        [self expectationWithDescription:@"Succesfully view query"];
    XCTestExpectation *viewRowBlockCalled = [self expectationWithDescription:@"Document Found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.skip = 9;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlockCalled fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);

    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(1, numberOfDocs);
}

- (void)testCorrectlyPages
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.limit = 5;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    __block NSString *lastDocId;
    __block NSString *lastKey;

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);

      lastDocId = (NSString *)doc[@"id"];
      lastKey = (NSString *)doc[@"key"];

    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(5, numberOfDocs);

    XCTestExpectation *secondPageRequest =
        [self expectationWithDescription:@"second page query sucuess"];
    XCTestExpectation *foundDocuments =
        [self expectationWithDescription:@"second page of documents"];

    op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";

    op.startKey = lastKey;
    op.startKeyDocId = lastDocId;

    // reset block variables
    numberOfDocs = 0;
    firstDoc = YES;

    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [foundDocuments fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [secondPageRequest fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    // expect 6 since we will see one doc twice.
    XCTAssertEqual(6, numberOfDocs);
}

- (void)testAbleToLimtDocsByStartKeyAndEndKey
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.startKey = @"carnivore";
    op.startKeyDocId = @"panda";
    op.endKey = @"herbivore";
    op.endkeyDocId = @"giraffe";

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(2, numberOfDocs);
}

- (void)testAbleToLimtDocsByStartKeyAndEndKeyInclusiveEnd
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.startKey = @"carnivore";
    op.startKeyDocId = @"panda";
    op.endKey = @"herbivore";
    op.endkeyDocId = @"giraffe";
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(3, numberOfDocs);
}

- (void)testSuccessfulViewQueryReduce
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet_count";
    op.reduce = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(1, numberOfDocs);
}

- (void)testSuccessfulViewQueryNoRowHandler
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet_count";
    op.reduce = YES;

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testAbleToLimtDocsByStartKeyAndEndKeyInclusiveEndComplex
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"complex_count";
    op.startKey = @[ @"bird", @"omnivore" ];
    op.startKeyDocId = @"snipe";
    op.endKey = @[ @"mammal", @"herbivore" ];
    op.endkeyDocId = @"giraffe";
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(4, numberOfDocs);
}

- (void)testFailureStartKeyIsInvalid
{
    XCTestExpectation *completionFailed =
        [self expectationWithDescription:@"Keys and Key property set"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.startKey = @{};

    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testFailureEndKeyIsInvalid
{
    XCTestExpectation *completionFailed =
        [self expectationWithDescription:@"Keys and Key property set"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.endKey = @{};
    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testFailureKeyIsInvalid
{
    XCTestExpectation *completionFailed =
        [self expectationWithDescription:@"Keys and Key property set"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.key = @{};
    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testFailureKeysIsInvalid
{
    XCTestExpectation *completionFailed =
        [self expectationWithDescription:@"Keys and Key property set"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.keys = @{};
    op.queryViewCompletionBlock = ^(NSError *error) {
      [completionFailed fulfill];
      XCTAssertNotNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];
}

- (void)testSuccessfulQueryViewWithKeyAsString
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.key = @"carnivore";
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(2, numberOfDocs);
}

- (void)testSuccessfulQueryViewWithKeyAsArray
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"complex_count";
    op.key = @[ @"bird", @"omnivore" ];
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(1, numberOfDocs);
}

- (void)testSuccessfulQueryViewWithKeysAsString
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"diet";
    op.keys = @[ @"carnivore", @"omnivore" ];
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(6, numberOfDocs);
}

- (void)testSuccessfulQueryViewWithKeysAsArray
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"complex_count";
    op.keys = @[ @[ @"bird", @"omnivore" ], @[ @"mammal", @"omnivore" ] ];
    op.inclusiveEnd = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"id"]);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(4, numberOfDocs);
}

- (void)testSuccessfulQueryViewWithGrouping
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"complex_count";
    op.group = YES;
    op.reduce = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(5, numberOfDocs);
}

- (void)testSuccessfulQueryViewWithGroupLevel
{
    XCTestExpectation *requestCompleted = [self expectationWithDescription:@"Succesfully query db"];
    XCTestExpectation *viewRowBlock = [self expectationWithDescription:@"Document found"];

    CDTQueryViewOperation *op = [[CDTQueryViewOperation alloc] init];
    op.ddoc = @"views101";
    op.viewName = @"complex_latin_name_count";
    op.group = YES;
    op.groupLevel = 2;
    op.reduce = YES;

    __block int numberOfDocs = 0;
    __block BOOL firstDoc = YES;
    op.viewRowBlock = ^(NSDictionary<NSString *, NSObject *> *doc) {
      if (firstDoc) {
          firstDoc = NO;
          [viewRowBlock fulfill];
      }
      numberOfDocs++;
      XCTAssertNotNil(doc);
      XCTAssertNotNil(doc[@"key"]);
      XCTAssertNotNil(doc[@"value"]);
    };

    op.queryViewCompletionBlock = ^(NSError *error) {
      [requestCompleted fulfill];
      XCTAssertNil(error);
    };

    [self.database addOperation:op];

    [self waitForExpectationsWithTimeout:10.0f
                                 handler:^(NSError *_Nullable error) {
                                   NSLog(@"Operation completion handler not called");
                                 }];

    XCTAssertEqual(4, numberOfDocs);
}

@end
