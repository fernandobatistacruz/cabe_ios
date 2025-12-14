//
//  CartaoListViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/12/25.
//


import Foundation
internal import Combine

@MainActor
final class CartaoListViewModel: ObservableObject {

    @Published var cartoes: [CartaoModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dao = CartaoData()

    func carregar() {
        isLoading = true
        errorMessage = nil

        Task {
            let resultado = await dao.listar()
            self.cartoes = resultado
            self.isLoading = false
        }
    }
}
