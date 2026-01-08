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
    @State private var showRegister = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Fundo
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer().frame(height: 40)

                // Ícone do app
                Image("app_icon_ui")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                Text("Bem-vindo ao Cabe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // MARK: - Email / Senha
                VStack(spacing: 12) {

                    TextField("E-mail", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                        .onChange(of: auth.email) { _ in
                            auth.errorMessage = nil
                            auth.infoMessage = nil
                        }

                    SecureField("Senha", text: $auth.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                        .onChange(of: auth.password) {_ in
                            auth.errorMessage = nil
                            auth.infoMessage = nil
                        }

                    // Recuperar senha
                    Button {
                        Task { await auth.sendPasswordReset() }
                    } label: {
                        Text("Esqueceu a senha?")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom)

                    // Erro
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    // Info
                    if let info = auth.infoMessage {
                        Text(info)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    // Botão Entrar
                    Button {
                        Task { await auth.signInWithEmail() }
                    } label: {
                        Text("Iniciar sessão")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(22)
                    }
                }

                Divider()

                // Criar conta
                Button {
                    showRegister = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.footnote)
                        Text("Criar conta com e-mail")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }

                // MARK: - Apple Sign In (oficial)
                SignInWithAppleButton(
                    .signIn,
                    onRequest: auth.prepareAppleRequest,
                    onCompletion: { result in
                        if case .success(let authorization) = result {
                            Task { await auth.handleAppleResult(authorization) }
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(22)
                              

                // MARK: - Google Sign In
                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 14, height: 14)

                        Text("Continuar com o Google")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .fullScreenCover(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(auth)
            }
        }
    }
}
