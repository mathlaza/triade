"""
Módulo de Autenticação - JWT Auth para Tríade
"""

from flask import Blueprint, request, jsonify, current_app, send_file
from functools import wraps
from datetime import datetime, timedelta
import jwt
import base64
from io import BytesIO

from app import db
from app.models import User, get_brazil_time

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

# ==================== HELPERS ====================

def generate_tokens(user):
    """Gera access token e refresh token para o usuário"""
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


# ==================== DECORADOR DE AUTENTICAÇÃO ====================

def token_required(f):
    """Decorador para proteger rotas que requerem autenticação"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Verificar header Authorization
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
        
        # Buscar usuário
        user = User.query.get(payload['user_id'])
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 401
        
        # Passar usuário para a função
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


# ==================== ROTAS DE AUTENTICAÇÃO ====================

@auth_bp.route('/register', methods=['POST'])
def register():
    """Registrar novo usuário"""
    data = request.get_json()
    
    # Campos obrigatórios
    required = ['username', 'personal_name', 'email', 'password']
    for field in required:
        if field not in data or not data[field]:
            return jsonify({'error': f'Campo obrigatório: {field}'}), 400
    
    username = data['username'].lower().strip()
    personal_name = data['personal_name'].strip()
    email = data['email'].lower().strip()
    password = data['password']
    
    # Validar username
    valid, error = User.validate_username(username)
    if not valid:
        return jsonify({'error': error, 'field': 'username'}), 400
    
    # Validar personal_name
    if len(personal_name) > 30:
        return jsonify({'error': 'Nome pessoal deve ter no máximo 30 caracteres', 'field': 'personal_name'}), 400
    
    # Validar email
    valid, error = User.validate_email(email)
    if not valid:
        return jsonify({'error': error, 'field': 'email'}), 400
    
    # Validar senha
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
    
    # Gerar tokens
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
    
    # Buscar por email ou username
    user = User.query.filter(
        (User.email == login_field) | (User.username == login_field)
    ).first()
    
    if not user or not user.check_password(password):
        return jsonify({'error': 'Credenciais inválidas'}), 401
    
    # Gerar tokens
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
    
    # Gerar novo access token
    access_token, new_refresh_token = generate_tokens(user)
    
    return jsonify({
        'access_token': access_token,
        'refresh_token': new_refresh_token
    }), 200


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_current_user(current_user):
    """Retorna dados do usuário autenticado"""
    return jsonify({'user': current_user.to_dict()}), 200


@auth_bp.route('/me', methods=['PUT'])
@token_required
def update_current_user(current_user):
    """Atualiza dados do usuário autenticado"""
    data = request.get_json()
    
    if 'personal_name' in data:
        personal_name = data['personal_name'].strip()
        if len(personal_name) > 30:
            return jsonify({'error': 'Nome pessoal deve ter no máximo 30 caracteres'}), 400
        current_user.personal_name = personal_name
    
    if 'email' in data:
        email = data['email'].lower().strip()
        valid, error = User.validate_email(email)
        if not valid:
            return jsonify({'error': error}), 400
        
        existing = User.query.filter(User.email == email, User.id != current_user.id).first()
        if existing:
            return jsonify({'error': 'Email já está em uso'}), 409
        
        current_user.email = email
    
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({
        'message': 'Dados atualizados com sucesso',
        'user': current_user.to_dict()
    }), 200


# ==================== FOTO DE PERFIL ====================

@auth_bp.route('/me/photo', methods=['POST'])
@token_required
def upload_photo(current_user):
    """Upload de foto de perfil"""
    
    # Verificar se é JSON com base64 ou multipart/form-data
    if request.content_type and 'application/json' in request.content_type:
        # Upload via base64
        data = request.get_json()
        if not data or 'photo' not in data:
            return jsonify({'error': 'Foto não fornecida'}), 400
        
        try:
            # Formato esperado: "data:image/jpeg;base64,/9j/4AAQ..."
            photo_data = data['photo']
            if ',' in photo_data:
                header, encoded = photo_data.split(',', 1)
                mimetype = header.split(':')[1].split(';')[0] if ':' in header else 'image/jpeg'
            else:
                encoded = photo_data
                mimetype = 'image/jpeg'
            
            photo_bytes = base64.b64decode(encoded)
            
            # Verificar tamanho (2MB)
            if len(photo_bytes) > 2 * 1024 * 1024:
                return jsonify({'error': 'Foto deve ter no máximo 2MB'}), 400
            
            current_user.profile_photo = photo_bytes
            current_user.profile_photo_mimetype = mimetype
            
        except Exception as e:
            return jsonify({'error': f'Erro ao processar foto: {str(e)}'}), 400
    else:
        # Upload via multipart/form-data
        if 'photo' not in request.files:
            return jsonify({'error': 'Foto não fornecida'}), 400
        
        file = request.files['photo']
        if file.filename == '':
            return jsonify({'error': 'Nenhum arquivo selecionado'}), 400
        
        # Verificar tipo
        allowed = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
        if file.content_type not in allowed:
            return jsonify({'error': 'Tipo de arquivo não permitido. Use JPEG, PNG, GIF ou WebP'}), 400
        
        photo_bytes = file.read()
        
        # Verificar tamanho (2MB)
        if len(photo_bytes) > 2 * 1024 * 1024:
            return jsonify({'error': 'Foto deve ter no máximo 2MB'}), 400
        
        current_user.profile_photo = photo_bytes
        current_user.profile_photo_mimetype = file.content_type
    
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({'message': 'Foto atualizada com sucesso'}), 200


@auth_bp.route('/me/photo', methods=['GET'])
@token_required
def get_my_photo(current_user):
    """Retorna foto de perfil do usuário autenticado"""
    if not current_user.profile_photo:
        return jsonify({'error': 'Usuário não possui foto de perfil'}), 404
    
    return send_file(
        BytesIO(current_user.profile_photo),
        mimetype=current_user.profile_photo_mimetype or 'image/jpeg'
    )


@auth_bp.route('/me/photo', methods=['DELETE'])
@token_required
def delete_photo(current_user):
    """Remove foto de perfil"""
    current_user.profile_photo = None
    current_user.profile_photo_mimetype = None
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({'message': 'Foto removida com sucesso'}), 200


@auth_bp.route('/users/<username>/photo', methods=['GET'])
def get_user_photo(username):
    """Retorna foto de perfil de um usuário público"""
    user = User.query.filter_by(username=username.lower()).first()
    
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404
    
    if not user.profile_photo:
        return jsonify({'error': 'Usuário não possui foto de perfil'}), 404
    
    return send_file(
        BytesIO(user.profile_photo),
        mimetype=user.profile_photo_mimetype or 'image/jpeg'
    )


# ==================== VERIFICAÇÃO ====================

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


# ==================== EDITAR PERFIL ====================

@auth_bp.route('/me', methods=['PUT'])
@token_required
def update_profile(current_user):
    """Atualiza dados do perfil do usuário"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400
    
    # Atualizar nome pessoal
    if 'personal_name' in data:
        personal_name = data['personal_name'].strip()
        if len(personal_name) > 30:
            return jsonify({'error': 'Nome pessoal deve ter no máximo 30 caracteres'}), 400
        if len(personal_name) < 1:
            return jsonify({'error': 'Nome pessoal é obrigatório'}), 400
        current_user.personal_name = personal_name
    
    # Atualizar email
    if 'email' in data:
        email = data['email'].lower().strip()
        
        # Validar formato
        valid, error = User.validate_email(email)
        if not valid:
            return jsonify({'error': error, 'field': 'email'}), 400
        
        # Verificar se email já está em uso por outro usuário
        existing = User.query.filter(
            User.email == email,
            User.id != current_user.id
        ).first()
        if existing:
            return jsonify({'error': 'Email já está em uso', 'field': 'email'}), 409
        
        current_user.email = email
    
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({
        'message': 'Perfil atualizado com sucesso',
        'user': current_user.to_dict()
    }), 200


