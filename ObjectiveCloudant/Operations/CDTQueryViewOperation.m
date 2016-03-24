//
//  CDTQueryViewOperation.m
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
#import "CDTQueryViewOperation.h"

static const int kCDTDefaultOperationIntegerValue = -1;

@implementation CDTQueryViewOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _descending = NO;
        _group = NO;
        _groupLevel = kCDTDefaultOperationIntegerValue;
        _includeDocs = NO;
        _inclusiveEnd = NO;
        _reduce = NO;
        _limit = kCDTDefaultOperationIntegerValue;
        _skip = kCDTDefaultOperationIntegerValue;
        _stale = CDTStaleViewNo;
    }
    return self;
}

- (BOOL)buildAndValidate
{
    if (![super buildAndValidate]) {
        return NO;
    }

    if (!self.ddoc) {
        return NO;
    }

    if (!self.viewName) {
        return NO;
    }

    // Query params

    if (self.endKey && ![CDTQueryViewOperation isValidStringOrJsonArray:self.endKey]) {
        return NO;
    }

    if (self.endkeyDocId && ![CDTQueryViewOperation isValidStringOrJsonArray:self.endkeyDocId]) {
        return NO;
    }

    if (self.key && self.keys) {
        return NO;
    }

    if (self.key && ![CDTQueryViewOperation isValidStringOrJsonArray:self.key]) {
        return NO;
    }

    if (self.keys && ![CDTQueryViewOperation isValidStringOrJsonArray:self.keys]) {
        return NO;
    }

    if (self.startKey && ![CDTQueryViewOperation isValidStringOrJsonArray:self.startKey]) {
        return NO;
    }

    if (self.startKeyDocId &&
        ![CDTQueryViewOperation isValidStringOrJsonArray:self.startKeyDocId]) {
        return NO;
    }

    return YES;
}

- (NSString *)httpMethod { return @"GET"; }
- (NSString *)httpPath
{
    return [NSString
        stringWithFormat:@"/%@/_design/%@/_view/%@", self.databaseName, self.ddoc, self.viewName];
}

- (nonnull NSArray<NSURLQueryItem *> *)queryItems
{
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray array];

    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"descending"
                                                      value:[CDTQueryViewOperation
                                                                stringForBoolean:self.descending]]];
    if (self.endKey) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"endkey"
                                                          value:[CDTQueryViewOperation
                                                                    stringForObject:self.endKey]]];
    }

    if (self.endkeyDocId) {
        [queryItems
            addObject:[NSURLQueryItem queryItemWithName:@"endkey_docid" value:self.endkeyDocId]];
    }

    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"group"
                                                      value:[CDTQueryViewOperation
                                                                stringForBoolean:self.group]]];

    if (self.groupLevel != kCDTDefaultOperationIntegerValue) {
        [queryItems
            addObject:[NSURLQueryItem
                          queryItemWithName:@"group_level"
                                      value:[NSString
                                                stringWithFormat:@"%ld", (long)self.groupLevel]]];
    }

    [queryItems
        addObject:[NSURLQueryItem
                      queryItemWithName:@"include_docs"
                                  value:[CDTQueryViewOperation stringForBoolean:self.includeDocs]]];

    [queryItems
        addObject:[NSURLQueryItem queryItemWithName:@"inclusive_end"
                                              value:[CDTQueryViewOperation
                                                        stringForBoolean:self.inclusiveEnd]]];

    if (self.key) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"key"
                                                          value:[CDTQueryViewOperation
                                                                    stringForObject:self.key]]];
    }

    if (self.keys) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"keys"
                                                          value:[CDTQueryViewOperation
                                                                    stringForObject:self.keys]]];
    }

    if (self.limit != kCDTDefaultOperationIntegerValue) {
        [queryItems
            addObject:[NSURLQueryItem
                          queryItemWithName:@"limit"
                                      value:[NSString stringWithFormat:@"%ld", (long)self.limit]]];
    }

    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"reduce"
                                                      value:[CDTQueryViewOperation
                                                                stringForBoolean:self.reduce]]];

    if (self.skip != kCDTDefaultOperationIntegerValue) {
        [queryItems
            addObject:[NSURLQueryItem
                          queryItemWithName:@"skip"
                                      value:[NSString stringWithFormat:@"%ld", (long)self.skip]]];
    }

    NSURLQueryItem *stale = [CDTQueryViewOperation QueryItemForStaleState:self.stale];

    if (stale) {
        [queryItems addObject:stale];
    }

    if (self.startKey) {
        [queryItems
            addObject:[NSURLQueryItem
                          queryItemWithName:@"startkey"
                                      value:[CDTQueryViewOperation stringForObject:self.startKey]]];
    }

    if (self.startKeyDocId) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"startkey_docid"
                                                          value:self.startKeyDocId]];
    }

    return [queryItems copy];
}

