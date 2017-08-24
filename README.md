# MATRIX Swift Auth SDK

[![Build Status](https://travis-ci.org/matrix-io/matrix-auth-swift-sdk.svg?branch=master)](https://travis-ci.org/matrix-io/matrix-auth-swift-sdk)

MATRIX Authentication framework for Swift

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
