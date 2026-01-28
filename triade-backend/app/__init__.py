import sentry_sdk
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from config import Config

# Inicializa Sentry ANTES de criar o app Flask
sentry_sdk.init(
    dsn="https://dc902bd6d7c301886ce9622e03fd9e09@o4510784716603392.ingest.us.sentry.io/4510784801865728",
    send_default_pii=True,
    traces_sample_rate=1.0,
)

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
