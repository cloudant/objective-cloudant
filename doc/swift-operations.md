# Writing custom operations in Swift

The ObjectiveCloudant library does not implement the complete CouchDB HTTP API yet. If you need to access API calls currently not implemented, you can do so by implementing your own operations. In order to do so, you need to subclass either `CDTCouchOperation` or `CDTCouchDatabaseOperation`. The only difference between those two classes is that the latter has property access to the database name, so is the one to choose if your operation needs to know the database name.

## Implementing the _changes operation

Let's implement a custom operation in Swift: the [`_changes`](http://docs.couchdb.org/en/1.6.1/api/database/changes.html#get--db-_changes) end point. It's a `GET` to `{DATABASE}/_changes` that can take a number of different parameters. For our purposes we will implement support for a single parameter only, `include_docs`, to demonstrate the pattern which should be the same for all other parameters.

As we need access to the database name, we need to subclass `CDTCouchDatabaseOperation`. Let's create a class for our new operation. I've called it `SKChangeOperation`.


```swift
//
//  SKChangeOperation.swift
//
//  Created by Stefan Kruger on 01/03/2016.
//  Copyright © 2016 Stefan Kruger. All rights reserved.

import Foundation
import ObjectiveCloudant

enum Err: ErrorType {
    case ChangesError
}

class SKChangeOperation: CDTCouchDatabaseOperation {
 	// TODO: properties for query parameters and callbacks

    override func buildAndValidate() -> Bool {
        return true
    }
    
    override func httpMethod() -> String {
        return "GET"
    }
    
    override func httpPath() -> String {
        return "/\(self.databaseName!)/_changes"
    }
    
    override func queryItems() -> [NSURLQueryItem] {
 		// TODO
    }
    
    override func callCompletionHandlerWithError(error: NSError) {
        self.completionHandler?([:], error)
    }
    
    override func processResponseWithData(responseData: NSData?, statusCode: Int, error: NSError?) {
 		// TODO
    }
}
```

There are six methods we need to override:

1. `buildAndValidate()` 

	Do any necessary validation of set query parameters and return true if valid. 

2. `httpMethod()`

	Return the HTTP verb that this operation uses. In our case, `GET`.

3. `httpPath()` 

	Return the URL path to the end point we're implementing, in our case `/{DATABASE}/_changes`

4. `queryItems()`

	Package and return the query items as an array of `NSURLQueryItem`.

5. `callCompletionHandlerWithError(error: NSError)`

	Call any defined completion handler with an error.

6. `processResponseWithData(responseData: NSData?, statusCode: Int, error: NSError?)`

	Unpack the response data, and if no errors, call any defined callbacks that user of our operation may have set with the data.

Additionally we need to create properties for each query parameter we intend to support, and one for the callback. 

Our optional completion handler will be called with a dictionary representing the unpacked JSON payload from the response, and an optional error, and return nothing:

```swift
var completionHandler: (([String:AnyObject], NSError?) -> ())?
```

and our single query parameter is an optional boolean:

```
var includeDocs: Bool?
```

## `queryItems()`

In our case, this is straight-forward as we have only a single parameter to deal with:

```swift
override func queryItems() -> [NSURLQueryItem] {
    var items: [NSURLQueryItem] = []
    
    if let includeDocs = includeDocs {
        items.append(NSURLQueryItem(name: "include_docs", value: "\(includeDocs)"))
    }
    
    return items
}
```

Note that we need to explicitly type the `items` array as Swift would otherwise infer a `NSArray` type which is not what we want in this case. `NSURLQueryItem` can be seen as a tuple mapping a name string to a value string. We can rely on Swift's excellent string interpolation to convert the bool to a string.

## `processResponseWithData(...)`

```swift
override func processResponseWithData(responseData: NSData?, statusCode: Int, error: NSError?) {
    if let error = error {
        callCompletionHandlerWithError(error)
        return
    }
    
    // check status code, 2XX good else error
    if statusCode / 100 == 2 {
        guard let responseData = responseData
            else {
                return
            }
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(responseData,
            	options: NSJSONReadingOptions())
            completionHandler?(json as! [String:AnyObject], nil)
        } catch {
        	// Bad JSON.
            callCompletionHandlerWithError(error as NSError)
        }
    } else {
    	// Non-2XX status. Report back the error. For simplicity: hard-coded.
        callCompletionHandlerWithError(Err.ChangesError as NSError)
    }
}
```

We first check the error, and bail early if we don't even got a response. The next step is to look at the HTTP status code. If the status code is in the 200 range, we attempt to unpack the data, and if that is successful, we call any defined callback with the unpacked data. If anything went wrong, we call the callback with the error. Note that the last error statement should really do a better job in terms of reporting back the error.

Here's the complete class:

```swift
//
//  SKChangeOperation.swift
//
//  Created by Stefan Kruger on 01/03/2016.
//  Copyright © 2016 Stefan Kruger. All rights reserved.
//

import Foundation
import ObjectiveCloudant

enum Err: ErrorType {
    case ChangesError
}

class SKChangeOperation: CDTCouchDatabaseOperation {
    var completionHandler: (([String:AnyObject], NSError?) -> ())?
    var includeDocs: Bool?
    
    override func buildAndValidate() -> Bool {
        return true
    }
    
    override func httpMethod() -> String {
        return "GET"
    }
    
    override func httpPath() -> String {
        return "/\(self.databaseName!)/_changes"
    }
    
    override func queryItems() -> [NSURLQueryItem] {
        var items: [NSURLQueryItem] = []
        
        if let includeDocs = includeDocs {
            items.append(NSURLQueryItem(name: "include_docs", value: "\(includeDocs)"))
        }
        
        return items
    }
    
    override func callCompletionHandlerWithError(error: NSError) {
        self.completionHandler?([:], error)
    }
    
    override func processResponseWithData(responseData: NSData?, statusCode: Int, error: NSError?) {
        if let error = error {
            callCompletionHandlerWithError(error)
            return
        }
        
        // check status code, 2XX good else error
        if statusCode / 100 == 2 {
            guard let responseData = responseData
                else {
                    return
                }
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions())
                completionHandler?(json as! [String:AnyObject], nil)
            } catch {
                // Bad JSON
                callCompletionHandlerWithError(error as NSError)
            }
        } else {
            // Non-2XX status. Report back the error. For simplicity: hard-coded.
            callCompletionHandlerWithError(Err.ChangesError as NSError)
        }
    }
}
```

Here's an example how to use the operation we just created:

```swift
let username = ...
let password = ...
let account = ...
let database = ...

let client = CDTCouchDBClient(forURL: NSURL(string: "https://\(account).cloudant.com")!, username: username, password: password)!

if let db = client[database] {
    let changes = SKChangeOperation()
    changes.completionHandler = { (data, error) in
        print(data)
    }
    changes.includeDocs = true
    
    db.addOperation(changes)
}
```

You should see the changes data for your database dumped to the console.
