//
//  HTTPStatus.swift
//  
//
//  Created by ChargeON on 2024/11/1.
//

import Foundation
public enum HTTPStatus: String {
    case ok = "200 OK"
    case badRequest = "400 Bad Request"
    case notFound = "404 Not Found"
    case methodNotAllowed = "405 Method Not Allowed"
    case internalServerError = "500 Internal Server Error"

    var statusCode: Int {
        return Int(rawValue.split(separator: " ")[0]) ?? 0
    }

    var statusDescription: String {
        return rawValue.split(separator: " ").dropFirst().joined(separator: " ")
    }
}
