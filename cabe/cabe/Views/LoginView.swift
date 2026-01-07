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
            // Fundo dinâmico
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                    
                    SecureField("Senha", text: $auth.password)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .foregroundColor(.primary)
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        Task { await auth.signInWithEmail() }
                    } label: {
                        Text("Entrar")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                // Criar nova conta
                Button {
                    showRegister = true
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .frame(width: 20, height: 16)
                        Text("Criar nova conta")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                // MARK: - Apple Sign In
                SignInWithAppleButton(
                    .signIn,
                    onRequest: auth.prepareAppleRequest,
                    onCompletion: { result in
                        if case .success(let authorization) = result {
                            Task { await auth.handleAppleResult(authorization) }
                        }
                    }
                )
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .white
                )
                .frame(height: 50)
                .cornerRadius(10)
                
                // MARK: - Google Sign In
                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Sign in with Google")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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


/*
import SwiftUI
import _AuthenticationServices_SwiftUI

struct LoginView: View {

    @EnvironmentObject var auth: AuthViewModel
    @State private var showRegister = false

    var body: some View {
        NavigationStack{
            VStack(spacing: 16) {
                // Email login
                VStack(spacing: 8) {
                    TextField("Email", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Senha", text: $auth.password)
                        .textFieldStyle(.roundedBorder)
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Entrar") {
                        Task { await auth.signInWithEmail() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Divider().padding(.vertical, 8)
                
                // Botão para criar nova conta
                Button("Criar nova conta") {
                    showRegister = true
                }
                .font(.footnote)
                .foregroundColor(.blue)
                
                
                // Apple login
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
            .fullScreenCover(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(auth) // repassa ViewModel
            }
        }
       
    }
}
*/

