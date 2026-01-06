//
//  AjustesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/12/25.
//

import SwiftUI
internal import Combine
import UserNotifications

struct AjustesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        NavigationLink {
                            PerfilUsuarioView()
                        } label: {
                            HStack {
                                AsyncImage(url: auth.user?.photoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 45))
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 6)
                                }
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text(auth.user?.name ?? "Conta")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text(auth.user?.email ?? "")
                                        .font(.subheadline)
                                        .tint(.secondary)
                                }
                            }
                            .padding(5)
                        }
                        .buttonStyle(.plain) // evita efeito de botão azul
                    }

                    /*
                    Section() {
                        HStack{
                            AsyncImage(url: auth.user?.photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 45))
                                    .foregroundStyle(.blue).padding(.horizontal,6)
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            VStack(alignment: .leading){
                                Text(auth.user?.name ?? "Conta")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(auth.user?.email ?? "")
                                    .font(.subheadline)
                                    .tint(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }.padding(5)
                        
                    }
                     */
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

    @AppStorage(AppSettings.notificacoesAtivas)
    private var notificacoesAtivas: Bool = false
    @State private var sistemaBloqueado = false

    var body: some View {
        List {
            Section {
                Toggle("Notificações", isOn: $notificacoesAtivas)
                    .onChange(of: notificacoesAtivas) { ativo in
                        if ativo {
                            solicitarPermissaoSeNecessario()
                        } else {
                            cancelarNotificacoes()
                        }
                    }
            } footer: {
                Text("Quando ativo, você será notificado quando houver um lançamento vencendo no dia.")
            }
        }
        .navigationTitle("Notificações")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    // MARK: - Permissão

    private func solicitarPermissaoSeNecessario() {
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {

                    case .notDetermined:
                        UNUserNotificationCenter.current()
                            .requestAuthorization(
                                options: [.alert, .badge, .sound]
                            ) { granted, _ in
                                DispatchQueue.main.async {
                                    if !granted {
                                        // usuário recusou → volta o toggle
                                        notificacoesAtivas = false
                                    }
                                }
                            }

                    case .denied:
                        // NÃO muda o AppStorage
                        sistemaBloqueado = true
                        abrirAjustesDoSistema()

                    case .authorized, .provisional:
                        sistemaBloqueado = false

                    default:
                        break
                    }
                }
            }
    }


    private func cancelarNotificacoes() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["lancamentos-dia"]
            )
    }

    private func abrirAjustesDoSistema() {
        guard let url = URL(string: UIApplication.openSettingsURLString)
        else { return }

        UIApplication.shared.open(url)
    }
}


enum AppSettings {
    static let notificacoesAtivas = "notificacoesAtivas"
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







