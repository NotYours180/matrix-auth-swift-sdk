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

/// Handles MATRIX API authorization.
public final class MatrixAuth {

    /// An error thrown by `MatrixAuth`.
    public enum Error: Swift.Error {

        /// The provided URL is invalid (e.g. empty).
        case invalidBaseURL

        /// The provided client ID is invalid (e.g. empty).
        case invalidClientID

        /// The provided client secret is invalid (e.g. empty).
        case invalidClientSecret

        /// Failed to get a user ID or expiration from a JWT.
        case decodeFailure

        /// Failed to get user access token.
        case unauthenticated

    }

    /// A completion handler that takes a success boolean and result dictionary.
    public typealias CompletionHandler = (Bool, [String: AnyObject]) -> ()

    private var _baseURL: String

    private var _clientID: String

    private var _clientSecret: String

    private var _refreshToken: Timer?

    private var _accessTokenToRefresh: String?

    /// The current user ID.
    public var userID: String?

    /// The user access token for the current authorized user. Fails silently if the token could not be decoded.
    public var userAccessToken: String? {
        didSet {
            if let token = userAccessToken, !token.isEmpty {
                try? decodeJWT(token: token)
            }
        }
    }

    /// Creates an instance for a given environment, client ID, and client secret.
    ///
    /// - throws: `MatrixAuth.Error` if the ID or secret are invalid (e.g. empty).
    public convenience init(env: Environment, clientID: String, clientSecret: String) throws {
        try self.init(baseURL: env.apiURL.absoluteString, clientID: clientID, clientSecret: clientSecret)
    }

    /// Creates an instance with a base URL, client ID, and client secret.
    ///
    /// - throws: `MatrixAuth.Error` if any parameter is invalid (e.g. empty)
    public init(baseURL: String, clientID: String, clientSecret: String) throws {
        guard !baseURL.isEmpty else {
            throw Error.invalidBaseURL
        }
        guard !clientID.isEmpty else {
            throw Error.invalidClientID
        }
        guard !clientSecret.isEmpty else {
            throw Error.invalidClientSecret
        }
        _baseURL = baseURL
        _clientID = clientID
        _clientSecret = clientSecret
    }

    /// Decodes the JSON web token, obtaining a user ID and refresh token.
    ///
    /// - throws: `Error.decodeFailure` if the user ID or expiration could not be retrieved.
    private func decodeJWT(token: String) throws {
        if let rt = _refreshToken {
            rt.invalidate()
            _refreshToken = nil
        }

        let cs: ClaimSet = try decode(token, algorithm: .hs256(Data()), verify: false, audience: nil, issuer: nil)

        guard let uid = cs["uid"] as? String, let exp = cs["exp"] as? Double else {
            throw Error.decodeFailure
        }

        userID = uid
        let date = Date(timeIntervalSince1970: exp)
        let seconds = date.timeIntervalSinceNow

        _refreshToken = Timer(timeInterval: seconds,
                              target: self,
                              selector: #selector(self.refreshUserAccessToken),
                              userInfo: nil,
                              repeats: false)
    }

    private func genericRequestResponse(response: Any?, statusCode: Int?, error: Swift.Error?, completionHandler: @escaping CompletionHandler) {
        var requestSuccess = false
        let result: [String: AnyObject]

        if let error = error {
            result = ["message": error.localizedDescription as AnyObject]
        } else if let json = response as? [String: AnyObject] {
            if json["status"] as? String == "OK", let results = json["results"] {
                if results is [AnyObject] {
                    result = ["results": results]
                } else if results is String {
                    result = ["message": results]
                } else {
                    result = results as! [String: AnyObject]
                }
                requestSuccess = true
            } else if let errorMessage = json["error"] {
                result = ["message": errorMessage]
            } else {
                result = ["message": "Unknown error" as AnyObject]
            }
        } else if let statusCode = statusCode {
            result = ["status code": "\(statusCode)" as AnyObject]
        } else {
            result = ["message": "Unknown error" as AnyObject]
        }

        DispatchQueue.main.async {
            completionHandler(requestSuccess, result)
        }
    }

