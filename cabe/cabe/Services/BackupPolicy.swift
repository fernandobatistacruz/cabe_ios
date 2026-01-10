//
//  BackupPolicy.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//


import Foundation

enum BackupPolicy {

    static let intervaloMinimo: TimeInterval = 60 * 60 * 24 // 24h

    static func deveFazerBackupAutomatico() -> Bool {
        let ativo = UserDefaults.standard.bool(forKey: AppSettings.backupAtivo)
        guard ativo else { return false }

        let ultimo = UserDefaults.standard.double(
            forKey: AppSettings.ultimoBackupTimestamp
        )

        if ultimo == 0 { return true }

        let agora = Date().timeIntervalSince1970
        return agora - ultimo >= intervaloMinimo
    }
}
