//
//  PerfilUsuarioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//

import SwiftUI

struct PerfilUsuarioView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showConfirmation = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 12) {

            // Foto
            AsyncImage(url: auth.user?.photoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .padding(.top)

            // Nome
            Text(auth.user?.name ?? "Usuário")
                .font(.title2)
                .fontWeight(.semibold)

            // Email
            Text(auth.user?.email ?? "")
                .foregroundColor(.secondary)
            
            if let creation = auth.user?.creationDate {
                Text("Conta criada em \(creation.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            Button(role: .destructive) {
                showConfirmation = true
            } label: {
                Text("Remover conta")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .alert("Remover conta", isPresented: $showConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Confirmar", role: .destructive) {
                    Task {
                        await auth.removerConta()
                        if auth.errorMessage == nil {
                            showSuccess = true
                        }
                    }
                }
            } message: {
                Text("Tem certeza que deseja remover sua conta? Essa ação não pode ser desfeita.")
            }
           
            Button {
                auth.signOut()
            } label: {
                Text("Finalizar sessão")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
        .navigationTitle("Minha Conta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Conta removida", isPresented: $showSuccess) {
            Button("OK") {
                auth.signOut()
            }
        } message: {
            Text("Sua conta foi removida com sucesso.")
        }
    }
}


