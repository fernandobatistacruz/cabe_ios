//
//  InicioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
internal import Combine

struct InicioView: View {
    @State private var mostrarNovaDespesa = false
    @State private var showCalendar = false
    @StateObject private var vmLancamentos: LancamentoListViewModel
    @StateObject private var vmContas: ContaListViewModel
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    
    
    @AppStorage("mostrarValores") private var mostrarValores: Bool = true
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: vmLancamentos.anoAtual,
                month: vmLancamentos.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    init(vmLancamentos: LancamentoListViewModel) {
        _vmLancamentos = StateObject(wrappedValue: vmLancamentos)
        
        let repositoryConta = ContaRepository()
        _vmContas = StateObject(
            wrappedValue: ContaListViewModel(repository: repositoryConta)
        )
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    
                    FavoritosView(
                        balanco: vmLancamentos.balanco,
                        cartao: vmLancamentos.totalCartao,
                        constas: vmContas.saldoTotal,
                        despesas: vmLancamentos.totalDespesas,
                        mostrarValores: mostrarValores,
                        moeda: vmContas.contas.first?.currencyCode ?? "BRL"
                    )
                    
                    NavigationLink {
                        ConsumoDetalhadoView(
                            vm: vmLancamentos,
                            items: vmLancamentos.gastosPorCategoriaDetalhado
                        )
                    } label: {
                        ConsumoCardView(
                            dados: vmLancamentos.gastosPorCategoriaResumo,
                            mostrarValores: mostrarValores
                        )
                    }
                    .buttonStyle(.plain)
                    
                    RecentesListView(
                        viewModel: vmLancamentos,
                        mosttrarValores: mostrarValores
                    )
                }
                .padding(.bottom, 10)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mostrarNovaDespesa = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(
            Text(selectedDate, format: .dateTime.month(.wide))
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCalendar = true
                } label: {
                    //Image(systemName: "chevron.left")
                    Text(selectedDate, format: .dateTime.year())
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    deepLinkManager.path.append(DeepLink.notificacoes)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                        
                        if vmLancamentos.notificacaoVM.total > 0 {
                            Text("\(vmLancamentos.notificacaoVM.total)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                Button {
                    mostrarValores.toggle()
                } label: {
                    Image(systemName: mostrarValores ? "eye.slash" : "eye" )
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            CalendarioZoomView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    vmLancamentos.selecionar(data: dataSelecionada)
                }
            )
            .presentationDetents([.medium, .large])
            
        }
        .sheet(isPresented: $mostrarNovaDespesa) {
            NovoLancamentoView()
        }
    }
}


struct FavoritosView: View{
    let balanco: Decimal
    let cartao: Decimal
    let constas: Decimal
    let despesas: Decimal
    let mostrarValores: Bool
    let moeda: String
    
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Resumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack() {
                CardItem(
                    title: String(localized: "Balanço"),
                    value: balanco,
                    color: .purple,
                    icone:  "chart.bar.fill",
                    mostrarValores: mostrarValores,
                    moeda: moeda
                )
                NavigationLink {
                    CartaoListView()
                } label: {
                    CardItem(
                        title: String(localized: "Cartões"),
                        value: cartao,
                        color: .orange,
                        icone: "creditcard.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }
                .buttonStyle(.plain)
            }.padding(.horizontal)
            HStack() {
                NavigationLink {                    
                    ContaListView()
                } label: {
                    CardItem(
                        title: String(localized: "Contas"),
                        value: constas,
                        color: .blue,
                        icone:  "wallet.bifold.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }.buttonStyle(.plain)                
                CardItem(
                    title: String(localized: "Despesas"),
                    value: despesas,
                    color: .red,
                    icone: "barcode",
                    mostrarValores: mostrarValores,
                    moeda: moeda
                    
                )
            }.padding(.horizontal)
        }
    }
}

struct CardItem: View {

    let title: String
    let value: Decimal
    let color: Color
    let icone: String
    let mostrarValores: Bool
    let moeda: String
    
    // Generates a subtle vertical gradient derived from the base color
    // Keeps good contrast in light/dark mode and avoids fully opaque blocks
    private func gradientColors(from base: Color) -> [Color] {
        // Slightly vary opacity for depth while keeping the hue
        let top = base.opacity(0.32)
        let middle = base.opacity(0.25)
        let bottom = base.opacity(0.36)
        return [top, middle, bottom]
    }

    var body: some View {
        HStack() {
            Image(systemName: icone)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if(mostrarValores){
                    Text(formatarValor(value, moeda: moeda))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }else{
                    Text("•••") // placeholder ou valor oculto
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradientColors(from: color),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    func formatarValor(_ valor: Decimal, moeda: String) -> String {
        let locale = Locale.current

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = moeda
        formatter.locale = locale
        formatter.maximumFractionDigits = 2

        let absValor = (valor as NSDecimalNumber).doubleValue
        let numero: Decimal
        let sufixo: String

        switch absValor {
        case 1_000_000_000...:
            numero = valor / 1_000_000_000
            sufixo = NSLocalizedString("suffix_billion", comment: "")
        case 1_000_000...:
            numero = valor / 1_000_000
            sufixo = NSLocalizedString("suffix_million", comment: "")
        case 100_000...:
            numero = valor / 1_000
            sufixo = NSLocalizedString("suffix_thousand", comment: "")
        default:
            return formatter.string(from: valor as NSDecimalNumber) ?? "\(valor)"
        }

        let valorFormatado = formatter.string(from: numero as NSDecimalNumber) ?? "\(numero)"
        return "\(valorFormatado) \(sufixo)"
    }
}

struct ConsumoCardView: View {
    
    let dados: [CategoriaResumo]
    let mostrarValores: Bool

    var body: some View {
        
        VStack(alignment: .leading){
            Text("Consumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack(spacing: 24) {
                ConsumoListView(items: dados, mostrarValores: mostrarValores)
                    .padding()
                DonutChartView(items: dados, lineWidth: 18 , size: 70)
                    .padding(.trailing, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
}

struct RecentesListView: View {
    
    @ObservedObject var viewModel: LancamentoListViewModel
    let mosttrarValores: Bool
    
    @State private var mostrarDetalhe = false
    @State private var selectedLancamento: LancamentoModel?
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("Recentes")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(viewModel.lancamentosRecentesAgrupadosSimples, id: \.date) { grupo in
                
                Text(grupo.date, format: .dateTime.day().month(.wide))
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.top, viewModel.lancamentosRecentesAgrupadosSimples.first?.date == grupo.date ? 0 : 10)
                
                VStack(spacing: 0) {
                    ForEach(grupo.items.indices, id: \.self) { index in
                        
                        Button {
                            selectedLancamento = grupo.items[index]
                            mostrarDetalhe = true
                        } label: {
                            HStack {
                                LancamentoRow(
                                    lancamento: grupo.items[index],
                                    mostrarPagamento: false,
                                    mostrarValores: mosttrarValores                                  
                                )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        if index != grupo.items.count - 1 {
                            Divider()
                                .padding(.leading, 35)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .padding(.horizontal)
        .navigationDestination(isPresented: $mostrarDetalhe) {
            if let lancamento = selectedLancamento {
                LancamentoDetalheView(lancamento: lancamento)
            }
        }
    }
}
    





