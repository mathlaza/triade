"""
Health Routes - Health check e utilitários de debug

Endpoints:
- GET /health - Verificar status da API
- POST /test/midnight-job - Testar job de meia-noite (debug)
"""

from flask import jsonify
from app.routes import api_bp
from app.models import get_brazil_time


@api_bp.route('/health', methods=['GET'])
def health_check():
    """Verifica se API está online"""
    return jsonify({
        'status': 'online',
        'message': 'API Tríade do Tempo rodando',
        'timestamp': get_brazil_time().isoformat()
    }), 200


@api_bp.route('/test/midnight-job', methods=['POST'])
def test_midnight_job():
    """APENAS TESTE - Remove em produção"""
    from app.scheduler import midnight_job
    from flask import current_app

    with current_app.app_context():
        midnight_job()

    return jsonify({'message': 'Job de meia-noite executado com sucesso'}), 200
