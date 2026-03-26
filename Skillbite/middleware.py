from django.http import HttpResponse


class LocalDevCorsMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        origin = request.headers.get('Origin', '')
        if request.path.startswith('/api/mobile/v1/') and self._is_allowed_local_origin(origin):
            if request.method == 'OPTIONS':
                response = HttpResponse(status=204)
            else:
                response = self.get_response(request)
            response['Access-Control-Allow-Origin'] = origin
            response['Vary'] = 'Origin'
            response['Access-Control-Allow-Credentials'] = 'true'
            response['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
            response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
            return response
        return self.get_response(request)

    def _is_allowed_local_origin(self, origin: str) -> bool:
        if not origin:
            return False
        allowed_prefixes = (
            'http://localhost:',
            'http://127.0.0.1:',
            'https://localhost:',
            'https://127.0.0.1:',
        )
        return origin.startswith(allowed_prefixes)
