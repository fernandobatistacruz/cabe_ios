//
//  AboutView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 26/01/26.
//

import SwiftUI

struct AboutView: View {
    
    @State private var showAlert = false

    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
             
                VStack(spacing: 12) {
                    Image(uiImage: UIImage(named: "app_icon_ui") ?? UIImage())
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text(appName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Versão \(version)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
               
                VStack(spacing: 16) {
                    
                    if let idioma = Bundle.main.preferredLocalizations.first {
                        let languageCode = Locale(identifier: idioma).language.languageCode?.identifier ?? ""
                        
                        if languageCode == "pt" {
                            LinkRow(
                                title: String(localized: "Política de Privacidade"),
                                systemImage: "hand.raised",
                                url: URL(string: "https://sites.google.com/view/cabeapp/privacidade")!
                            )
                        } else {
                            LinkRow(
                                title: String(localized: "Política de Privacidade"),
                                systemImage: "hand.raised",
                                url: URL(string: "https://sites.google.com/view/cabeapp/privacy-policy")!
                            )
                        }
                    }
                    LinkRow(
                        title: String(localized: "Termos de Uso (EULA)"),
                        systemImage: "doc.text",
                        url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!
                    )
                }
                .padding(.horizontal)
             
                VStack(spacing: 8) {
                    Text("Suporte")
                        .font(.headline)
                    
                    Button {
                        let email = "cabe.aplicativo@gmail.com"

                        if let url = URL(string: "mailto:\(email)"),
                           UIApplication.shared.canOpenURL(url) {

                            UIApplication.shared.open(url)
                        } else {
                            UIPasteboard.general.string = email
                            showAlert = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(verbatim: "cabe.aplicativo@gmail.com")
                        }
                    }
                    .alert("E-mail copiado",
                           isPresented: $showAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Cole o e-mail no app de sua preferência.")
                    }
                }
               
                Text("Desenvolvido por Fernando Batista da Cruz")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Sobre")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct LinkRow: View {
    let title: String
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
}
