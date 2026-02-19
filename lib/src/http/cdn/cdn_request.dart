import 'package:http/http.dart';

import 'package:penyxx/src/client.dart';
import 'package:penyxx/src/http/request.dart';

/// A request to Discord's CDN.
class CdnRequest extends HttpRequest {
  /// Create a new [CdnRequest].
  CdnRequest(super.route, {super.queryParameters}) : super(method: 'GET', authenticated: false, applyGlobalRateLimit: false);

  @override
  BaseRequest prepare(Nyxx client) {
    final queryParameters = this.queryParameters.isEmpty ? null : this.queryParameters;

    return Request(method, Uri.https(client.apiOptions.cdnHost, route.path, queryParameters));
  }
}
