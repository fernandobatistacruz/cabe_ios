//
//  AjustesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/12/25.
//

import SwiftUI

struct AjustesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @AppStorage(AppSettings.notificacoesAtivas)
    private var notificacoesAtivas: Bool = false
    
    @AppStorage(AppSettings.backupAtivo)
    private var backupAtivo = false
    
    @AppStorage(AppSettings.pagamentoPadrao)
    private var pagamentoPadraoData: Data?
    @State private var pagamentoPadrao: MeioPagamento? = nil
    
    @State private var mostrandoZoomPagamento = false
    
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
                                    .font(.headline)
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.cyan)
                            Text("Backup")
                            Spacer()
                            Text(backupAtivo ? String(localized: "Ativado") :  String(localized: "Desativado"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        PaywallView(isModal: false)
                    } label: {
                        HStack (){
                            Image(systemName: "purchased")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray)
                            Text("Sobre")
                        }
                    }
                  
                }
                Section() {
                    NavigationLink {
                            ZoomPagamentoView(
                                selecionado: $pagamentoPadrao,
                                salvarComoPadrao: true
                            )
                    } label: {
                        HStack {
                            Image(systemName: "wallet.bifold.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.green)
                            Text("Pagamento Padrão")
                            Spacer()
                            if let pagamento = pagamentoPadrao {
                                Text(pagamento.titulo)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Nenhum")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoriaListView()
                    } label: {
                        HStack (){
                            Image(systemName: "square.split.2x2.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.purple)
                            Text("Categorias")
                        }
                    }
                    
                    NavigationLink {
                        CartaoListView()
                    } label: {
                        HStack (){
                            Image(systemName: "creditcard.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.orange)
                            Text("Cartão de Crédito")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let data = pagamentoPadraoData,
               let meio = try? JSONDecoder().decode(MeioPagamento.self, from: data) {
                pagamentoPadrao = meio
            } else {
                pagamentoPadrao = nil
            }
        }
    }
}

#Preview {
    AjustesView().environmentObject(ThemeManager())
}
