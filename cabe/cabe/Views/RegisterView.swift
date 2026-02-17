//
//  RegisterView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 07/01/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var name: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
               
                Image("app_icon_ui")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Text("Criar Conta")
                    .font(.title)
                    .fontWeight(.bold)
                
                // MARK: - Campos
                VStack(spacing: 12) {
                    TextField("Nome", text: $name)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .foregroundColor(.primary)
                        .disableAutocorrection(true)
                    
                    TextField("E-mail", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .foregroundColor(.primary)
                    
                    SecureField("Senha", text: $auth.password)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .foregroundColor(.primary)
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let info = auth.infoMessage {
                        Text(info)
                            .foregroundColor(.blue)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                   
                    Button {
                        Task { await auth.registerWithEmail(name: name) }
                    } label: {
                        Text("Criar Conta")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.accentColor)
                            .cornerRadius(22)
                    }
                }
                               
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Text("Cancelar")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
