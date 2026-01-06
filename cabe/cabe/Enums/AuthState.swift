//
//  AuthState.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//


import FirebaseAuth

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
}
