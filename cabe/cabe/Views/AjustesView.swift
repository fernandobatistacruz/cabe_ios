//
//  AjustesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/12/25.
//

import SwiftUI
internal import Combine

struct AjustesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section() {
                        HStack{
                            Image(systemName: "person.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.blue).padding(.horizontal,6)
                            VStack(alignment: .leading){
                                Text("Conta")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("fernandobatistacruz@gmail.com")
                                    .font(.subheadline)
                                    .tint(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }.padding(5)
                        
                    }
                    Section() {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.blue)
                            Text("Aparência")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .background(
                            NavigationLink("", destination: AppearanceSettingsView())
                                .opacity(0)
                        )
                        
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.red)
                            Text("Notificações")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .background(
                            NavigationLink("", destination: NotificacoesSettingsView())
                                .opacity(0)
                        )
                        
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.cyan)
                            Text("Backup")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .background(
                            NavigationLink("", destination: BackupSettingsView())
                                .opacity(0)
                        )
                        
                        
                        HStack {
                            Image(systemName: "purchased")
                                .foregroundStyle(.pink)
                            Text("Assinatura")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundStyle(.gray)
                            Text("Sobre")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section() {
                        HStack {
                            Image(systemName: "switch.2")
                                .foregroundStyle(.green)
                            Text("Controle de Pagamento")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Image(systemName: "wallet.bifold.fill")
                                .foregroundStyle(.orange)
                            Text("Carteira Padrão")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Image(systemName: "square.split.2x2.fill")
                                .foregroundStyle(.purple)
                            Text("Categorias")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
        }        
    }
}
#Preview {
    AjustesView().environmentObject(ThemeManager())
}

final class ThemeManager: ObservableObject {

    enum Theme: String {
        case system, light, dark
    }

    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        theme = Theme(rawValue: saved ?? "") ?? .system
    }
}

struct AppearanceSettingsView: View {

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    themeRow(
                        title: String(localized: "Automático"),
                        theme: .system
                    )

                    themeRow(
                        title:  String(localized: "Claro"),
                        theme: .light
                    )

                    themeRow(
                        title:  String(localized: "Escuro"),
                        theme: .dark
                    )
                } footer: {
                    Text("Escolha como o app deve se comportar em relação ao modo Claro e Escuro.")
                }
            }
            .navigationTitle("Aparência")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private func themeRow(
        title: String,
        theme: ThemeManager.Theme
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            if themeManager.theme == theme {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            themeManager.theme = theme
        }
    }
}

struct NotificacoesSettingsView: View {

    @State private var notificacaoAtivo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $notificacaoAtivo) {
                        Text("Notificações")
                    }
                } footer: {
                    Text("Quando ativo, você será notificado quando houver um lançamento vencendo no dia.")
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }
}

struct BackupSettingsView: View {

    @State private var backupAtivo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $backupAtivo) {
                        Text("Backup do iCloud")
                    }
                } footer: {
                    Text("Quando ativado, seus dados serão salvos automaticamente no iCloud.")
                }
            }
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }
}







