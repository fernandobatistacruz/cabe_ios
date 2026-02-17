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
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    
                    Spacer().frame(height: 30)
                   
                    Image("app_icon_ui")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    Text("Bem-vindo ao Cabe")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.vertical, 10)
                  
                    VStack(spacing: 12) {
                        
                        TextField("E-mail", text: $auth.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .foregroundColor(.primary)
                            .onChange(of: auth.email) { _ in
                                auth.errorMessage = nil
                                auth.infoMessage = nil
                            }
                        
                        SecureField("Senha", text: $auth.password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .foregroundColor(.primary)
                            .onChange(of: auth.password) {_ in
                                auth.errorMessage = nil
                                auth.infoMessage = nil
                            }
                       
                        Button {
                            Task { await auth.sendPasswordReset() }
                        } label: {
                            Text("Esqueceu a Senha?")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.bottom)
                      
                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                        }
                                              
                        if let info = auth.infoMessage {
                            Text(info)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                        }
                       
                        Button {
                            Task { await auth.signInWithEmail() }
                        } label: {
                            Text("Iniciar Sessão")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(22)
                        }
                    }
                    
                    Divider()
                  
                    Button {
                        showRegister = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.footnote)
                            Text("Criar conta com E-mail")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.black)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: auth.prepareAppleRequest,
                        onCompletion: { result in
                            if case .success(let authorization) = result {
                                Task { await auth.handleAppleResult(authorization) }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(22)
                   
                    Button {
                        Task { await auth.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image("google_logo")
                                .resizable()
                                .frame(width: 14, height: 14)
                            
                            Text("Iniciar sessão com o Google")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.black)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(auth)
        }
    }
}
