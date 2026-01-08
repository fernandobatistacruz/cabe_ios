//
//  PerfilUsuarioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//

import SwiftUI

struct PerfilUsuarioView: View {
    @EnvironmentObject var auth: AuthViewModel

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

            // Logout
            Button(role: .destructive) {
                auth.signOut()
            } label: {
                Text("Finalizar sessão")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
        .navigationTitle("Minha Conta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
