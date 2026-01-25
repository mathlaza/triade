"""
Routes Package - Tríade do Tempo API

Organização modular das rotas por domínio:
- tasks: CRUD de tarefas, daily, weekly
- dashboard: Estatísticas e insights
- config: Configurações diárias
- backup: Backup e restauração
- health: Health check e utilitários
"""

from flask import Blueprint

# Blueprint principal da API
api_bp = Blueprint('api', __name__)

# Importar e registrar rotas de cada módulo
from app.routes import tasks
from app.routes import dashboard
from app.routes import config
from app.routes import backup
from app.routes import health
