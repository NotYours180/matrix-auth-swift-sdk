//
//  Helpers.swift
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

import JWT
import Result

import struct Alamofire.DataResponse

internal func _results(of response: DataResponse<Any>) -> Result<[String: Any], ResponseError> {
    switch response.result {
    case let .success(value):
        if let json = value as? [String: Any] {
            if json["status"] as? String == "OK", let results = json["results"] as? [String: Any] {
                return .success(results)
            } else if let message = json["error"] as? String {
                return .failure(.api(message))
            }
        }
        return .failure(.retrieval(value))
    case let .failure(error):
        return .failure(.provided(error))
    }
}

internal func _decode(accessToken: String) -> Result<(id: String, exp: TimeInterval), DecodeError> {
    do {
        let cs: ClaimSet = try JWT.decode(accessToken, algorithm: .hs256(Data()), verify: false)
        guard let id = cs["uid"] as? String, let exp = cs["exp"] as? TimeInterval else {
            return .failure(.retrieval(cs))
        }
        let value = (id, exp)
        return .success(value)
    } catch {
        return .failure(.jwt(error))
    }
}
