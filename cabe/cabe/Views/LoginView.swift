//
//  LoginView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//

import SwiftUI
import _AuthenticationServices_SwiftUI

struct LoginView: View {

    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {

            SignInWithAppleButton(
                .signIn,
                onRequest: auth.prepareAppleRequest,
                onCompletion: { result in
                    if case .success(let authorization) = result {
                        Task {
                            await auth.handleAppleResult(authorization)
                        }
                    }
                }
            )
            .frame(height: 44)

            Button {
                Task {
                    await auth.signInWithGoogle()
                }
            } label: {
                HStack {
                    Image("google_logo") // imagem do ícone do Google adicionada ao Assets
                        .resizable()
                        .frame(width: 20, height: 20)

                    Text("Sign in with Google")
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
    }
}
