//
//  AppleSignInService.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//


import AuthenticationServices
import FirebaseAuth

final class AppleSignInService {

    private var currentNonce: String?

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signIn(
        authorization: ASAuthorization
    ) async throws -> AuthCredential {

        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleIDCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.generic("Credenciais Apple inválidas")
        }

        return OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
    }
}
