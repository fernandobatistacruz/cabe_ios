//
//  PaywallView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 08/01/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject var sub: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    var isModal: Bool = true

    @State private var selectedPlan: SubscriptionManager.Plan = .basic

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                planCards
                footerText
            }
            .padding()
        }
        .onAppear {
            selectedPlan = sub.currentPlan
        }
        .navigationTitle("Assinatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await sub.restore()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Footer

    var footerText: some View {
        Group {
            if let product = sub.product {
                Text("A assinatura será automaticamente renovada por \(product.displayPrice) por mês até ser cancelada.")
            } else {
                Text("Carregando informações da assinatura…")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Header

private extension PaywallView {

    var header: some View {
        VStack(spacing: 12) {

            if sub.currentPlan == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }

            Text(sub.currentPlan == .complete
                 ? "Assinatura Completa"
                 : "Assinatura Básica")
                .font(.title.bold())

            Text(statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    var statusDescription: String {
        sub.currentPlan == .complete
        ? "Você tem acesso a todos os recursos da assinatura completa."
        : "Você está usando a assinatura básica."
    }
}

// MARK: - Plans

private extension PaywallView {

    var planCards: some View {
        VStack(spacing: 16) {
            basicPlan
            completePlan
        }
    }

    var basicPlan: some View {
        PlanCard(
            title: "Básica",
            price: "Grátis",
            features: [
                "Contas, cartões e categorias limitados",
                "Com anúncios"
            ],
            isSelected: selectedPlan == .basic,
            showsButton: false,
            isPurchasing: false
        )
        .onTapGesture {
            if sub.currentPlan != .complete {
                selectedPlan = .basic
            }
        }
    }

    var completePlan: some View {
        PlanCard(
            title: "Completa",
            price: sub.isLoadingProduct
                ? "Carregando…"
                : sub.product?.displayPrice ?? "Indisponível",
            features: [
                "Acesso ilimitado aos cadastros",
                "Exportação de dados para CSV",
                "Backup no iCloud",
                "Notificação de vencimento",
                "Sem anúncios"
            ],
            isSelected: selectedPlan == .complete,
            showsButton: true,
            action: {
                Task {
                    await sub.purchase()
                }
            },
            isPurchasing: sub.isPurchasing,
            isButtonEnabled:
                selectedPlan == .complete &&
                sub.product != nil &&
                !sub.isPurchasing
        )
        .onTapGesture {
            selectedPlan = .complete
        }
    }
}

// MARK: - PlanCard

struct PlanCard: View {

    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool

    let showsButton: Bool
    var action: (() -> Void)? = nil
    let isPurchasing: Bool
    var isButtonEnabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())

                    Text(price)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .font(.title3)
                }
            }

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                        .font(.footnote)

                    Text(feature)
                        .font(.footnote)
                }
            }

            // 🔥 Botão só aparece se permitido
            if showsButton {
                Button {
                    action?()
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        Text("Assinar")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isButtonEnabled)
                .opacity(isButtonEnabled ? 1.0 : 0.6)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.tint, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
    }
}
