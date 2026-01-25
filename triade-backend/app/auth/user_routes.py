"""
User Routes - Rotas de perfil e usuário

Endpoints:
- GET /auth/me - Dados do usuário atual
- PUT /auth/me - Atualizar perfil
- POST /auth/me/photo - Upload de foto
- GET /auth/me/photo - Obter foto
- DELETE /auth/me/photo - Remover foto
- GET /auth/users/<username>/photo - Foto pública de usuário
- PUT /auth/change-password - Alterar senha
"""

from flask import request, jsonify, send_file
import base64
from io import BytesIO

from app import db
from app.auth import auth_bp
from app.auth.decorators import token_required
from app.models import User, get_brazil_time


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_current_user(current_user):
    """Retorna dados do usuário autenticado"""
    return jsonify({'user': current_user.to_dict()}), 200


@auth_bp.route('/me', methods=['PUT'])
@token_required
def update_profile(current_user):
    """Atualiza dados do perfil do usuário"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'Dados não fornecidos'}), 400
    
    if 'personal_name' in data:
        personal_name = data['personal_name'].strip()
        if len(personal_name) > 30:
            return jsonify({'error': 'Nome pessoal deve ter no máximo 30 caracteres'}), 400
        if len(personal_name) < 1:
            return jsonify({'error': 'Nome pessoal é obrigatório'}), 400
        current_user.personal_name = personal_name
    
    if 'email' in data:
        email = data['email'].lower().strip()
        
        valid, error = User.validate_email(email)
        if not valid:
            return jsonify({'error': error, 'field': 'email'}), 400
        
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


@auth_bp.route('/me/photo', methods=['POST'])
@token_required
def upload_photo(current_user):
    """Upload de foto de perfil"""
    
    if request.content_type and 'application/json' in request.content_type:
        data = request.get_json()
        if not data or 'photo' not in data:
            return jsonify({'error': 'Foto não fornecida'}), 400
        
        try:
            photo_data = data['photo']
            if ',' in photo_data:
                header, encoded = photo_data.split(',', 1)
                mimetype = header.split(':')[1].split(';')[0] if ':' in header else 'image/jpeg'
            else:
                encoded = photo_data
                mimetype = 'image/jpeg'
            
            photo_bytes = base64.b64decode(encoded)
            
            if len(photo_bytes) > 2 * 1024 * 1024:
                return jsonify({'error': 'Foto deve ter no máximo 2MB'}), 400
            
            current_user.profile_photo = photo_bytes
            current_user.profile_photo_mimetype = mimetype
            
        except Exception as e:
            return jsonify({'error': f'Erro ao processar foto: {str(e)}'}), 400
    else:
        if 'photo' not in request.files:
            return jsonify({'error': 'Foto não fornecida'}), 400
        
        file = request.files['photo']
        if file.filename == '':
            return jsonify({'error': 'Nenhum arquivo selecionado'}), 400
        
        allowed = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
        if file.content_type not in allowed:
            return jsonify({'error': 'Tipo de arquivo não permitido. Use JPEG, PNG, GIF ou WebP'}), 400
        
        photo_bytes = file.read()
        
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
    
    if not current_user.check_password(current_password):
        return jsonify({'error': 'Senha atual incorreta'}), 401
    
    valid, error = User.validate_password(new_password)
    if not valid:
        return jsonify({'error': error}), 400
    
    current_user.set_password(new_password)
    current_user.updated_at = get_brazil_time()
    db.session.commit()
    
    return jsonify({'message': 'Senha alterada com sucesso'}), 200
