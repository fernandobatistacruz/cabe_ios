//
//  AuthViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//


import FirebaseAuth
import Combine
import AuthenticationServices
import GoogleSignIn
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    
    @AppStorage("isAdmin")
    private(set) var isAdmin: Bool = false

    @Published private(set) var state: AuthState = .loading
    @Published var error: AuthError?
    @Published var pendingLinkCredential: AuthCredential?
    @Published private(set) var user: AuthUser?
    @Published var infoMessage: String?
    
    // MARK: - Email/Password
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?

    private let appleService = AppleSignInService()
    private let googleService = GoogleSignInService()
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init() {
            state = .loading
           
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                guard let self = self else { return }

                if let firebaseUser {
                    self.user = AuthUser(
                        uid: firebaseUser.uid,
                        name: firebaseUser.displayName,
                        email: firebaseUser.email,
                        photoURL: firebaseUser.photoURL,
                        creationDate: firebaseUser.metadata.creationDate
                    )
                    self.state = .authenticated
                   
                    let admins: Set<String> = [
                        "fernandobatistacruz@gmail.com",
                        "chelle.castro@gmail.com",
                        "kleciobrunno@gmail.com"                        
                    ]

                    let email = firebaseUser.email?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased() ?? ""

                    isAdmin = admins.contains(email)
                    
                } else {
                    self.user = nil
                    self.state = .unauthenticated
                }
            }
        }

    deinit {
        if let handle = authListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Apple

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        appleService.prepare(request)
    }

    func handleAppleResult(_ authorization: ASAuthorization) async {
        do {
            let credential = try await appleService.signIn(authorization: authorization)
            AnalyticsService.shared.loginAttempt(method: .apple)
            
            try await signInOrLink(credential)
            
            AnalyticsService.shared.loginSuccess(method: .apple)
        } catch {
            AnalyticsService.shared.loginError(
                        method: .apple,
                        code: error.localizedDescription.count
                    )
            handle(error)
        }
    }

    // MARK: - Google

    func signInWithGoogle() async {
        AnalyticsService.shared.loginAttempt(method: .google)
        do {
            let credential = try await googleService.signIn()
            try await signInOrLink(credential)
            AnalyticsService.shared.loginSuccess(method: .google)
        } catch {
            AnalyticsService.shared.loginError(
                method: .google,
                        code: error.localizedDescription.count
                    )
            handle(error)
        }
    }

    // MARK: - Core logic

    private func signInOrLink(_ credential: AuthCredential) async throws {
        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            try await handleLinkingIfNeeded(error, credential)
        }
    }

    private func handleLinkingIfNeeded(
        _ error: Error,
        _ credential: AuthCredential
    ) async throws {

        let nsError = error as NSError

        guard nsError.code == AuthErrorCode.credentialAlreadyInUse.rawValue else {
            throw error
        }

        // Guarda a credential para link posterior
        pendingLinkCredential = credential

        // Não tenta descobrir provider (deprecated)
        throw AuthError.credentialInUse
    }


    func linkPendingCredential() async {
        guard
            let credential = pendingLinkCredential,
            let user = Auth.auth().currentUser
        else { return }

        do {
            try await user.link(with: credential)
            pendingLinkCredential = nil
        } catch {
            handle(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        self.user = nil
        self.state = .unauthenticated
        AnalyticsService.shared.logout()
    }


    private func handle(_ error: Error) {
        if let authError = error as? AuthError {
            self.error = authError
        } else {
            self.error = .generic(error.localizedDescription)
        }
    }
   
    // Login com email
    func signInWithEmail() async {
        errorMessage = nil
        infoMessage = nil
        state = .loading
        
        AnalyticsService.shared.loginAttempt(method: .email)
        
        do {
            let result = try await Auth.auth()
                .signIn(withEmail: email, password: password)
            
            
            // 🔒 Verificação de e-mail
            guard result.user.isEmailVerified else {
                infoMessage = "Verifique seu e-mail para ativar sua conta."
                try Auth.auth().signOut()
                state = .unauthenticated
                return
            }
                                    
            // ✅ Login OK
            updateUser(result.user)
            state = .authenticated
            AnalyticsService.shared.loginSuccess(method: .email)
            
        } catch let authError as NSError {
            state = .unauthenticated
            
            AnalyticsService.shared.loginError(
                method: .email,
                code: authError.code
            )
            
            switch authError.code {
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "Usuário não encontrado. Crie uma conta."
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Senha incorreta."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "E-mail inválido."
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "Esta conta foi desativada."
            default:
                errorMessage = authError.localizedDescription
            }
        }
    }


    // Cadastro de novos usuários
    func registerWithEmail(name: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Atualiza displayName
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Limpa mensagens
            self.errorMessage = nil
            self.infoMessage = "Conta criada! Verifique seu e-mail para ativar a conta."
            
            AnalyticsService.shared.signUpCompleted(method: .email)
            
            // Envia e-mail de verificação
            try await result.user.sendEmailVerification()
            
        } catch let authError as NSError {
            switch authError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                self.errorMessage = "Este e-mail já está registrado. Tente fazer login."
            case AuthErrorCode.invalidEmail.rawValue:
                self.errorMessage = "E-mail inválido."
            case AuthErrorCode.weakPassword.rawValue:
                self.errorMessage = "Senha muito fraca. Use pelo menos 6 caracteres."
            default:
                self.errorMessage = authError.localizedDescription
            }
        }
    }

    // Atualiza usuário e estado
    private func updateUser(_ firebaseUser: User) {
        self.user = AuthUser(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName,
            email: firebaseUser.email,
            photoURL: firebaseUser.photoURL,
            creationDate: firebaseUser.metadata.creationDate
        )
        self.state = .authenticated
    }    
  
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Informe seu e-mail."
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = nil
            infoMessage = "Se houver uma conta, enviaremos as instruções por e-mail."
            AnalyticsService.shared.passwordResetRequested()
        } catch let authError as NSError {
            switch authError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "E-mail inválido."
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "Nenhuma conta encontrada com esse e-mail."
            default:
                errorMessage = authError.localizedDescription
            }
        }
    }
    
    func removerConta() async {
        guard let user = Auth.auth().currentUser else {
            infoMessage = "Nenhum usuário logado."
            return
        }

        do {
            // 1️⃣ Apaga o usuário no Firebase Auth
            try await user.delete()
            
            // Analytics opcional
            AnalyticsService.shared.accountDeleted()

            // 2️⃣ Apagar banco local
            try AppDatabase.shared.deleteDatabase()

            // 3️⃣ Limpar preferências locais
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
            }

            // 4️⃣ Informar o usuário que a conta foi removida
            self.infoMessage = "Conta removida com sucesso."

        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                self.errorMessage = "Para remover a conta, faça login novamente."
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
