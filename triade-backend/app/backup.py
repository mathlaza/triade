# app/backup.py
import os
import shutil
from datetime import datetime
from pathlib import Path
from app import db

def backup_database():
    """
    Cria backup do banco de dados SQLite.
    Retorna o caminho do arquivo de backup criado.
    """
    # Caminho do banco original
    db_path = Path('instance/triade.db')
    
    # Verificar se o banco existe
    if not db_path.exists():
        raise FileNotFoundError('Banco de dados triade.db não encontrado')
    
    # Criar pasta de backups se não existir
    backup_dir = Path('backups')
    backup_dir.mkdir(exist_ok=True)
    
    # Nome do arquivo com timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f'triade_{timestamp}.db'
    backup_path = backup_dir / backup_filename
    
    # Copiar arquivo
    shutil.copy2(db_path, backup_path)
    
    # Limpar backups antigos (manter apenas os 10 mais recentes)
    _cleanup_old_backups(backup_dir, keep=10)
    
    return str(backup_path)

def _cleanup_old_backups(backup_dir, keep=10):
    """Remove backups antigos, mantendo apenas os N mais recentes"""
    backup_files = sorted(
        backup_dir.glob('triade_*.db'),
        key=lambda x: x.stat().st_mtime,
        reverse=True
    )
    
    # Remover arquivos além do limite
    for old_backup in backup_files[keep:]:
        old_backup.unlink()




def restore_backup(backup_filename):
    """
    Restaura um backup específico.
    Tenta fechar conexões antes de sobrescrever.
    """
    # Caminho base do projeto (ajuste se necessário, mas geralmente o root é o cwd)
    base_path = Path.cwd()

    backup_path = base_path / 'backups' / backup_filename

    # CORREÇÃO 1: O banco geralmente fica dentro de 'instance' no Flask moderno
    # Se o seu estiver na raiz, mude para base_path / 'triade.db'
    current_db = base_path / 'instance' / 'triade.db' 

    if not backup_path.exists():
        raise FileNotFoundError(f'Backup {backup_filename} não encontrado')

    # --- O TRUQUE PARA O WINDOWS ---
    # 1. Remove a sessão atual (rollback em transações pendentes)
    db.session.remove()
    # 2. Descarta o pool de conexões. Isso deve liberar o arquivo no SO.
    db.engine.dispose()
    # -------------------------------

    # Fazer backup de segurança do banco atual (Emergency Backup)
    emergency_backup_name = None
    if current_db.exists():
        emergency_backup_name = f'pre_restore_{datetime.now().strftime("%Y%m%d_%H%M%S")}.db'
        emergency_backup_path = base_path / 'backups' / emergency_backup_name

        try:
            shutil.copy2(current_db, emergency_backup_path)
        except PermissionError:
            # Se ainda der erro aqui, é porque algo externo (DB Browser, VS Code) está segurando o arquivo
            return {
                'error': 'O arquivo do banco está travado. Feche visualizadores de DB ou reinicie o servidor.',
                'success': False
            }

    # Restaurar (sobrescreve o triade.db atual)
    try:
        shutil.copy2(backup_path, current_db)
    except OSError as e:
        return {
            'error': f'Falha ao sobrescrever o arquivo: {str(e)}. O Windows bloqueou o arquivo.',
            'success': False
        }

    return {
        'restored_backup': backup_filename,
        'safety_backup': emergency_backup_name,
        'message': f'Banco restaurado de {backup_filename}',
        'warning': 'Recomendado reiniciar o servidor para garantir integridade total.',
        'success': True
    }

def list_backups():
    """Lista todos os backups disponíveis"""
    backup_dir = Path('backups')
    
    if not backup_dir.exists():
        return []
    
    backups = []
    for backup_file in sorted(backup_dir.glob('triade_*.db'), reverse=True):
        stat = backup_file.stat()
        backups.append({
            'filename': backup_file.name,
            'size_mb': round(stat.st_size / (1024 * 1024), 2),
            'created_at': datetime.fromtimestamp(stat.st_mtime).isoformat()
        })
    
    return backups