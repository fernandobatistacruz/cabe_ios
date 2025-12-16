import SwiftUI

struct MonthYearPickerView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    let onSelect: (Int, Int) -> Void

    private let calendar = Calendar.current
    private let years: [Int] = {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return Array(2020...(currentYear + 10))
    }()
    
    

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    init(
        initialYear: Int,
        initialMonth: Int,
        onSelect: @escaping (Int, Int) -> Void
    ) {
        _selectedYear = State(initialValue: initialYear)
        _selectedMonth = State(initialValue: initialMonth)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 32) {

                        Color.clear.frame(height: 12)

                        ForEach(years, id: \.self) { year in
                            YearSection(
                                year: year,
                                calendar: calendar,
                                selectedYear: selectedYear,
                                selectedMonth: selectedMonth
                            ) { y, m in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedYear = y
                                    selectedMonth = m
                                }

                                onSelect(y, m)
                                dismiss()
                            }
                            .id(year)
                        }

                        Color.clear.frame(height: 24)
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(selectedYear, anchor: .center)
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .toolbar {
               
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.gray)
                }
             
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hoje") {
                        let today = Date()
                        let year = calendar.component(.year, from: today)
                        let month = calendar.component(.month, from: today)

                        onSelect(year, month)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .fontWeight(.semibold)
                    .tint(.blue)
                    
                }
            }
        }
    }
}

#Preview {
    MonthYearPickerView(
        initialYear: Calendar.current.component(.year, from: Date()),
        initialMonth: Calendar.current.component(.month, from: Date())
    ) { year, month in
        print("Preview selecionado:", year, month)
    }
    .presentationDetents([.medium, .large])
}



struct YearSection: View {

    let year: Int
    let calendar: Calendar
    let selectedYear: Int
    let selectedMonth: Int
    let onSelect: (Int, Int) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(year, format: .number.grouping(.never))
                .font(.title.weight(.semibold))
                .foregroundColor(year == selectedYear ? .accentColor : .primary)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    MonthCell(
                        title: calendar.monthSymbols[month - 1],
                        isSelected: year == selectedYear && month == selectedMonth
                    )
                    .onTapGesture {
                        onSelect(year, month)
                    }
                }
            }
            .padding(.horizontal)
            
        }
    }
}

struct MonthCell: View {

    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title.capitalized)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        isSelected ? Color.accentColor : Color.secondary
                            .opacity(0.10)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}


