from datetime import datetime, timezone, timedelta
from app import db
from sqlalchemy import Enum as SQLEnum, Index
import enum

# 🔥 NOVO: Define timezone do Brasil
BRAZIL_TZ = timezone(timedelta(hours=-3))

def get_brazil_time():
    """Retorna horário atual no timezone do Brasil"""
    return datetime.now(BRAZIL_TZ).replace(tzinfo=None)

class EnergyLevel(enum.Enum):
    HIGH_ENERGY = "HIGH_ENERGY"
    LOW_ENERGY = "LOW_ENERGY"
    RENEWAL = "RENEWAL"

class TaskStatus(enum.Enum):
    ACTIVE = "ACTIVE"
    DONE = "DONE"
    DELEGATED = "DELEGATED"
    PENDING_REVIEW = "PENDING_REVIEW"

class Task(db.Model):
    __tablename__ = 'tasks'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    energy_level = db.Column(SQLEnum(EnergyLevel), nullable=False)
    duration_minutes = db.Column(db.Integer, nullable=False)
    status = db.Column(SQLEnum(TaskStatus), default=TaskStatus.ACTIVE, nullable=False)
    date_scheduled = db.Column(db.Date, nullable=False)

    role_tag = db.Column(db.String(50), nullable=True)
    context_tag = db.Column(db.String(50), nullable=True)

    delegated_to = db.Column(db.String(100), nullable=True)
    follow_up_date = db.Column(db.Date, nullable=True)

    is_repeatable = db.Column(db.Boolean, default=False)
    repeat_count = db.Column(db.Integer, default=0)
    repeat_days = db.Column(db.Integer, nullable=True, default=None)

    completed_at = db.Column(db.DateTime, nullable=True)

    # 🔥 MUDANÇA: Usa função com timezone do Brasil
    created_at = db.Column(db.DateTime, default=get_brazil_time)
    updated_at = db.Column(db.DateTime, default=get_brazil_time, onupdate=get_brazil_time)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'energy_level': self.energy_level.value,
            'duration_minutes': self.duration_minutes,
            'status': self.status.value,
            'date_scheduled': self.date_scheduled.isoformat(),
            'role_tag': self.role_tag,
            'context_tag': self.context_tag,
            'delegated_to': self.delegated_to,
            'follow_up_date': self.follow_up_date.isoformat() if self.follow_up_date else None,
            'is_repeatable': self.is_repeatable,
            'repeat_count': self.repeat_count,
            'repeat_days': self.repeat_days,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }


class DailyConfig(db.Model):
    __tablename__ = 'daily_configs'

    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.Date, unique=True, nullable=False)
    available_hours = db.Column(db.Float, nullable=False, default=8.0)

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date.isoformat(),
            'available_hours': self.available_hours
        }


class TaskCompletion(db.Model):
    __tablename__ = 'task_completions'

    id = db.Column(db.Integer, primary_key=True)
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id', ondelete='CASCADE'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    status = db.Column(SQLEnum(TaskStatus), default=TaskStatus.DONE, nullable=False)
    # 🔥 MUDANÇA: Usa função com timezone do Brasil
    created_at = db.Column(db.DateTime, default=get_brazil_time)
    completed_at = db.Column(db.DateTime, nullable=True)

    __table_args__ = (
        db.UniqueConstraint('task_id', 'date', name='unique_task_date_completion'),
    )


Index('idx_task_date_status', Task.date_scheduled, Task.status)
Index('idx_task_repeatable', Task.is_repeatable, Task.status)
Index('idx_completion_task_date', TaskCompletion.task_id, TaskCompletion.date)