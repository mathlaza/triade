"""
Auth Package - Autenticação JWT para Tríade

Organização:
- decorators: token_required, token_optional
- helpers: generate_tokens, decode_token
- routes: login, register, refresh
- user_routes: perfil, foto, senha
"""

from flask import Blueprint

# Blueprint de autenticação
auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

# Importar decorators para exposição no pacote
from app.auth.decorators import token_required, token_optional

# Importar rotas para registro
from app.auth import routes
from app.auth import user_routes
