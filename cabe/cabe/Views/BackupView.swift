//
//  BackupView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 26/01/26.
//

import SwiftUI

struct BackupView: View {

    @AppStorage(AppSettings.backupAtivo)
    private var backupAtivo = false

    @AppStorage(AppSettings.ultimoBackupTimestamp)
    private var ultimoBackupTimestamp: Double = 0

    @EnvironmentObject var vm: BackupViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @State private var mostrarPaywall = false


    var body: some View {
        Form {

            Section {
                Toggle(
                    "Backup Automático",
                    isOn: Binding(
                        get: {
                            backupAtivo
                        },
                        set: { novoValor in
                            if novoValor {
                                if sub.isSubscribed {
                                    backupAtivo = true
                                } else {
                                    backupAtivo = false
                                    mostrarPaywall = true
                                }
                            } else {
                                backupAtivo = false
                            }
                        }
                    )
                )
            }
            footer: {
                Text("Quando ativado, seus dados serão salvos diariamente no iCloud.")
            }

            Section {
                HStack {
                    Text("Último Backup")
                    Spacer()
                    Text(ultimoBackupTexto)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Fazer Backup Agora") {
                    if ( sub.isSubscribed) {
                        vm.fazerBackupManual()
                    } else {
                        mostrarPaywall = true
                    }
                }

                Button("Apagar Backup do iCloud", role: .destructive) {
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
        .sheet(isPresented: $mostrarPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
    }

    private var ultimoBackupTexto: String {
        guard ultimoBackupTimestamp > 0 else { return String(localized: "Nunca") }
        let date = Date(timeIntervalSince1970: ultimoBackupTimestamp)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
