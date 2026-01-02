from datetime import datetime, date
from app import db
from app.models import Task, DailyConfig, TaskStatus

def calculate_used_hours(target_date):
    """Calcula horas ocupadas em um dia específico"""
    tasks = Task.query.filter(
        Task.date_scheduled == target_date,
        Task.status == TaskStatus.ACTIVE
    ).all()

    total_minutes = sum(task.duration_minutes for task in tasks)
    return round(total_minutes / 60, 2)

def get_available_hours(target_date):
    """Retorna horas disponíveis do dia (padrão 8h se não configurado)"""
    config = DailyConfig.query.filter_by(date=target_date).first()
    return config.available_hours if config else 8.0

def validate_timebox(target_date, new_duration_minutes):
    """Valida se adicionar nova tarefa estoura o dia"""
    used_hours = calculate_used_hours(target_date)
    available_hours = get_available_hours(target_date)

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

def get_triad_order_value(category):
    """Define ordem de prioridade: Urgente > Importante > Circunstancial"""
    order = {
        'URGENT': 1,
        'IMPORTANT': 2,
        'CIRCUMSTANTIAL': 3
    }
    return order.get(category.value if hasattr(category, 'value') else category, 999)
