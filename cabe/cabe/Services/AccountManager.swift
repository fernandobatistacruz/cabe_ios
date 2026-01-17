//
//  AccountManager.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/01/26.
//

import Foundation

@MainActor
final class AccountManager {

    static let shared = AccountManager()
    
    func removerConta() async {
        do {
            // 1. Remover conta remota
            // await authService.deleteUser()

            // 2. Apagar banco local
            try AppDatabase.shared.deleteDatabase()

            // 3. Limpar preferências
            UserDefaults.standard.removePersistentDomain(
                forName: Bundle.main.bundleIdentifier!
            )

            // 4. Recriar banco limpo
            try AppDatabase.shared.recreateDatabase()

            // 5. Redirecionar UI / onboarding
        } catch {
            print("Erro ao remover conta:", error)
        }
    }
}
