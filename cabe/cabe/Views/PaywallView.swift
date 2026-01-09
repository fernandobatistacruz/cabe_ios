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

    var body: some View {
        ScrollView {
            
            VStack(spacing: 24) {

                header
                planCards
                footerText
            }
            .padding()
        }
        .navigationTitle("Assinatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await sub.restore()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Restaurar compras")
            }
        }
    }
    
    var footerText: some View {
        Text("A assinatura será automaticamente renovada por \(sub.product?.displayPrice ?? "") por mês até ser cancelada.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

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
                 ? "Assinatura Ativa"
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
            isSelected: sub.currentPlan == .basic
        )
    }
    
    var completePlan: some View {
        PlanCard(
            title: "Completa",
            price: sub.product?.displayPrice ?? "R$ —/mês",
            features: [
                "Acesso ilimitado aos cadastros",
                "Exportação de dados para CSV",
                "Backup no iCloud",
                "Notificação de vencimento",
                "Sem anúncios"
            ],
            isSelected: sub.currentPlan == .complete,
            action: {
                Task {
                    await sub.purchase()
                }
            }
        )
    }
}

struct PlanCard: View {

    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool
    var action: (() -> Void)? = nil

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

            if let action, !isSelected {
                Button {
                    action()
                } label: {
                    Text("Assinar")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
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
    }
}

