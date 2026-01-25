"""
Script para resetar o banco de dados completamente.
ATENÇÃO: Este script APAGA TODOS OS DADOS do banco!

Uso:
    python reset_database.py

Para confirmar sem prompt interativo:
    python reset_database.py --force
"""

import os
import sys
import shutil

def reset_database(force=False):
    """Reseta o banco de dados completamente"""
    
    # Caminho do banco de dados
    instance_path = os.path.join(os.path.dirname(__file__), 'instance')
    db_path = os.path.join(instance_path, 'triade.db')
    
    print("=" * 60)
    print("🚨 ATENÇÃO: RESET COMPLETO DO BANCO DE DADOS 🚨")
    print("=" * 60)
    print()
    
    if os.path.exists(db_path):
        print(f"📁 Banco encontrado em: {db_path}")
        
        # Verificar tamanho do arquivo
        size_kb = os.path.getsize(db_path) / 1024
        print(f"📊 Tamanho atual: {size_kb:.2f} KB")
    else:
        print("ℹ️  Banco de dados não existe ainda.")
    
    print()
    
    if not force:
        print("⚠️  Esta ação irá APAGAR PERMANENTEMENTE:")
        print("   - Todos os usuários")
        print("   - Todas as tarefas")
        print("   - Todas as configurações diárias")
        print("   - Todo o histórico")
        print()
        confirm = input("Digite 'CONFIRMAR' para prosseguir: ")
        
        if confirm != 'CONFIRMAR':
            print("\n❌ Operação cancelada.")
            return False
    
    print()
    print("🔄 Resetando banco de dados...")
    
    # Remover banco existente
    if os.path.exists(db_path):
        try:
            os.remove(db_path)
            print("✅ Banco de dados antigo removido")
        except Exception as e:
            print(f"❌ Erro ao remover banco: {e}")
            return False
    
    # Criar novo banco
    try:
        from app import create_app, db
        from app.models import User, Task, DailyConfig, EnergyLevel, TaskStatus
        
        app = create_app()
        
        with app.app_context():
            # Criar todas as tabelas
            db.create_all()
            print("✅ Novas tabelas criadas")
            
            # Opcional: Criar usuário admin padrão
            create_admin = input("\nDeseja criar um usuário admin padrão? (s/n): ").lower()
            
            if create_admin == 's':
                admin = User(
                    username='admin',
                    personal_name='Administrador',
                    email='admin@triade.app'
                )
                admin.set_password('Admin@123')
                db.session.add(admin)
                db.session.commit()
                print("✅ Usuário admin criado:")
                print("   Username: admin")
                print("   Email: admin@triade.app")
                print("   Senha: Admin@123")
            
            print()
            print("=" * 60)
            print("✅ BANCO DE DADOS RESETADO COM SUCESSO!")
            print("=" * 60)
            
        return True
        
    except Exception as e:
        print(f"❌ Erro ao criar novo banco: {e}")
        return False


if __name__ == '__main__':
    force = '--force' in sys.argv
    reset_database(force)
