"""
Auth Routes - Rotas de autenticação

Endpoints:
- POST /auth/register - Registrar novo usuário
- POST /auth/login - Login
- POST /auth/refresh - Renovar tokens
- GET /auth/check-username - Verificar disponibilidade
- GET /auth/check-email - Verificar disponibilidade
- POST /auth/forgot-password - Recuperar senha
"""

from flask import request, jsonify

from app import db
from app.auth import auth_bp
from app.auth.decorators import generate_tokens, decode_token
from app.models import User


@auth_bp.route('/register', methods=['POST'])
def register():
    """Registrar novo usuário"""
    data = request.get_json()
    
    required = ['username', 'personal_name', 'email', 'password']
    for field in required:
        if field not in data or not data[field]:
            return jsonify({'error': f'Campo obrigatório: {field}'}), 400
    
    username = data['username'].lower().strip()
    personal_name = data['personal_name'].strip()
    email = data['email'].lower().strip()
    password = data['password']
    
    # Validações
    valid, error = User.validate_username(username)
    if not valid:
        return jsonify({'error': error, 'field': 'username'}), 400
    
    if len(personal_name) > 30:
        return jsonify({'error': 'Nome pessoal deve ter no máximo 30 caracteres', 'field': 'personal_name'}), 400
    
    valid, error = User.validate_email(email)
    if not valid:
        return jsonify({'error': error, 'field': 'email'}), 400
    
    valid, error = User.validate_password(password)
    if not valid:
        return jsonify({'error': error, 'field': 'password'}), 400
    
    # Verificar duplicatas
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username já está em uso', 'field': 'username'}), 409
    
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'Email já está cadastrado', 'field': 'email'}), 409
    
    # Criar usuário
    user = User(
        username=username,
        personal_name=personal_name,
        email=email
    )
    user.set_password(password)
    
    db.session.add(user)
    db.session.commit()
    
    access_token, refresh_token = generate_tokens(user)
    
    return jsonify({
        'message': 'Usuário criado com sucesso',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    }), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login com email/username e senha"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400
    
    login_field = data.get('email') or data.get('username')
    password = data.get('password')
    
    if not login_field or not password:
        return jsonify({'error': 'Email/username e senha são obrigatórios'}), 400
    
    login_field = login_field.lower().strip()
    
    user = User.query.filter(
        (User.email == login_field) | (User.username == login_field)
    ).first()
    
    if not user or not user.check_password(password):
        return jsonify({'error': 'Credenciais inválidas'}), 401
    
    access_token, refresh_token = generate_tokens(user)
    
    return jsonify({
        'message': 'Login realizado com sucesso',
        'user': user.to_dict(),
        'access_token': access_token,
        'refresh_token': refresh_token
    }), 200


@auth_bp.route('/refresh', methods=['POST'])
def refresh():
    """Renovar access token usando refresh token"""
    data = request.get_json()
    refresh_token = data.get('refresh_token')
    
    if not refresh_token:
        return jsonify({'error': 'Refresh token não fornecido'}), 400
    
    payload, error = decode_token(refresh_token)
    if error:
        return jsonify({'error': error}), 401
    
    if payload.get('type') != 'refresh':
        return jsonify({'error': 'Tipo de token inválido'}), 401
    
    user = User.query.get(payload['user_id'])
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 401
    
    access_token, new_refresh_token = generate_tokens(user)
    
    return jsonify({
        'access_token': access_token,
        'refresh_token': new_refresh_token
    }), 200


@auth_bp.route('/check-username/<username>', methods=['GET'])
def check_username(username):
    """Verifica se username está disponível"""
    username = username.lower().strip()
    
    valid, error = User.validate_username(username)
    if not valid:
        return jsonify({'available': False, 'error': error}), 200
    
    exists = User.query.filter_by(username=username).first() is not None
    return jsonify({'available': not exists}), 200


@auth_bp.route('/check-email/<email>', methods=['GET'])
def check_email(email):
    """Verifica se email está disponível"""
    email = email.lower().strip()
    
    valid, error = User.validate_email(email)
    if not valid:
        return jsonify({'available': False, 'error': error}), 200
    
    exists = User.query.filter_by(email=email).first() is not None
    return jsonify({'available': not exists}), 200


@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Solicita recuperação de senha por email"""
    data = request.get_json()
    
    if not data or 'email' not in data:
        return jsonify({'error': 'Email é obrigatório'}), 400
    
    email = data['email'].lower().strip()
    user = User.query.filter_by(email=email).first()
    
    if user:
        import secrets
        reset_token = secrets.token_urlsafe(32)
        print(f"[PASSWORD RESET] Token para {email}: {reset_token}")
    
    return jsonify({
        'message': 'Se o email estiver cadastrado, você receberá um link de recuperação'
    }), 200
