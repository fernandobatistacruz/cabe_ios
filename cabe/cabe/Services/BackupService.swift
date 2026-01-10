//
//  BackupError.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//


import Foundation
import UIKit

enum BackupError: LocalizedError {
    case iCloudIndisponivel
    case bancoLocalInexistente
    case backupNaoEncontrado

    var errorDescription: String? {
        switch self {
        case .iCloudIndisponivel:
            return "iCloud não está disponível. Verifique se você está logado no iCloud."
        case .bancoLocalInexistente:
            return "Banco de dados local não encontrado."
        case .backupNaoEncontrado:
            return "Nenhum backup encontrado no iCloud."
        }
    }
}

final class BackupService {

    static let shared = BackupService()
    private init() {}

    // MARK: - Paths

    private let databaseName = "cabe.db"
    private let backupFolder = "backup"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var localDatabaseURL: URL {
        documentsURL.appendingPathComponent(databaseName)
    }

    private var iCloudContainerURL: URL? {
        FileManager.default.url(
            forUbiquityContainerIdentifier: "iCloud.com.example.cabe"
        )
    }

    private var iCloudDatabaseURL: URL? {
        guard let container = iCloudContainerURL else { return nil }
        return container
            .appendingPathComponent("Documents")
            .appendingPathComponent(backupFolder)
            .appendingPathComponent(databaseName)
    }

    // MARK: - Status

    func iCloudDisponivel() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func existeBackupNoICloud() -> Bool {
        guard let url = iCloudDatabaseURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - Backup

    func fazerBackup() throws {
        guard iCloudDisponivel() else {
            throw BackupError.iCloudIndisponivel
        }

        let fm = FileManager.default

        guard fm.fileExists(atPath: localDatabaseURL.path) else {
            throw BackupError.bancoLocalInexistente
        }

        guard let iCloudURL = iCloudDatabaseURL else {
            throw BackupError.iCloudIndisponivel
        }

        let backupDir = iCloudURL.deletingLastPathComponent()
        try fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

        if fm.fileExists(atPath: iCloudURL.path) {
            try fm.removeItem(at: iCloudURL)
        }

        try fm.copyItem(at: localDatabaseURL, to: iCloudURL)
    }

    // MARK: - Restore

    func restaurarSeNecessario() throws {
        let fm = FileManager.default

        guard !fm.fileExists(atPath: localDatabaseURL.path) else {
            return
        }

        guard let iCloudURL = iCloudDatabaseURL,
              fm.fileExists(atPath: iCloudURL.path) else {
            return
        }

        try fm.copyItem(at: iCloudURL, to: localDatabaseURL)
    }

    // MARK: - Delete

    func apagarBackup() throws {
        guard let iCloudURL = iCloudDatabaseURL,
              FileManager.default.fileExists(atPath: iCloudURL.path) else {
            throw BackupError.backupNaoEncontrado
        }

        try FileManager.default.removeItem(at: iCloudURL)
    }
}
