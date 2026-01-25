from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from config import Config

db = SQLAlchemy()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Habilitar CORS para Flutter
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Inicializar banco
    db.init_app(app)

    # Registrar rotas principais
    from app.routes import api_bp
    app.register_blueprint(api_bp)
    
    # Registrar rotas de autenticação
    from app.auth import auth_bp
    app.register_blueprint(auth_bp)

    # Criar tabelas
    with app.app_context():
        db.create_all()

    return app
