from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, date, timedelta
from app import db
from app.models import Task, TaskStatus

def duplicate_repeatable_tasks():
    """Duplica tarefas repetíveis para o dia seguinte"""
    today = date.today()
    yesterday = today - timedelta(days=1)

    repeatable_tasks = Task.query.filter(
        Task.date_scheduled == yesterday,
        Task.is_repeatable == True,
        Task.status == TaskStatus.DONE
    ).all()

    for task in repeatable_tasks:
        new_task = Task(
            title=task.title,
            triad_category=task.triad_category,
            duration_minutes=task.duration_minutes,
            date_scheduled=today,
            role_tag=task.role_tag,
            context_tag=task.context_tag,
            is_repeatable=True,
            repeat_count=task.repeat_count + 1,
            status=TaskStatus.ACTIVE
        )
        db.session.add(new_task)

    db.session.commit()
    print(f"[SCHEDULER] {len(repeatable_tasks)} tarefas repetíveis duplicadas para {today}")


def mark_pending_review():
    """Marca tarefas ACTIVE do dia anterior como PENDING_REVIEW"""
    yesterday = date.today() - timedelta(days=1)

    tasks = Task.query.filter(
        Task.date_scheduled == yesterday,
        Task.status == TaskStatus.ACTIVE
    ).all()

    for task in tasks:
        task.status = TaskStatus.PENDING_REVIEW

    db.session.commit()
    print(f"[SCHEDULER] {len(tasks)} tarefas marcadas como PENDING_REVIEW de {yesterday}")


def midnight_job():
    """Job executado à meia-noite"""
    print(f"[SCHEDULER] Executando job de meia-noite: {datetime.now()}")
    duplicate_repeatable_tasks()
    mark_pending_review()


def init_scheduler(app):
    """Inicializa o scheduler"""
    scheduler = BackgroundScheduler()

    # Executar à meia-noite (00:00)
    scheduler.add_job(
        func=lambda: app.app_context().push() or midnight_job(),
        trigger='cron',
        hour=0,
        minute=0,
        id='midnight_job'
    )

    scheduler.start()
    print("[SCHEDULER] Scheduler inicializado - Job configurado para 00:00")