    @objc private func refreshUserAccessToken() {
        let url = _baseURL + "/v1/oauth2/user/refresh_token"
        let parameters: [String: Any] = [
            "client_id": _clientID,
            "client_secret": _clientSecret,
            "grant_type": "refresh_token",
            "jwt_token": true,
            "refresh_token": _accessTokenToRefresh as Any
        ]
        request(url, method: .post, parameters: parameters).responseJSON { [weak self] response in
            guard let `self` = self else {
                return
            }
            self.genericRequestResponse(response: response.result.value,
                                         statusCode: response.response?.statusCode,
                                         error: response.result.error) { success, result in
                if success, let token = result["access_token"] as? String {
                    self.userAccessToken = token
                }
            }
        }
    }

    /// Authenticates `username` with `password` and sets the corresponding values within `self`.
    public func authenticate(username: String, password: String, completionHandler: @escaping CompletionHandler) {
        let url = _baseURL + "/v1/oauth2/user/token"
        let parameters: [String: Any] = [
            "client_id": _clientID,
            "client_secret": _clientSecret,
            "grant_type": "password",
            "jwt_token": true,
            "refresh_token": true,
            "username": username,
            "password": password
        ]
        request(url, method: .post, parameters: parameters).responseJSON { [weak self] response in
            guard let `self` = self else {
                return
            }
            let val = response.result.value
            let err = response.result.error
            let stat = response.response?.statusCode
            self.genericRequestResponse(response: val, statusCode: stat, error: err) { success, result in
                if let token = result["access_token"] as? String {
                    self.userAccessToken = token
                }
                if let token = result["refresh_token"] as? String {
                    self._accessTokenToRefresh = token
                }
                completionHandler(success, result)
            }
        }
    }

    /// Logs the current user out, invalidating the user access token.
    public func logout() {
        userAccessToken = nil
        _accessTokenToRefresh = nil
        userID = nil
        if let rt = _refreshToken {
            rt.invalidate()
        }
    }

    /// Registers a new user with a `username`, `password`, and `role`.
    public func registerNewUser(username: String, password: String, role: String, completionHandler: @escaping CompletionHandler) {
        let url = _baseURL + "/v1/oauth2/user/register"
        let parameters: [String: Any] = [
            "username": username,
            "password": password,
            "role": role,
            "active": true,
            "client_id": _clientID
        ]
        request(url, method: .post, parameters: parameters).responseJSON { [weak self] response in
            self?.genericRequestResponse(response: response.result.value,
                                         statusCode: response.response?.statusCode,
                                         error: response.result.error,
                                         completionHandler: completionHandler)
        }
    }

    /// Gets the secret for `deviceID`, handling the result in `completionHandler`.
    ///
    /// - throws: `Error.unauthenticated` if the user access token is invalid (e.g. `nil` or empty).
    public func getDeviceSecret(deviceID: String, completionHandler: @escaping CompletionHandler) throws {
        guard let uat = userAccessToken, !uat.isEmpty else {
            throw Error.unauthenticated
        }
        let url = _baseURL + "/v2/device/secret"
        let parameters = [
            "device_id": deviceID,
            "access_token": uat
        ]

        request(url, method: .get, parameters: parameters).responseJSON { [weak self] response in
            self?.genericRequestResponse(response: response.result.value,
                                         statusCode: response.response?.statusCode,
                                         error: response.result.error,
                                         completionHandler: completionHandler)
        }
    }

    /// Sends a request to restore the password for `username`.
    public func forgotPassword(username: String, completionHandler: @escaping CompletionHandler) {
        let url = _baseURL + "/v1/user/request/restore_password"
        let parameters = [
            "user_email": username
        ]

        request(url, method: .post, parameters: parameters).responseJSON { [weak self] response in
            self?.genericRequestResponse(response: response.result.value,
                                         statusCode: response.response?.statusCode,
                                         error: response.result.error,
                                         completionHandler: completionHandler)
        }
    }

    /// Gets the user details
    ///
    /// - throws: `Error.unauthenticated` if the user access token is invalid (e.g. `nil` or empty).
    public func getUserDetails(userID: String, completionHandler: @escaping CompletionHandler) throws {
        guard let uat = userAccessToken, !uat.isEmpty else {
            throw Error.unauthenticated
        }
        let url = _baseURL + "/admin/user/details"
        let parameters = [
            "user_id": userID,
            "access_token": uat
        ]

        request(url, method: .get, parameters: parameters).responseJSON { [weak self] response in
            self?.genericRequestResponse(response: response.result.value,
                                         statusCode: response.response?.statusCode,
                                         error: response.result.error,
                                         completionHandler: completionHandler)
        }
    }

}
