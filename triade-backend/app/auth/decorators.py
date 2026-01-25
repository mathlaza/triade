"""
Auth Decorators e Helpers

Funções auxiliares para autenticação JWT.
"""

from flask import request, jsonify, current_app
from functools import wraps
import jwt

from app.models import User


def generate_tokens(user):
    """Gera access token e refresh token para o usuário"""
    from datetime import datetime
    
    now = datetime.utcnow()
    
    # Access Token (curta duração)
    access_payload = {
        'user_id': user.id,
        'username': user.username,
        'type': 'access',
        'iat': now,
        'exp': now + current_app.config['JWT_ACCESS_TOKEN_EXPIRES']
    }
    access_token = jwt.encode(
        access_payload,
        current_app.config['JWT_SECRET_KEY'],
        algorithm='HS256'
    )
    
    # Refresh Token (longa duração)
    refresh_payload = {
        'user_id': user.id,
        'type': 'refresh',
        'iat': now,
        'exp': now + current_app.config['JWT_REFRESH_TOKEN_EXPIRES']
    }
    refresh_token = jwt.encode(
        refresh_payload,
        current_app.config['JWT_SECRET_KEY'],
        algorithm='HS256'
    )
    
    return access_token, refresh_token


def decode_token(token):
    """Decodifica e valida um token JWT"""
    try:
        payload = jwt.decode(
            token,
            current_app.config['JWT_SECRET_KEY'],
            algorithms=['HS256']
        )
        return payload, None
    except jwt.ExpiredSignatureError:
        return None, 'Token expirado'
    except jwt.InvalidTokenError:
        return None, 'Token inválido'


def token_required(f):
    """Decorador para proteger rotas que requerem autenticação"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == 'bearer':
                token = parts[1]
        
        if not token:
            return jsonify({'error': 'Token de autenticação não fornecido'}), 401
        
        payload, error = decode_token(token)
        if error:
            return jsonify({'error': error}), 401
        
        if payload.get('type') != 'access':
            return jsonify({'error': 'Tipo de token inválido'}), 401
        
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 401
        
        return f(current_user=user, *args, **kwargs)
    
    return decorated


def token_optional(f):
    """Decorador para rotas que podem ou não ter autenticação"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        current_user = None
        
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == 'bearer':
                token = parts[1]
        
        if token:
            payload, error = decode_token(token)
            if not error and payload.get('type') == 'access':
                current_user = User.query.get(payload['user_id'])
        
        return f(current_user=current_user, *args, **kwargs)
    
    return decorated
