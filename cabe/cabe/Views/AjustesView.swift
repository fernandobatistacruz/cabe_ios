//
//  AjustesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/12/25.
//

import SwiftUI
import Combine
import UserNotifications

struct AjustesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @AppStorage(AppSettings.notificacoesAtivas)
    private var notificacoesAtivas: Bool = false
    
    @AppStorage(AppSettings.backupAtivo)
    private var backupAtivo = false
    
    var body: some View {
        VStack {
            List {
                Section {
                    NavigationLink {
                        PerfilUsuarioView()
                    } label: {
                        HStack (){
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
                            .padding(.trailing, 5)
                            
                            VStack(alignment: .leading) {
                                Text(auth.user?.name ?? "Conta")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(auth.user?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(5)
                    }
                }
                Section() {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack (){
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.blue)
                            Text("Aparência")
                            Spacer()
                            Text(themeManager.theme.title)
                                .foregroundStyle(.secondary)
                           
                        }
                    }
                    
                    NavigationLink {
                        NotificacoesSettingsView()
                    } label: {
                        HStack (){
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.red)
                            Text("Notificações")
                            Spacer()
                            Text(notificacoesAtivas ?  String(localized: "Ativado") :  String(localized: "Desativado"))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        BackupView()
                    } label: {
                        HStack (){
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.cyan)
                            Text("Backup")
                            Spacer()
                            Text(backupAtivo ? String(localized: "Ativado") :  String(localized: "Desativado"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        PaywallView()
                    } label: {
                        HStack (){
                            Image(systemName: "purchased")
                                .foregroundStyle(.pink)
                            Text("Assinatura")
                            Spacer()
                            Text(sub.currentPlan.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack (){
                            Image(systemName: "iphone")
                                .foregroundStyle(.gray)
                            Text("Sobre")
                        }
                    }
                  
                }
                Section() {
                    /*
                    HStack {
                        Image(systemName: "switch.2")
                            .foregroundStyle(.green)
                        Text("Controle de Pagamento")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                     */
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

#Preview {
    AjustesView().environmentObject(ThemeManager())
}

final class ThemeManager: ObservableObject {

    enum Theme: String, CaseIterable {
        case system
        case light
        case dark

        var title: LocalizedStringKey {
            switch self {
            case .system:
                return "theme.system"
            case .light:
                return "theme.light"
            case .dark:
                return "theme.dark"
            }
        }
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
            .toolbar(.hidden, for: .tabBar)
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
        .toolbar(.hidden, for: .tabBar)
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

/*
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
            .toolbar(.hidden, for: .tabBar)
            .listStyle(.insetGrouped)
        }
    }
}
 */


struct BackupView: View {

    @AppStorage(AppSettings.backupAtivo)
    private var backupAtivo = false

    @AppStorage(AppSettings.ultimoBackupTimestamp)
    private var ultimoBackupTimestamp: Double = 0

    @EnvironmentObject var vm: BackupViewModel

    var body: some View {
        Form {

            Section {
                Toggle("Ativar backup automático", isOn: $backupAtivo)
            }
            footer: {
                Text("Quando ativado, seus dados serão salvos automaticamente no iCloud.")
            }

            Section {
                HStack {
                    Text("Último backup")
                    Spacer()
                    Text(ultimoBackupTexto)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Fazer backup agora") {
                    vm.fazerBackupManual()
                }

                Button("Apagar backup do iCloud", role: .destructive) {
                    vm.apagarBackup()
                }
            }

            if vm.emProgresso {
                ProgressView()
            }

            if let erro = vm.erro {
                Text(erro)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var ultimoBackupTexto: String {
        guard ultimoBackupTimestamp > 0 else { return "Nunca" }
        let date = Date(timeIntervalSince1970: ultimoBackupTimestamp)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct AboutView: View {
    
    @State private var showAlert = false

    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // MARK: - Header
                VStack(spacing: 12) {
                    Image(uiImage: UIImage(named: "app_icon_ui") ?? UIImage())
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text(appName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Versão \(version) (\(build))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // MARK: - Links
                VStack(spacing: 16) {
                    //TODO: Ajustar o links de privacidade e termos de uso
                    LinkRow(
                        title: "Política de Privacidade",
                        systemImage: "hand.raised",
                        url: URL(string: "https://sites.google.com/view/cabeapp/privacidade")!
                    )

                    LinkRow(
                        title: "Termos de Uso (EULA)",
                        systemImage: "doc.text",
                        url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!
                    )
                }
                .padding(.horizontal)
                
                
                

                // MARK: - Support
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

                // MARK: - Footer
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







