//
//  CDTDatabase.h
//  ObjectiveCouch
//
//  Created by Michael Rhodes on 15/08/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <Foundation/Foundation.h>

@class CDTCouchDBClient;
@class CDTGetDocumentOperation;
@class CDTCouchDatabaseOperation;

@interface CDTDatabase : NSObject

/**
 Initialises a new database object with a CouchDB client and database name.
 */
- (nullable instancetype)initWithClient:(nonnull CDTCouchDBClient *)client
                           databaseName:(nonnull NSString *)name;

/**
 Add an operation to be executed within the context of this database object.

 Internally this sets the database URL and access credentials based on the
 database this object represents and the client it uses to access the remote
 database.
 */
- (void)addOperation:(nonnull CDTCouchDatabaseOperation *)operation;

/**
 Synchronously access a document in this database.
 */
- (nullable NSDictionary *)objectForKeyedSubscript:(nonnull NSString *)key;

/**
 Convenience method for retrieving the latest version of a document.

 Use a CDTGetDocumentOperation for greater control.
 */
- (void)getDocumentWithId:(nonnull NSString *)documentId
        completionHandler:
            (void (^_Nonnull)(NSDictionary<NSString *, NSObject *> *_Nullable document,
                              NSError *_Nullable error))completionHandler;

- (void)getDocumentWithId:(nonnull NSString *)documentId
               revisionId:(nonnull NSString *)revId
        completionHandler:
            (void (^_Nonnull)(NSDictionary<NSString *, NSObject *> *_Nullable document,
                              NSError *_Nullable operationError))completionHandler;

/**
 Convenience method of deleting documents from the database

 Use a CDTDeleteDoucmentOperation for greater control.

 @param documentId the id of the document to delete
 @param revId the revision of the document to delete
 @param completionHandler a block of code to call when the operation has been completed
 */
- (void)deleteDocumentWithId:(nonnull NSString *)documentId
                  revisionId:(nonnull NSString *)revId
         completetionHandler:
             (void (^_Nonnull)(NSInteger statusCode, NSError *_Nullable error))completionHandler;

/**
 Convenience method for creating a document

 Use a CDTPutDocumentOperation for greater control.

 @param documentId the id of the document to create.
 @param body the body of the document to create
 @param completionHandler a block of code to call when the operation has been completed
 */
- (void)putDocumentWithId:(nonnull NSString *)documentId
                     body:(nonnull NSDictionary<NSString *, NSObject *> *)body
        completionHandler:(void (^_Nonnull)(NSString *_Nullable docId, NSString *_Nullable revId,
                                            NSInteger statusCode,
                                            NSError *_Nullable operationError))completionHandler;
/**
 Convenience method for updating a document

 Use a CDTPutDocumentOperation for greater control.

 @param documentId the id of the document to update.
 @param revId the revision id of the document that is being update
 @param body the body of the document to update
 @param completionHandler a block of code to call when the operation has been completed
 */
- (void)putDocumentWithId:(nonnull NSString *)documentId
               revisionId:(nonnull NSString *)revId
                     body:(nonnull NSDictionary<NSString *, NSObject *> *)body
        completionHandler:(void (^_Nonnull)(NSString *_Nullable docId, NSString *_Nullable revId,
                                            NSInteger statusCode,
                                            NSError *_Nullable operationError))completionHandler;

/**
 Convenience method for creating a JSON Query Index.

 Use CDTCreateQueryIndexOperation for greater control.

 @param indexName the name of the index to create
 @param fields the fields to be indexed
 @param completionHandler a block to call when the operation has been completed
 */
- (void)createJSONQueryIndexWithName:(nonnull NSString *)indexName
                              fields:(nonnull NSArray<NSObject *> *)fields
                   completionHandler:
                       (void (^_Nonnull)(NSError *_Nullable operationError))completionHandler;

/**
 Convience method for creating a Text Query Index

 Use CDTCreateQueryIndexOperation for greater control.

 @param indexName the name of the index to create
 @param fields the fields to be indexed
 @param completionHandler a block to call when the operation has been completed
 */
- (void)createTextQueryIndexWithname:(nonnull NSString *)indexName
                              fields:(nonnull NSArray<NSObject *> *)fields
                   completionHandler:
                       (void (^_Nonnull)(NSError *_Nullable operationError))completionHandler;

/**
 Convenience method for finding documents using Cloudant Query

 Use CDTQueryFindDocumentsOperation for greater control.

 @param selector the selector to use to find documents
 @param documentHandler code block to run for each document found to match the selector
 @param completionHandler code block to run when the operation is complete
 */
- (void)findDocumentsUsingSeletor:(nonnull NSDictionary<NSString *, NSObject *> *)selector
                  documentHandler:
                      (void (^_Nonnull)(NSDictionary<NSString *, NSObject *> *_Nonnull document))
                          documentHandler
                completionHandler:(void (^_Nonnull)(NSString *_Nullable bookmark,
                                                    NSError *_Nullable error))completionHandler;

/**
 Convenience method for deleting Cloudant Query JSON indexes

 Use CDTDeleteQueryIndexOperation for greater control.

 @param indexname the name of the index tot delete
 @param designDocumentName the name of the design document that contains the index
 @param completionHander a block to run when the operation completes
 */
- (void)deleteJSONQueryIndexWithName:(nonnull NSString *)indexName
                  designDocumentName:(nonnull NSString *)designDocumentName
                   completionHandler:
                       (void (^_Nonnull)(NSInteger status,
                                         NSError *_Nullable operationError))completionHandler;

/**
 Convenience method for deleting Cloudant Query Text indexes

 Use CDTDeleteQueryIndexOperation for greater control.

 @param indexname the name of the index tot delete
 @param designDocumentName the name of the design document that contains the index
 @param completionHander a block to run when the operation completes
 */
- (void)deleteTextQueryIndexWithName:(nonnull NSString *)indexName
                  designDocumentName:(nonnull NSString *)designDocumentName
                   completionHandler:
                       (void (^_Nonnull)(NSInteger status,
                                         NSError *_Nullable operationError))completionHandler;

@end
