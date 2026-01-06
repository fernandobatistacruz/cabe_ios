//
//  GoogleSignInService.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//


import GoogleSignIn
import FirebaseAuth
import UIKit
import FirebaseCore

final class GoogleSignInService {

    func signIn() async throws -> AuthCredential {
        guard
            let clientID = FirebaseApp.app()?.options.clientID,
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.windows.first?.rootViewController
        else {
            throw AuthError.generic("Erro ao iniciar Google Sign-In")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.generic("Token Google inválido")
        }

        let accessToken = result.user.accessToken.tokenString

        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

    }
}