# ==================== ALTERAR SENHA ====================

@auth_bp.route('/change-password', methods=['PUT'])
@token_required
def change_password(current_user):
    """Altera a senha do usuário"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400
    
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'error': 'Senha atual e nova senha são obrigatórias'}), 400
    
    # Verificar senha atual
    if not current_user.check_password(current_password):
        return jsonify({'error': 'Senha atual incorreta'}), 401
    
    # Validar nova senha
    valid, error = User.validate_password(new_password)
    if not valid:
        return jsonify({'error': error}), 400
    
    # Atualizar senha
    current_user.set_password(new_password)
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({'message': 'Senha alterada com sucesso'}), 200


# ==================== RECUPERAR SENHA ====================

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Solicita recuperação de senha por email"""
    data = request.get_json()
    
    if not data or 'email' not in data:
        return jsonify({'error': 'Email é obrigatório'}), 400
    
    email = data['email'].lower().strip()
    user = User.query.filter_by(email=email).first()
    
    # Sempre retorna sucesso para não revelar se o email existe
    # Em produção, aqui você enviaria o email real
    if user:
        # TODO: Implementar envio de email real
        # Por enquanto, apenas loga no servidor
        import secrets
        reset_token = secrets.token_urlsafe(32)
        print(f"[PASSWORD RESET] Token para {email}: {reset_token}")
        
        # Em produção, salvar o token no banco e enviar por email
        # user.reset_token = reset_token
        # user.reset_token_expires = datetime.utcnow() + timedelta(hours=1)
        # db.session.commit()
        # send_email(email, reset_token)
    
    return jsonify({
        'message': 'Se o email estiver cadastrado, você receberá um link de recuperação'
    }), 200
