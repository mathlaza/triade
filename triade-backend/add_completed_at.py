# add_completed_at.py
import sqlite3
from datetime import datetime

def migrate():
    """Adiciona coluna completed_at na tabela tasks"""
    conn = sqlite3.connect('triade.db')
    cursor = conn.cursor()
    
    try:
        # 1. Adicionar coluna
        cursor.execute('ALTER TABLE tasks ADD COLUMN completed_at TIMESTAMP NULL')
        print("✅ Coluna 'completed_at' adicionada com sucesso")
        
        # 2. Popular com dados históricos (tarefas DONE recebem updated_at como completed_at)
        cursor.execute('''
            UPDATE tasks 
            SET completed_at = updated_at 
            WHERE status = 'DONE'
        ''')
        
        affected = cursor.rowcount
        print(f"✅ {affected} tarefas DONE receberam completed_at retroativo")
        
        conn.commit()
        print("✅ Migration concluída!")
        
    except sqlite3.OperationalError as e:
        if 'duplicate column name' in str(e):
            print("⚠️ Coluna 'completed_at' já existe. Nada a fazer.")
        else:
            raise
    finally:
        conn.close()

if __name__ == '__main__':
    migrate()