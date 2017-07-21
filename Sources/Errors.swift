//
//  Errors.swift
//  MATRIX Auth SDK
//
//  MIT License
//
//  Copyright (c) 2017 MATRIX Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import struct JWT.ClaimSet

/// A user authentication error.
public enum UserAuthError: Error {
    case decode(DecodeError)
    case response(ResponseError)
}

/// An error in decoding data from a user access token.
public enum DecodeError: Error {
    /// An error thrown by `JWT.decode`.
    case jwt(Error)
    /// Failed to retrieve user ID and expiration from claim set.
    case retrieval(ClaimSet)
}

/// An error that may occur when dealing with API responses.
public enum ResponseError: Error {
    /// AdMobilize API error.
    case api(String)
    /// Failed to retrieve values from response.
    case retrieval(Any)
    /// Provided error on response failure.
    case provided(Error)
}
