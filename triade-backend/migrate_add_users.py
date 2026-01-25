"""
Script de Migração - Adiciona suporte a múltiplos usuários
Executa as seguintes ações:
1. Cria a tabela 'users' se não existir
2. Adiciona coluna 'user_id' nas tabelas tasks, daily_configs e task_completions
3. Cria o usuário @matheus com senha padrão
4. Atribui todas as tarefas existentes ao @matheus
"""

import os
import sys
from datetime import datetime

# Adiciona o diretório raiz ao path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models import User, Task, DailyConfig, TaskCompletion
from sqlalchemy import text, inspect

def run_migration():
    """Executa a migração para adicionar suporte a usuários"""
    app = create_app()
    
    with app.app_context():
        inspector = inspect(db.engine)
        
        print("=" * 60)
        print("🚀 Iniciando migração para suporte multi-usuário")
        print("=" * 60)
        
        # =====================================================
        # 1. CRIAR TABELA USERS (se não existir)
        # =====================================================
        if 'users' not in inspector.get_table_names():
            print("\n📌 Criando tabela 'users'...")
            db.create_all()
            print("   ✅ Tabela 'users' criada!")
        else:
            print("\n📌 Tabela 'users' já existe, pulando...")
        
        # =====================================================
        # 2. CRIAR USUÁRIO @matheus (se não existir)
        # =====================================================
        print("\n📌 Verificando usuário @matheus...")
        
        matheus = User.query.filter_by(username='matheus').first()
        
        if not matheus:
            print("   Criando usuário @matheus...")
            matheus = User(
                username='matheus',
                personal_name='Matheus Lazaro',
                email='matheusmml@gmail.com'
            )
            # Senha padrão - MUDE APÓS A MIGRAÇÃO!
            matheus.set_password('Triade@2024')
            db.session.add(matheus)
            db.session.commit()
            print("   ✅ Usuário @matheus criado!")
            print("   ⚠️  IMPORTANTE: Altere a senha padrão 'Triade@2024' após o primeiro login!")
        else:
            print("   ✅ Usuário @matheus já existe (ID: {})".format(matheus.id))
        
        matheus_id = matheus.id
        
        # =====================================================
        # 3. ADICIONAR COLUNA user_id NAS TABELAS (se necessário)
        # =====================================================
        
        # Verificar e adicionar user_id em tasks
        print("\n📌 Verificando coluna user_id em 'tasks'...")
        tasks_columns = [col['name'] for col in inspector.get_columns('tasks')]
        
        if 'user_id' not in tasks_columns:
            print("   Adicionando coluna user_id...")
            try:
                db.session.execute(text('ALTER TABLE tasks ADD COLUMN user_id INTEGER REFERENCES users(id)'))
                db.session.commit()
                print("   ✅ Coluna user_id adicionada em 'tasks'!")
            except Exception as e:
                print(f"   ⚠️  Erro ao adicionar coluna (pode já existir): {e}")
                db.session.rollback()
        else:
            print("   ✅ Coluna user_id já existe em 'tasks'")
        
        # Verificar e adicionar user_id em daily_configs
        print("\n📌 Verificando coluna user_id em 'daily_configs'...")
        if 'daily_configs' in inspector.get_table_names():
            config_columns = [col['name'] for col in inspector.get_columns('daily_configs')]
            
            if 'user_id' not in config_columns:
                print("   Adicionando coluna user_id...")
                try:
                    db.session.execute(text('ALTER TABLE daily_configs ADD COLUMN user_id INTEGER REFERENCES users(id)'))
                    db.session.commit()
                    print("   ✅ Coluna user_id adicionada em 'daily_configs'!")
                except Exception as e:
                    print(f"   ⚠️  Erro ao adicionar coluna: {e}")
                    db.session.rollback()
            else:
                print("   ✅ Coluna user_id já existe em 'daily_configs'")
        
        # Verificar e adicionar user_id em task_completions
        print("\n📌 Verificando coluna user_id em 'task_completions'...")
        if 'task_completions' in inspector.get_table_names():
            completions_columns = [col['name'] for col in inspector.get_columns('task_completions')]
            
            if 'user_id' not in completions_columns:
                print("   Adicionando coluna user_id...")
                try:
                    db.session.execute(text('ALTER TABLE task_completions ADD COLUMN user_id INTEGER REFERENCES users(id)'))
                    db.session.commit()
                    print("   ✅ Coluna user_id adicionada em 'task_completions'!")
                except Exception as e:
                    print(f"   ⚠️  Erro ao adicionar coluna: {e}")
                    db.session.rollback()
            else:
                print("   ✅ Coluna user_id já existe em 'task_completions'")
        
        # =====================================================
        # 4. ATRIBUIR DADOS EXISTENTES AO @matheus
        # =====================================================
        
        print("\n📌 Atribuindo dados existentes ao @matheus...")
        
        # Atualizar tasks
        tasks_updated = db.session.execute(
            text('UPDATE tasks SET user_id = :user_id WHERE user_id IS NULL'),
            {'user_id': matheus_id}
        )
        print(f"   ✅ {tasks_updated.rowcount} tarefas atribuídas ao @matheus")
        
        # Atualizar daily_configs
        if 'daily_configs' in inspector.get_table_names():
            configs_updated = db.session.execute(
                text('UPDATE daily_configs SET user_id = :user_id WHERE user_id IS NULL'),
                {'user_id': matheus_id}
            )
            print(f"   ✅ {configs_updated.rowcount} configurações diárias atribuídas ao @matheus")
        
        # Atualizar task_completions
        if 'task_completions' in inspector.get_table_names():
            completions_updated = db.session.execute(
                text('UPDATE task_completions SET user_id = :user_id WHERE user_id IS NULL'),
                {'user_id': matheus_id}
            )
            print(f"   ✅ {completions_updated.rowcount} conclusões de tarefas atribuídas ao @matheus")
        
        db.session.commit()
        
        # =====================================================
        # 5. SUMÁRIO
        # =====================================================
        print("\n" + "=" * 60)
        print("✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!")
        print("=" * 60)
        print(f"\n📊 Resumo:")
        print(f"   • Usuário criado: @matheus (ID: {matheus_id})")
        print(f"   • Email: matheusmml@gmail.com")
        print(f"   • Senha padrão: Triade@2024")
        print(f"\n⚠️  AÇÕES NECESSÁRIAS:")
        print(f"   1. Altere a senha padrão após o primeiro login")
        print(f"   2. Teste o login com email ou username")
        print(f"   3. Verifique se todas as tarefas aparecem corretamente")
        print("")


if __name__ == '__main__':
    run_migration()
