"""
Backup Routes - Backup e restauração do banco de dados

Endpoints:
- POST /backup/create - Criar backup
- GET /backup/list - Listar backups
- POST /backup/restore - Restaurar backup
"""

from flask import request, jsonify
from app.routes import api_bp
from app.backup import backup_database, restore_backup, list_backups


@api_bp.route('/backup/create', methods=['POST'])
def create_backup():
    """Criar backup manual do banco de dados"""
    try:
        backup_path = backup_database()
        return jsonify({
            'message': 'Backup criado com sucesso',
            'backup_file': backup_path
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api_bp.route('/backup/list', methods=['GET'])
def list_available_backups():
    """Listar backups disponíveis"""
    try:
        backups = list_backups()
        return jsonify({
            'total': len(backups),
            'backups': backups
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api_bp.route('/backup/restore', methods=['POST'])
def restore_from_backup():
    """Restaurar banco de um backup específico"""
    data = request.get_json()
    
    if 'filename' not in data:
        return jsonify({'error': 'Campo filename obrigatório'}), 400
    
    try:
        result = restore_backup(data['filename'])
        return jsonify(result), 200
    except FileNotFoundError as e:
        return jsonify({'error': str(e)}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
