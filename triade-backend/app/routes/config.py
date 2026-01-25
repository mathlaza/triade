"""
Config Routes - Configurações diárias

Endpoints:
- GET /config/daily - Obter horas disponíveis do dia
- POST /config/daily - Definir horas disponíveis do dia
"""

from flask import request, jsonify
from datetime import datetime
from app import db
from app.routes import api_bp
from app.models import DailyConfig
from app.auth import token_required


@api_bp.route('/config/daily', methods=['POST'])
@token_required
def set_daily_config(current_user):
    """Criar/atualizar horas disponíveis do dia"""
    data = request.get_json()

    if 'date' not in data or 'available_hours' not in data:
        return jsonify({'error': 'Campos obrigatórios: date, available_hours'}), 400

    try:
        target_date = datetime.strptime(data['date'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date inválido. Use YYYY-MM-DD'}), 400

    config = DailyConfig.query.filter(
        DailyConfig.user_id == current_user.id,
        DailyConfig.date == target_date
    ).first()

    if config:
        config.available_hours = data['available_hours']
    else:
        config = DailyConfig(
            user_id=current_user.id,
            date=target_date,
            available_hours=data['available_hours']
        )
        db.session.add(config)

    db.session.commit()

    return jsonify({
        'message': 'Configuração salva',
        'config': config.to_dict()
    }), 200


@api_bp.route('/config/daily', methods=['GET'])
@token_required
def get_daily_config(current_user):
    """Retornar horas disponíveis do dia"""
    date_str = request.args.get('date')

    if not date_str:
        return jsonify({'error': 'Parâmetro date obrigatório'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date inválido. Use YYYY-MM-DD'}), 400

    config = DailyConfig.query.filter(
        DailyConfig.user_id == current_user.id,
        DailyConfig.date == target_date
    ).first()

    if not config:
        return jsonify({
            'date': date_str,
            'available_hours': 8.0,
            'is_default': True
        }), 200

    return jsonify(config.to_dict()), 200
