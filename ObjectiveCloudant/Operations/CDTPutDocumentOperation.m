//
//  CDTPutDocumentOperation.m
//  ObjectiveCloudant
//
//  Created by Michael Rhodes on 16/09/2015.
//  Copyright © 2015 Small Text. All rights reserved.
//

#import "CDTPutDocumentOperation.h"

@implementation CDTPutDocumentOperation

- (BOOL)buildAndValidate
{
    if(![super buildAndValidate]){
        return NO;
    }

    
    if(!self.docId){
        NSLog(@"docId was nil");
        return NO;
    } else if (!self.body) {
        NSLog(@"body was nil");
        return NO;
    } else if (![NSJSONSerialization isValidJSONObject:self.body]){
        NSLog(@"body was invalid JSON");
        return NO;
    }

    NSMutableArray *tmp = [NSMutableArray array];

    if (self.revId) {
        [tmp addObject:[NSURLQueryItem queryItemWithName:@"rev" value:self.revId]];
    }

    self.queryItems = [NSArray arrayWithArray:tmp];
    return YES;
}

#pragma mark Instance methods

- (void)dispatchAsyncHttpRequest
{
    NSString *path = [NSString stringWithFormat:@"/%@/%@", self.databaseName, self.docId];

    NSURLComponents *components =
        [NSURLComponents componentsWithURL:self.rootURL resolvingAgainstBaseURL:NO];

    components.path = path;
    components.queryItems = components.queryItems ? components.queryItems : @[];
    components.queryItems = [components.queryItems arrayByAddingObjectsFromArray:self.queryItems];

    NSLog(@"%@", [[components URL] absoluteString]);

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[components URL]
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:10.0];

    [request setHTTPMethod:@"PUT"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:self.body options:0 error:nil];

    __weak CDTPutDocumentOperation *weakSelf = self;
    NSURLSessionDataTask *task = [self.session
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable res,
                              NSError *_Nullable error) {
            CDTPutDocumentOperation *self = weakSelf;

            if (error) {
                if (self && self.putDocumentCompletionBlock) {
                    self.putDocumentCompletionBlock(0, nil, nil, error);
                }
            } else {
                NSInteger statusCode = ((NSHTTPURLResponse *)res).statusCode;
                if (statusCode == 201 || statusCode == 202) {
                    // Success
                    NSDictionary *result =
                        (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data
                                                                        options:0
                                                                          error:nil];
                    if (self && self.putDocumentCompletionBlock) {
                        self.putDocumentCompletionBlock(statusCode, result[@"doc"], result[@"rev"],
                                                        nil);
                    }
                } else {
                    NSString *json =
                        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSString *msg =
                        [NSString stringWithFormat:@"Database creation failed with %ld %@.",
                                                   statusCode, json];
                    NSDictionary *userInfo =
                        @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
                    NSError *error =
                        [NSError errorWithDomain:CDTObjectiveCloudantErrorDomain
                                            code:CDTObjectiveCloudantErrorCreateDatabaseFailed
                                        userInfo:userInfo];

                    if (self && self.putDocumentCompletionBlock) {
                        self.putDocumentCompletionBlock(statusCode, nil, nil, error);
                    }
                }
            }

            [self completeOperation];
          }];
    [task resume];
}
@end
