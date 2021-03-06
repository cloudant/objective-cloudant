//
//  CreateDatabaseTests.m
//  ObjectiveCloudant
//
//  Created by Michael Rhodes on 16/09/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <XCTest/XCTest.h>

#import <ObjectiveCloudant/ObjectiveCloudant.h>

#import "TestHelpers.h"

@interface CreateDatabaseTests : XCTestCase

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@end

@implementation CreateDatabaseTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the
    // class.

    self.url = @"http://localhost:5984";
    self.username = nil;
    self.password = nil;

    // These tests require their own database as they modify content; create one

    self.dbName = [NSString stringWithFormat:@"%@-test-database-%@", REMOTE_DB_PREFIX,
                                             [TestHelpers generateRandomString:5]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.

    CDTCouchDBClient *client = [CDTCouchDBClient clientForURL:[NSURL URLWithString:self.url]
                                                     username:self.username
                                                     password:self.password];

    CDTDeleteDatabaseOperation *delete = [[CDTDeleteDatabaseOperation alloc] init];
    delete.databaseName = self.dbName;
    [client addOperation:delete];
    [delete waitUntilFinished];

    [super tearDown];
}

- (void)testCreateUsingPut
{
    CDTCouchDBClient *client = [CDTCouchDBClient clientForURL:[NSURL URLWithString:self.url]
                                                     username:self.username
                                                     password:self.password];

    __block NSInteger statusCode;

    CDTCreateDatabaseOperation *op = [[CDTCreateDatabaseOperation alloc] init];
    op.databaseName = self.dbName;
    op.createDatabaseCompletionBlock = ^(NSInteger sc, NSError *err) { statusCode = sc; };
    [client addOperation:op];
    [op waitUntilFinished];

    XCTAssertTrue((statusCode == 201 || statusCode == 202), @"status code was %lu", statusCode);
}

@end
