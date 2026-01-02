from app import create_app, db
from app.scheduler import init_scheduler

app = create_app()

# Inicializar scheduler
init_scheduler(app)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("✅ Banco de dados inicializado")

    print("🚀 API rodando em http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
