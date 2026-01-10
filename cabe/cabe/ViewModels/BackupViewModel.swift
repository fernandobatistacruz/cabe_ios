//
//  BackupViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//

import Foundation
import Combine

@MainActor
final class BackupViewModel: ObservableObject {

    @Published var emProgresso = false
    @Published var erro: String?

    private let service = BackupService.shared

    func fazerBackupManual() {
        let service = self.service

        executar {
            try service.fazerBackup()
            self.salvarUltimoBackup()
        }
    }
    
    func apagarBackup() {
        let service = self.service
        
        executar {
            try service.apagarBackup()
            UserDefaults.standard.removeObject(
                forKey: AppSettings.ultimoBackupTimestamp
            )
        }
    }

    private func salvarUltimoBackup() {
        let timestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(
            timestamp,
            forKey: AppSettings.ultimoBackupTimestamp
        )
    }

    private func executar(_ action: @escaping () throws -> Void) {
        emProgresso = true
        erro = nil

        DispatchQueue.global(qos: .utility).async {
            do {
                try action()
            } catch {
                DispatchQueue.main.async {
                    self.erro = error.localizedDescription
                }
            }

            DispatchQueue.main.async {
                self.emProgresso = false
            }
        }
    }
}
