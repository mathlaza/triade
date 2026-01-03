from app import create_app, db
from app.scheduler import init_scheduler
import os

app = create_app()

# Inicializar scheduler
init_scheduler(app)

if __name__ == '__main__':
    with app.app_context():
        # O Flask guarda o caminho da pasta instance aqui: app.instance_path
        db_path = os.path.join(app.instance_path, 'triade.db')

        # Agora verificamos no lugar certo
        if not os.path.exists(db_path):
            db.create_all()
            print(f"✅ Banco de dados criado em: {db_path}")
        else:
            print(f"✅ Banco de dados existente carregado de: {db_path}")

    print("🚀 API rodando em http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
