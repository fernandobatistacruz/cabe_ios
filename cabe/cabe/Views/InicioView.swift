//
//  InicioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
internal import Combine
import GRDB

struct InicioView: View {
    @State private var mostrarNovaDespesa = false
    @State private var showCalendar = false
    @StateObject private var vm = NotificacoesViewModel()
    @StateObject private var viewModel: LancamentoListViewModel
    @AppStorage("mostrarValores") private var mostrarValores: Bool = true
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    init() {
        let repository = LancamentoRepository()
        let mesAtual = Calendar.current.component(.month, from: Date())
        let anoAtual = Calendar.current.component(.year, from: Date())
        
        _viewModel = StateObject(
            wrappedValue: LancamentoListViewModel(
                repository: repository,
                mes: mesAtual,
                ano: anoAtual
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        FavoritosView(
                            balanco: viewModel.balanco,
                            cartao: viewModel.totalCartao,
                            despesas: viewModel.totalDespesas,
                            mostrarValores: mostrarValores
                        )
                        
                        NavigationLink {
                            ConsumoDetalhadoView(
                                vm: viewModel,
                                items: viewModel.gastosPorCategoriaDetalhado
                            )
                        } label: {
                            ConsumoCardView(
                                dados: viewModel.gastosPorCategoriaResumo,
                                mostrarValores: mostrarValores
                            )
                        }
                        .buttonStyle(.plain)
                                                
                        RecentesListView(
                            viewModel: viewModel,
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
                    NavigationLink(
                        destination: NotificacoesView(vm: vm)
                    ) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                            
                            if vm.totalNotificacoes > 0 {
                                Text("\(vm.totalNotificacoes)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
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
                        viewModel.selecionar(data: dataSelecionada)
                    }
                )
                .presentationDetents([.medium, .large])
                
            }

        }
        .sheet(isPresented: $mostrarNovaDespesa) {
            NovoLancamentoView()
        }
    }

}

#Preview {
    //InicioView().environmentObject(ThemeManager())
}

struct FavoritosView: View{
    let balanco: Decimal
    let cartao: Decimal
    let despesas: Decimal
    let mostrarValores: Bool
    
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
                    mostrarValores: mostrarValores
                )
                NavigationLink {
                    CartaoListView()
                } label: {
                    CardItem(
                        title: String(localized: "Cartões"),
                        value: cartao,
                        color: .orange,
                        icone: "creditcard.fill",
                        mostrarValores: mostrarValores
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
                        value: 2500,
                        color: .blue,
                        icone:  "wallet.bifold.fill",
                        mostrarValores: mostrarValores
                    )
                }.buttonStyle(.plain)                
                CardItem(
                    title: String(localized: "Despesas"),
                    value: despesas,
                    color: .red,
                    icone: "barcode",
                    mostrarValores: mostrarValores
                    
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
                    Text(value, format: .currency(code: "BRL"))
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
        NavigationStack {
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
                                        mostrarValores: mosttrarValores,
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
}




