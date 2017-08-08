//
//  MatrixAuthSDK.swift
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

import Foundation
import Alamofire
import JWT

import struct Result.AnyError
import enum Result.Result

/// Handles MATRIX API authorization.
///
/// Callbacks are called asynchronously and take a `Result<T, E>`. As a result,
/// errors must be handled and can't be ignored.
///
/// ```
/// let auth = try MatrixAuth(clientId: ..., clientSecret: ...)
///
/// auth.authenticate(username: "your@email.com", password: "1234") { result in
///     switch result {
///     case let .success(user):
///         // Do stuff with user
///         ...
///
///         user.details { result in
///             switch result {
///             case let .success(details):
///                 print(details)
///             case let .failure(error):
///                 ...
///             }
///         }
///
///         user.deviceSecret(for: "MyDeviceId") { result in
///             switch result {
///             case let .success(secret):
///                 print(secret)
///             case let .failure(error):
///                 ...
///             }
///         }
///     case let .failure(error):
///         // Authentication failure; handle error
///         ...
///     }
/// }
/// ```
public final class MatrixAuth {

    /// An error thrown by `MatrixAuth`.
    public enum Error: Swift.Error {

        /// The provided URL is invalid (e.g. empty).
        case invalidBaseURL

        /// The provided client ID is invalid (e.g. empty).
        case invalidClientID

        /// The provided client secret is invalid (e.g. empty).
        case invalidClientSecret

    }

    internal var _baseURL: String

    internal var _clientId: String

    internal var _clientSecret: String

    /// Creates an instance for a given environment, client ID, and client secret.
    ///
    /// - throws: `MatrixAuth.Error` if the ID or secret are invalid (e.g. empty).
    public convenience init(env: Environment = .prod, clientId: String, clientSecret: String) throws {
        try self.init(baseURL: env.apiURL.absoluteString, clientId: clientId, clientSecret: clientSecret)
    }

    /// Creates an instance with a base URL, client ID, and client secret.
    ///
    /// - throws: `MatrixAuth.Error` if any parameter is invalid (e.g. empty)
    public init(baseURL: String, clientId: String, clientSecret: String) throws {
        guard !baseURL.isEmpty else {
            throw Error.invalidBaseURL
        }
        guard !clientId.isEmpty else {
            throw Error.invalidClientID
        }
        guard !clientSecret.isEmpty else {
            throw Error.invalidClientSecret
        }
        _baseURL = baseURL
        _clientId = clientId
        _clientSecret = clientSecret
    }

    /// Authenticates `username` with `password` and sets the corresponding values within `self`.
    public func authenticate(username: String, password: String, completionHandler: @escaping (Result<UserAuth, UserAuthError>) -> ()) {
        let url = _baseURL + "/v1/oauth2/user/token"
        let parameters: [String: Any] = [
            "client_id": _clientId,
            "client_secret": _clientSecret,
            "grant_type": "password",
            "jwt_token": true,
            "refresh_token": true,
            "username": username,
            "password": password
        ]

        request(url, method: .post, parameters: parameters).responseJSON { response in
            let result: Result<UserAuth, UserAuthError>

            switch _results(of: response) {
            case let .success(results):
                guard let accessToken = results["access_token"] as? String,
                    let refreshToken = results["refresh_token"] as? String
                else {
                    result = .failure(.response(.retrieval(results)))
                    break
                }

                switch _decode(accessToken: accessToken) {
                case let .success((id, exp)):
                    result = .success(UserAuth(matrixAuth: self,
                                               id: id,
                                               refreshToken: refreshToken,
                                               accessToken: accessToken,
                                               expiration: exp))
                case let .failure(error):
                    result = .failure(.decode(error))
                }
            case let .failure(error):
                result = .failure(.response(error))
            }

            completionHandler(result)
        }
    }

    /// Registers a new user with a `username`, `password`, and `role`.
    public func registerNewUser(username: String,
                                password: String,
                                role: String,
                                completionHandler: @escaping (Result<[String: Any], ResponseError>) -> ()) {
        let url = _baseURL + "/v1/oauth2/user/register"
        let parameters: [String: Any] = [
            "username": username,
            "password": password,
            "role": role,
            "active": true,
            "client_id": _clientId
        ]
        request(url, method: .post, parameters: parameters).responseJSON { response in
            completionHandler(_results(of: response))
        }
    }

    /// Sends a request to restore the password for `username`.
    public func forgotPassword(username: String, completionHandler: @escaping (Result<[String: Any], ResponseError>) -> ()) {
        let url = _baseURL + "/v1/user/request/restore_password"
        let parameters = [
            "user_email": username
        ]
        request(url, method: .post, parameters: parameters).responseJSON { response in
            completionHandler(_results(of: response))
        }
    }

}
