# 0.2.2 (2016-09-16)

- [DEPRECATED] Deprecated in favour of [SwiftCloudant](https://github.com/cloudant/swift-cloudant).

# 0.2.2 (2015-11-24)

- [FIX] Fixed issue where `selector` wasn't put into the POST body for text index
  creation
- [FIX] Fixed issue where `fields` wasn't nested in the `index` field for text
   index creation.

# 0.2.1 (2015-11-13)

- [FIX] Fixed issue where the document id would be null
  when calling `putDocumentCompletionBlock`
- [FIX] Fixed issue where the status code passed to `putDocumentCompletionBlock`
  would always be equal to `kCDTNoHTTPStatusCode` even when a HTTP request was
  made successfully made to the server.

# 0.2 (2015-11-9)

Initial Release
