from datetime import datetime, date
from app import db
from app.models import Task, DailyConfig, TaskStatus

def calculate_used_hours(target_date, user_id=None):
    """Calcula horas ocupadas em um dia específico"""
    query = Task.query.filter(
        Task.date_scheduled == target_date,
        Task.status == TaskStatus.ACTIVE
    )
    if user_id:
        query = query.filter(Task.user_id == user_id)
    
    tasks = query.all()
    total_minutes = sum(task.duration_minutes for task in tasks)
    return round(total_minutes / 60, 2)

def get_available_hours(target_date, user_id=None):
    """Retorna horas disponíveis do dia (padrão 8h se não configurado)"""
    query = DailyConfig.query.filter(DailyConfig.date == target_date)
    if user_id:
        query = query.filter(DailyConfig.user_id == user_id)
    
    config = query.first()
    return config.available_hours if config else 8.0

def validate_timebox(target_date, new_duration_minutes, user_id=None):
    """Valida se adicionar nova tarefa estoura o dia"""
    used_hours = calculate_used_hours(target_date, user_id)
    available_hours = get_available_hours(target_date, user_id)

    new_hours = new_duration_minutes / 60
    total = used_hours + new_hours

    if total > available_hours:
        return False, {
            "error": "Dia estourado. Libere espaço editando ou excluindo tarefas.",
            "available_hours": available_hours,
            "used_hours": used_hours,
            "attempting_to_add": new_hours,
            "would_total": round(total, 2)
        }

    return True, None

def get_energy_level_order_value(level):
    """Define ordem de prioridade: Alta Energia > Renovação > Baixa Energia"""
    order = {
        'HIGH_ENERGY': 1,
        'RENEWAL': 2,
        'LOW_ENERGY': 3
    }
    return order.get(level.value if hasattr(level, 'value') else level, 999)
