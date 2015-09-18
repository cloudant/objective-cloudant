//
//  CDTCouchOperation.m
//  ObjectiveCouch
//
//  Created by Michael Rhodes on 27/08/2015.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTCouchOperation.h"

NSString *const CDTObjectiveCloudantErrorDomain = @"CDTObjectiveCloudantErrorDomain";

@implementation CDTCouchOperation

#pragma mark Sub-class overrides

- (BOOL)buildAndValidate { return YES; }

- (void)dispatchAsyncHttpRequest { return; }

#pragma mark Concurrent operation NSOperation functions

- (id)init
{
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent { return YES; }

- (BOOL)isExecuting { return executing; }

- (BOOL)isFinished { return finished; }

- (void)start
{
    // Always check for cancellation before launching the task.
    if ([self isCancelled]) {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }


    
    if([self buildAndValidate]){
        // If the operation is not canceled and is valid, begin executing the task.
        [self willChangeValueForKey:@"isExecuting"];
        [self dispatchAsyncHttpRequest];
        executing = YES;
        [self didChangeValueForKey:@"isExecuting"];
    } else {
        //throw an expcetion because this should be a coding error?
        @throw [[NSException alloc]initWithName:@"Invalid Operation" reason:@"Operation was configured incorrectly" userInfo:@{}];
    }
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    executing = NO;
    finished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
