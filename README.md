# MATRIX Swift Auth SDK

MATRIX Authentication framework for Swift

[![Build Status](https://travis-ci.org/matrix-io/matrix-auth-swift-sdk.svg?branch=master)](https://travis-ci.org/matrix-io/matrix-auth-swift-sdk)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/MatrixAuthSDK.svg)](https://img.shields.io/cocoapods/v/MatrixAuthSDK.svg)
[![License](https://img.shields.io/cocoapods/l/ImagePicker.svg?style=flat)](http://cocoadocs.org/docsets/ImagePicker)
[![Platform](https://img.shields.io/cocoapods/p/ImagePicker.svg?style=flat)](http://cocoadocs.org/docsets/ImagePicker)
![Swift](https://img.shields.io/badge/%20in-swift%203.0-orange.svg)
## Requirements

- iOS 8.0+
- Xcode 8.1, 8.2, 8.3
- Swift 3.0, 3.1, 3.2

## Installation

### CocoaPods

To integrate MATRIX Auth SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
    pod 'MatrixAuthSDK'
```

Then, run the following command:

```bash
$ pod install
```

## Usage

The starting point is `MatrixAuth`. With it you can:
- Authenticate an existing user and work with it via `UserAuth`
- Create a new user with given credentials and a role
- Request a password reset for a user, which they can then do via email

### User Authentication

```swift
let auth = try MatrixAuth(clientId: ..., clientSecret: ...)
let username = "your@email.com"
let password = ...

auth.authenticate(username: username, password: password) { result in
    switch result {
    case let .success(user):
        // Do stuff with user
        ...
    case let .failure(error):
        // Authentication failure; handle error
        ...
    }
}
```

### User Details

```swift
let user: UserAuth = ...

user.details { result in
    switch result {
    case let .success(details):
        // Prints the details of the user as returned by the AdMobilize API
        print(details)
    case let .failure(error):
        // Handle error
        ...
    }
}
```

### User Device Secret

```swift
let user: UserAuth = ...
let device: String = ...

user.deviceSecret(for: device) { result in
    switch result {
    case let .success(secret):
        // Prints the secret for `device` belonging to `user`
        print(secret)
    case let .failure(error):
        // Handle error
        ...
    }
}
```

### User Registration

```swift
let auth: MatrixAuth = ...

auth.registerNewUser(username: ..., password: ..., role: ...) { result in
    switch result {
    case let .success(value):
        // Do stuff with API response
        ...
    case let .failure(error):
        // Handle error
        ...
    }
}
```

### User Password Reset

After this, an email will be sent to the user asking them to reset their
password.

```swift
let auth: MatrixAuth = ...

auth.forgotPassword(username: ...) { result in
    switch result {
    case let .success(value):
        // Do stuff with API response
        ...
    case let .failure(error):
        // Handle error
        ...
    }
}
```

## License

This project is released under the [MIT License](LICENSE.md).
