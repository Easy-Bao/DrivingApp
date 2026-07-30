import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:session_service/src/features/session/data/datasources/secure_session_datasource.dart';
import 'package:session_service/src/features/session/presentation/bloc/auth_event.dart';
import 'package:session_service/src/features/session/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SecureSessionService _secureSessionService;

  AuthBloc({required SecureSessionService secureSessionService})
      : _secureSessionService = secureSessionService,
        super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _secureSessionService.readAuthToken();
    final passengerId = await _secureSessionService.readPassengerId();
    final driverId = await _secureSessionService.readDriverId();
    final userId = (passengerId != null && passengerId.isNotEmpty)
        ? passengerId
        : (driverId ?? '');

    if (token != null && token.isNotEmpty && userId.isNotEmpty) {
      emit(AuthState.authenticated(token: token, userId: userId));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthLoggedIn(
    AuthLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    await _secureSessionService.writeAuthToken(event.token);
    emit(AuthState.authenticated(token: event.token, userId: event.userId));
  }

  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _secureSessionService.clearSession();
    emit(const AuthState.unauthenticated());
  }
}
