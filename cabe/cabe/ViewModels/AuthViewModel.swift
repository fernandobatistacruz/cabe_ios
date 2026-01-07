//
//  AuthViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//


import FirebaseAuth
internal import Combine
import AuthenticationServices
import GoogleSignIn

@MainActor
final class AuthViewModel: ObservableObject {

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
            try await signInOrLink(credential)
        } catch {
            handle(error)
        }
    }

    // MARK: - Google

    func signInWithGoogle() async {
        do {
            let credential = try await googleService.signIn()
            try await signInOrLink(credential)
        } catch {
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
    }


    private func handle(_ error: Error) {
        if let authError = error as? AuthError {
            self.error = authError
        } else {
            self.error = .generic(error.localizedDescription)
        }
    }
   
    // Login com email
    @MainActor
    func signInWithEmail() async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Verifica se o e-mail está confirmado
            if !result.user.isEmailVerified {
                self.errorMessage = "Por favor, verifique seu e-mail antes de entrar."
                try? Auth.auth().signOut() // impede login sem confirmação
                return
            }
            
            // Atualiza usuário e limpa erro
            updateUser(result.user)
            self.errorMessage = nil
            
        } catch let authError as NSError {
            switch authError.code {
            case AuthErrorCode.userNotFound.rawValue:
                self.errorMessage = "Usuário não encontrado. Crie uma conta."
            case AuthErrorCode.wrongPassword.rawValue:
                self.errorMessage = "Senha incorreta."
            case AuthErrorCode.invalidEmail.rawValue:
                self.errorMessage = "Email inválido."
            default:
                self.errorMessage = authError.localizedDescription
            }
        }
    }


    // Cadastro de novos usuários
    @MainActor
    func registerWithEmail(name: String) async {
        //TODO: Testar o confirmação de e-mail e validar se está deixando logar sem validar a confirmação
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Atualiza displayName
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Limpa mensagens
            self.errorMessage = nil
            self.infoMessage = "Conta criada! Verifique seu e-mail para ativar a conta."
            
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


}
