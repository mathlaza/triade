from datetime import datetime, date
from app import db
from sqlalchemy import Enum as SQLEnum
import enum

class TriadCategory(enum.Enum):
    IMPORTANT = "IMPORTANT"
    URGENT = "URGENT"
    CIRCUMSTANTIAL = "CIRCUMSTANTIAL"

class TaskStatus(enum.Enum):
    ACTIVE = "ACTIVE"
    DONE = "DONE"
    DELEGATED = "DELEGATED"
    PENDING_REVIEW = "PENDING_REVIEW"

class Task(db.Model):
    __tablename__ = 'tasks'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    triad_category = db.Column(SQLEnum(TriadCategory), nullable=False)
    duration_minutes = db.Column(db.Integer, nullable=False)
    status = db.Column(SQLEnum(TaskStatus), default=TaskStatus.ACTIVE, nullable=False)
    date_scheduled = db.Column(db.Date, nullable=False)

    # Tags opcionais
    role_tag = db.Column(db.String(50), nullable=True)
    context_tag = db.Column(db.String(50), nullable=True)

    # Delegação
    delegated_to = db.Column(db.String(100), nullable=True)
    follow_up_date = db.Column(db.Date, nullable=True)

    # Repetição
    is_repeatable = db.Column(db.Boolean, default=False)
    repeat_count = db.Column(db.Integer, default=0)
    repeat_days = db.Column(db.Integer, nullable=True, default=None) 

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'triad_category': self.triad_category.value,
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
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    status = db.Column(SQLEnum(TaskStatus), default=TaskStatus.DONE, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('task_id', 'date', name='unique_task_date_completion'),
    )