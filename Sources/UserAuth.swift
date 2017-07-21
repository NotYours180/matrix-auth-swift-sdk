//
//  UserAuth.swift
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

import Alamofire
import JWT

import struct Result.AnyError
import enum Result.Result

/// User authentication delegate.
public protocol UserAuthDelegate: class {

    /// Returns whether the `UserAuth` instance should refresh its access token.
    func userAuthShouldRefreshAccessToken(_ userAuth: UserAuth) -> Bool

    /// The `UserAuth` instance did refresh its access token.
    func userAuthDidRefreshAccessToken(_ userAuth: UserAuth, result: Result<(), UserAuthError>)

}

/// User authentication result from MATRIX API.
public final class UserAuth {

    /// The MATRIX auth which `self` came from.
    public let matrixAuth: MatrixAuth

    /// The user ID.
    public let id: String

    /// The user refresh token.
    public let refreshToken: String

    /// The user access token.
    public private(set) var accessToken: String

    /// The delegate.
    public weak var delegate: UserAuthDelegate?

    /// Timer that goes off when `accessToken` expires.
    private var _refreshTimer: Timer!

    /// Creates an instance.
    ///
    /// - warning: Should only be called from `MatrixAuth` with valid values.
    internal init(matrixAuth: MatrixAuth, id: String, refreshToken: String, accessToken: String, expiration: TimeInterval) {
        self.matrixAuth = matrixAuth
        self.id = id
        self.refreshToken = refreshToken
        self.accessToken = accessToken

        let seconds = Date(timeIntervalSince1970: expiration).timeIntervalSinceNow

        _refreshTimer = Timer(timeInterval: seconds,
                              target: self,
                              selector: #selector(_refreshAccessToken),
                              userInfo: nil,
                              repeats: false)
    }

    @objc private func _refreshAccessToken() { refreshAccessToken() }

    /// Refresh the access token for `self`.
    public func refreshAccessToken() {
        guard delegate?.userAuthShouldRefreshAccessToken(self) ?? true else {
            return
        }

        let url = matrixAuth._baseURL + "/v1/oauth2/user/refresh_token"

        let parameters: [String: Any] = [
            "client_id": matrixAuth._clientId,
            "client_secret": matrixAuth._clientSecret,
            "grant_type": "refresh_token",
            "jwt_token": true,
            "refresh_token": refreshToken
        ]
        request(url, method: .post, parameters: parameters).responseJSON { response in
            let result: Result<(), UserAuthError>

            switch _results(of: response) {
            case let .success(results):
                guard let token = results["access_token"] as? String else {
                    result = .failure(.response(.retrieval(results)))
                    break
                }
                self.accessToken = token

                switch _decode(accessToken: token) {
                case let .success((_, exp)):
                    let seconds = Date(timeIntervalSince1970: exp).timeIntervalSinceNow
                    self._refreshTimer = Timer(timeInterval: seconds,
                                               target: self,
                                               selector: #selector(self._refreshAccessToken),
                                               userInfo: nil,
                                               repeats: false)
                    result = .success()
                case let .failure(error):
                    result = .failure(.decode(error))
                }
            case let .failure(error):
                result = .failure(.response(error))
            }

            self.delegate?.userAuthDidRefreshAccessToken(self, result: result)
        }
    }

    /// Get the device secret for `deviceId` and handle the result.
    public func deviceSecret(for deviceId: String, completionHandler: @escaping (Result<String, UserAuthError>) -> ()) {
        let url = matrixAuth._baseURL + "/v2/device/secret"
        let parameters = [
            "device_id": deviceId,
            "access_token": accessToken
        ]

        request(url, method: .get, parameters: parameters).responseJSON { response in
            let result: Result<String, UserAuthError>

            switch _results(of: response) {
            case let .success(results):
                guard let secret = results["deviceSecret"] as? String else {
                    result = .failure(.response(.retrieval(results)))
                    break
                }
                result = .success(secret)
            case let .failure(error):
                result = .failure(.response(error))
            }

            completionHandler(result)
        }
    }

    /// Gets the user details.
    public func details(completionHandler: @escaping (Result<[String: Any], ResponseError>) -> ()) {
        let url = matrixAuth._baseURL + "/admin/user/details"
        let parameters = [
            "user_id": id,
            "access_token": accessToken
        ]

        request(url, method: .get, parameters: parameters).responseJSON { response in
            completionHandler(_results(of: response))
        }
    }

}
