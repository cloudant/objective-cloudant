//
//  CDTGetViewOperation.h
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

#import <ObjectiveCloudant/ObjectiveCloudant.h>

typedef NS_ENUM(NSUInteger, CDTStale) {
    /**
     Do not allow stale views.
     **/
    CDTStaleViewNo,
    /**
     Allow stale views.
     **/
    CDTStaleViewOk,
    /**
     Allow stale views, but update them immediately after the request.
     **/
    CDTStaleViewUpdateAfter
};

/**
 An operation to query Map Reduce views.
 */
@interface CDTQueryViewOperation : CDTCouchDatabaseOperation

/**
 * The name of the design document which contains the view.
 *
 * Required: This needs to be set before an operation can successfully run.
 */
@property (nullable, nonatomic, strong) NSString *ddoc;

/**
 * The name of the view to query.
 *
 * Required: This needs to be set before an operation can succesfully run.
 */
@property (nullable, nonatomic, strong) NSString *viewName;

/**
 * Return the documents in 'descending by key' order.
 *
 * Default : NO, order is aescending by key.
 */
@property (nonatomic) BOOL descending;

/**
 * Stop the view returning results when the specified key is reached.
 * It must be set to an Object of type `NSString*` or `NSArray<NSString*>*`.
 *
 * Optional: CouchDB will return all the results if this is not set.
 */
@property (nullable, nonatomic, strong) NSObject *endKey;

/**
 * Stop the view returning results when the specified document ID is reached.
 *
 * Optional: CouchDB will return all the results if this is not set.
 */
@property (nullable, nonatomic, strong) NSString *endkeyDocId;

/**
 * Group the results of a reduced based on their keys.
 *
 * Default: NO.
 */
@property (nonatomic) BOOL group;

/**
 * Group reduce results for documents with complex keys. Using the first x number of items in the
 * complex key array, where x is the group level.
 *
 * For example, if you had the complex key : ["A","B", "C", "D"], if groupLevel is set to 3,
 * "A", "B" and "C" would be used to group the view results.
 *
 * Optional: CouchDB will use the default groupLevel if grouping is enabled, negative values will
 * result in the parameter not being included in requests
 **/
@property (nonatomic) NSInteger groupLevel;

/**
 * Include the full document content in the view results.
 *
 * Default: NO
 */
@property (nonatomic) BOOL includeDocs;

/**
 * Include rows with the specified `endKey`.
 *
 * Default: NO.
 */
@property (nonatomic) BOOL inclusiveEnd;

/**
 * Return only documents that match the specified key.
 * The key must be of type `NSString*` or `NSArray<NSString*>*`
 *
 * Cannot be used with `key` option.
 *
 * Optional: CouchDB will return all documents emitted from the view.
 */
@property (nullable, nonatomic, strong) NSObject *key;

/**
 * Return only the documents that match the specified keys.
 * The keys in the array must be of type `NSString*` or `NSArray<NSString*>*`
 *
 * Optional: CouchDB will return all documents emitted from the view.
 */
@property (nullable, nonatomic, strong) NSArray<NSObject *> *keys;

/**
 * Limit the number of documents returned from the view.
 *
 * Optional: CouchDB will return all documents emitted from the view, negative values will
 * result in the parameter not being included in requests.
 */
@property (nonatomic) NSInteger limit;

/**
 * Use the reduce function for the view.
 *
 * Default: NO.
 */
@property (nonatomic) BOOL reduce;

/**
 * The number of rows to skip in the view results.
 *
 * Optional, CouchDB will noy skip any matching rows, negative values will
 * result in the parameter not being included in requests
 */
@property (nonatomic) NSInteger skip;

/**
 * Allows a stale view to be used to return a result, this allows the request
 * to return imediately and not wait for views to build.
 *
 * Default: CDTStaleViewNo.
 *
 * WANRING: This is an advanced option, it should not be used unless you know exactly what you are
 * doing, it will be deterimental to performance.
 */
@property (nonatomic) CDTStale stale;

/**
 * Return records starting with the specified key.
 * The key must be of type `NSString*` or `NSArray<NSString*>*`.
 *
 * Optional: CouchDB will return all records emitted from the view.
 *
 */
@property (nullable, nonatomic, strong) NSObject *startKey;

/**
 * Return records starting with the specified document ID.
 *
 * Optional: CouchDB will return all records emitted from the view.
 */
@property (nullable, nonatomic, strong) NSString *startKeyDocId;

/**
 * Block to run for each row in response to the view query.
 *
 * - row - a row in the response to the view query.
 **/
@property (nullable, nonatomic, strong) void (^viewRowBlock)
    (NSDictionary<NSString *, NSObject *> *_Nonnull row);

/**
 *  Completion blokc to run when the operation completes.
 *
 * - error a pointer to an error object containing information about an error executing the
 * operation.
 */
@property (nullable, nonatomic, strong) void (^queryViewCompletionBlock)(NSError *_Nullable error);
@end
