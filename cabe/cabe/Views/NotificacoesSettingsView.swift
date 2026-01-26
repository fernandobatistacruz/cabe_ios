//
//  NotificacoesSettingsView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 26/01/26.
//

import SwiftUI

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
                                        notificacoesAtivas = false
                                    }
                                }
                            }

                    case .denied:
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func abrirAjustesDoSistema() {
        guard let url = URL(string: UIApplication.openSettingsURLString)
        else { return }

        UIApplication.shared.open(url)
    }
}
