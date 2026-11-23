/// Endereço do relé de push gratuito (Cloudflare Worker em worker/).
///
/// Depois do deploy, cole aqui a URL, por exemplo:
/// 'https://conviva-push.SEU-USUARIO.workers.dev'
/// Deixe vazio para desligar o envio de push (o app continua funcionando).
class PushRelayConfig {
  PushRelayConfig._();

  static const String url = 'https://conviva-push.conviva-app.workers.dev';
}
