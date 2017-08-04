//
//  MatrixAuthTests.swift
//  MatrixAuthTests
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

import XCTest
import MatrixAuthSDK

enum InfoKey: String {

    case devUsername      = "DEV_USERNAME"
    case devPassword      = "DEV_PASSWORD"

    case devClientId      = "DEV_CLIENT_ID"
    case devClientSecret  = "DEV_CLIENT_SECRET"

    case prodClientId     = "PROD_CLIENT_ID"
    case prodClientSecret = "PROD_CLIENT_SECRET"

}

extension Bundle {
    static let current = Bundle(for: MatrixAuthTests.self)

    func infoString(for key: InfoKey) -> String? {
        return infoDictionary?[key.rawValue] as? String
    }
}

extension MatrixAuth {
    convenience init(env: Environment) throws {
        let bundle = Bundle.current
        let clientId, clientSecret: String

        switch env {
        case .dev:
            clientId = bundle.infoString(for: .devClientId) ?? ""
            clientSecret = bundle.infoString(for: .devClientSecret) ?? ""
        case .prod:
            clientId = bundle.infoString(for: .prodClientId) ?? ""
            clientSecret = bundle.infoString(for: .prodClientSecret) ?? ""
        case .rc:
            clientId = ""
            clientSecret = ""
        }

        try self.init(env: env, clientId: clientId, clientSecret: clientSecret)
    }
}

extension Environment {

    var credentials: (username: String, password: String)? {
        let bundle = Bundle.current
        guard case .dev = self,
            let username = bundle.infoString(for: .devUsername),
            let password = bundle.infoString(for: .devPassword)
        else {
            return nil
        }
        return (username, password)
    }

}

class MatrixAuthTests: XCTestCase {

    func testLogin() throws {
        let envs: [Environment] = [.dev, /* .prod */]

        for env in envs {
            let auth = try MatrixAuth(env: env)
            let exp = expectation(description: "handler")

            guard let (username, password) = env.credentials else {
                continue
            }

            auth.authenticate(username: username, password: password) { result in
                guard let value = result.value else {
                    return
                }
                for child in Mirror(reflecting: value).children {
                    print(child)
                }
                exp.fulfill()
            }

            waitForExpectations(timeout: 5)
        }
    }

    func testUserDetails() throws {
        let env = Environment.dev
        let exp = expectation(description: "handler")

        guard let (username, password) = env.credentials else {
            XCTFail("Failed to get credentials for \(env)")
            return
        }

        try MatrixAuth(env: .dev).authenticate(username: username, password: password) { result in
            guard case let .success(user) = result else {
                return
            }
            user.details { result in
                print(result)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testDeviceSecret() throws {
        let deviceId = "1234"
        let env = Environment.dev
        let exp = expectation(description: "secret")

        guard let (username, password) = env.credentials else {
            XCTFail("Failed to get credentials for \(env)")
            return
        }

        try MatrixAuth(env: .dev).authenticate(username: username, password: password) { result in
            guard case let .success(user) = result else {
                return
            }
            user.deviceSecret(for: deviceId) { result in
                print(result)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

}
