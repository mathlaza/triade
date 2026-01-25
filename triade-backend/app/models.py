from datetime import datetime, timezone, timedelta
from app import db
from sqlalchemy import Enum as SQLEnum, Index
from werkzeug.security import generate_password_hash, check_password_hash
import enum
import re

# 🔥 NOVO: Define timezone do Brasil
BRAZIL_TZ = timezone(timedelta(hours=-3))

def get_brazil_time():
    """Retorna horário atual no timezone do Brasil"""
    return datetime.now(BRAZIL_TZ).replace(tzinfo=None)


# ==================== USER MODEL ====================

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(10), unique=True, nullable=False, index=True)
    personal_name = db.Column(db.String(30), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    profile_photo = db.Column(db.LargeBinary, nullable=True)  # Foto em bytes (max 2MB)
    profile_photo_mimetype = db.Column(db.String(50), nullable=True)  # Ex: image/jpeg
    created_at = db.Column(db.DateTime, default=get_brazil_time)
    updated_at = db.Column(db.DateTime, default=get_brazil_time, onupdate=get_brazil_time)

    # Relacionamento com tarefas
    tasks = db.relationship('Task', backref='owner', lazy='dynamic')
    daily_configs = db.relationship('DailyConfig', backref='owner', lazy='dynamic')

    def set_password(self, password):
        """Gera hash seguro da senha usando Werkzeug"""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Verifica se a senha confere com o hash"""
        return check_password_hash(self.password_hash, password)

    @staticmethod
    def validate_username(username):
        """Valida username: até 10 chars, letras, números, ., - e _"""
        if not username or len(username) > 10:
            return False, "Username deve ter entre 1 e 10 caracteres"
        pattern = r'^[a-zA-Z0-9._-]+$'
        if not re.match(pattern, username):
            return False, "Username só pode conter letras, números, '.', '-' e '_'"
        return True, None

    @staticmethod
    def validate_email(email):
        """Valida formato de email"""
        if not email:
            return False, "Email é obrigatório"
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, email):
            return False, "Formato de email inválido"
        return True, None

    @staticmethod
    def validate_password(password):
        """Valida senha: mínimo 8 chars, 1 número e 1 caractere especial"""
        if not password or len(password) < 8:
            return False, "Senha deve ter no mínimo 8 caracteres"
        if not re.search(r'\d', password):
            return False, "Senha deve conter pelo menos 1 número"
        if not re.search(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;\'`~]', password):
            return False, "Senha deve conter pelo menos 1 caractere especial"
        return True, None

    def to_dict(self, include_photo=False):
        data = {
            'id': self.id,
            'username': self.username,
            'personal_name': self.personal_name,
            'email': self.email,
            'has_photo': self.profile_photo is not None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
        return data


# ==================== ENUMS ====================

class EnergyLevel(enum.Enum):
    HIGH_ENERGY = "HIGH_ENERGY"
    LOW_ENERGY = "LOW_ENERGY"
    RENEWAL = "RENEWAL"

class TaskStatus(enum.Enum):
    ACTIVE = "ACTIVE"
    DONE = "DONE"
    DELEGATED = "DELEGATED"
    PENDING_REVIEW = "PENDING_REVIEW"


# ==================== TASK MODEL ====================

class Task(db.Model):
    __tablename__ = 'tasks'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)  # nullable=True para migração
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
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)  # nullable=True para migração
    date = db.Column(db.Date, nullable=False)
    available_hours = db.Column(db.Float, nullable=False, default=8.0)

    # Constraint: Um usuário só pode ter uma config por dia
    __table_args__ = (
        db.UniqueConstraint('user_id', 'date', name='unique_user_date_config'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date.isoformat(),
            'available_hours': self.available_hours
        }


class TaskCompletion(db.Model):
    __tablename__ = 'task_completions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)  # nullable=True para migração
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id', ondelete='CASCADE'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    status = db.Column(SQLEnum(TaskStatus), default=TaskStatus.DONE, nullable=False)
    # 🔥 MUDANÇA: Usa função com timezone do Brasil
    created_at = db.Column(db.DateTime, default=get_brazil_time)
    completed_at = db.Column(db.DateTime, nullable=True)

    __table_args__ = (
        db.UniqueConstraint('task_id', 'date', name='unique_task_date_completion'),
    )


# ==================== INDEXES ====================

Index('idx_task_user_date', Task.user_id, Task.date_scheduled)
Index('idx_task_date_status', Task.date_scheduled, Task.status)
Index('idx_task_repeatable', Task.is_repeatable, Task.status)
Index('idx_completion_user_task', TaskCompletion.user_id, TaskCompletion.task_id)
Index('idx_completion_task_date', TaskCompletion.task_id, TaskCompletion.date)
Index('idx_daily_config_user', DailyConfig.user_id, DailyConfig.date)