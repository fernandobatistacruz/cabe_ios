//
//  AuthError.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//

import Foundation

enum AuthError: LocalizedError {
    case credentialInUse
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .credentialInUse:
            return "Essa conta já existe. Faça login com o método original para vincular."
        case .generic(let message):
            return message
        }
    }
}