- (void)callCompletionHandlerWithError:(NSError *)error
{
    if (self && self.queryViewCompletionBlock) {
        self.queryViewCompletionBlock(error);
    }
}

- (void)processResponseWithData:(NSData *)responseData
                     statusCode:(NSInteger)statusCode
                          error:(NSError *)error
{
    if (error) {
        [self callCompletionHandlerWithError:error];
    } else if (statusCode / 100 == 2) {
        // process the things!
        NSError *jsonError;
        NSDictionary<NSString *, NSObject *> *responseJson =
            [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];

        if (!responseJson) {
            [self callCompletionHandlerWithError:jsonError];
        } else {
            if (self.viewRowBlock) {
                for (NSDictionary<NSString *, NSObject *> *row in(
                         NSArray<NSDictionary<NSString *, NSObject *> *> *)responseJson[@"rows"]) {
                    self.viewRowBlock(row);
                }
            }
            if (self.queryViewCompletionBlock) {
                self.queryViewCompletionBlock(nil);
            }
        }

    } else {
        NSString *json = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSString *msg = [NSString
            stringWithFormat:@"Querying view failed with %ld %@.", (long)statusCode, json];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
        error = [NSError errorWithDomain:CDTObjectiveCloudantErrorDomain
                                    code:CDTObjectiveCloudantErrorQueryViewFailed
                                userInfo:userInfo];

        [self callCompletionHandlerWithError:error];
    }
}

+ (BOOL)isValidStringOrJsonArray:(NSObject *)obj
{
    if ([obj isKindOfClass:[NSArray class]]) {
        if (![NSJSONSerialization isValidJSONObject:obj]) {
            return NO;
        }
    } else if (![obj isKindOfClass:[NSString class]]) {
        return NO;
    }

    return YES;
}

+ (NSString *)stringForBoolean:(BOOL)boolean
{
    if (boolean) {
        return @"true";
    } else {
        return @"false";
    }
}

+ (NSString *)stringForObject:(NSObject *)obj
{
    if ([obj isKindOfClass:[NSArray class]]) {
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];

        if (error) {
            // well we need to error here
            @throw [NSException exceptionWithName:@"JSONSerialisationError"
                                           reason:@"Could not seralise array into json"
                                         userInfo:nil];
        }

        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    } else if ([obj isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"\"%@\"", (NSString *)obj];
    } else {
        return [NSString stringWithFormat:@"\"%@\"", [obj description]];
    }
}

+ (NSURLQueryItem *)QueryItemForStaleState:(CDTStale)stale
{
    NSString *staleStr;

    switch (stale) {
        case CDTStaleViewNo:
            return nil;
            break;
        case CDTStaleViewOk:
            staleStr = @"ok";
            break;

        case CDTStaleViewUpdateAfter:
            staleStr = @"updateafter";
            break;
    }

    return [NSURLQueryItem queryItemWithName:@"stale" value:staleStr];
}

@end
