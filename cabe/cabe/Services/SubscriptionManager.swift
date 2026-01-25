//
//  SubscriptionManager.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 08/01/26.
//


import StoreKit
import SwiftUI
import Combine

enum SubscriptionError: Error {
    case failedVerification
}

@MainActor
final class SubscriptionManager: ObservableObject {
    
    @AppStorage("isAdmin")
    private var isAdmin: Bool = false
    
    @Published var product: Product?
    private let productId = "com.example.cabe.completa"
    
    @AppStorage("isSubscribed")
    private(set) var isSubscribed: Bool = false
    
    @Published var isLoadingProduct: Bool = false
    @Published var isPurchasing: Bool = false

    var currentPlan: Plan {
        isSubscribed ? .complete : .basic
    }

    enum Plan {
        case basic
        case complete

        var title: String {
            switch self {
            case .basic:
                return "Básica"
            case .complete:
                return "Completa"
            }
        }
    }

    init() {
        observeTransactions()
        
        Task {
            await loadProduct()
            await updateSubscriptionStatus()
        }
    }

    // MARK: - Produto
    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [productId])
            self.product = products.first
        } catch {
            print("Erro ao carregar produto:", error)
            self.product = nil
        }
    }

    // MARK: - Compra
    func purchase() async {
        guard let product else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()

            case .userCancelled:
                break

            case .pending:
                break

            @unknown default:
                break
            }
        } catch {
            print("Erro na compra:", error)
        }
    }

    // MARK: - Status da assinatura
    func updateSubscriptionStatus() async {
        if isAdmin {
            isSubscribed = true
            return
        }
        
        guard let product else { return }

        do {
            let statuses = try await product.subscription?.status ?? []

            isSubscribed = statuses.contains { status in
                status.state == .subscribed
            }
            /*
            #if DEBUG
            isSubscribed = true
            #endif
            */
             
        } catch {
            print("Erro ao verificar assinatura:", error)
            isSubscribed = false
        }
    }

    // MARK: - Restaurar
    func restore() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Observador
    private func observeTransactions() {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await updateSubscriptionStatus()
                } catch {
                    print("Transação inválida")
                }
            }
        }
    }

    // MARK: - Verificação
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw SubscriptionError.failedVerification
        }
    }
}
