import 'dart:async';

class AuthResult {
  final bool authenticated;
  final String authToken;
  AuthResult(this.authenticated, this.authToken);
}

abstract class Authenticator {
  Future<AuthResult> authenticate(String login, String secret);
  Future refreshUsers();
}

class DummyAuthenticator implements Authenticator {
  Future<AuthResult> authenticate(String login, String secret) async =>
      new AuthResult(true, 'SUCCESS');
  Future refreshUsers() async => null;
}
