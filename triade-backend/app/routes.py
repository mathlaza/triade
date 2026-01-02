from flask import Blueprint, request, jsonify
from datetime import datetime, date, timedelta
from app import db
from app.models import Task, DailyConfig, TriadCategory, TaskStatus
from app.utils import validate_timebox, calculate_used_hours, get_available_hours, get_triad_order_value

api_bp = Blueprint('api', __name__)

# ==================== TASKS ====================

@api_bp.route('/tasks/daily', methods=['GET'])
def get_daily_tasks():
    """Retorna tarefas do dia ordenadas por categoria + tarefas repetíveis dos dias anteriores"""
    date_str = request.args.get('date')

    if not date_str:
        return jsonify({'error': 'Parâmetro date obrigatório (YYYY-MM-DD)'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Formato de data inválido. Use YYYY-MM-DD'}), 400

    # 1. Buscar tarefas ATIVAS do dia específico
    tasks = Task.query.filter(
        Task.date_scheduled == target_date,
        Task.status == TaskStatus.ACTIVE
    ).all()

    # 2. ADICIONAR tarefas repetíveis de dias ANTERIORES
    repeatable_tasks = Task.query.filter(
        Task.date_scheduled < target_date,
        Task.is_repeatable == True,
        Task.status.in_([TaskStatus.DONE, TaskStatus.ACTIVE])
    ).all()

    # Criar "cópias virtuais" para o dia alvo
    virtual_tasks = []
    for rep_task in repeatable_tasks:
        # Verificar se já existe uma cópia para este dia
        existing = Task.query.filter(
            Task.title == rep_task.title,
            Task.date_scheduled == target_date
        ).first()

        if not existing:
            # Calcular quantos dias se passaram desde a criação
            days_diff = (target_date - rep_task.date_scheduled).days

            virtual_task = Task(
                id=rep_task.id,
                title=rep_task.title,
                triad_category=rep_task.triad_category,
                duration_minutes=rep_task.duration_minutes,
                status=TaskStatus.ACTIVE,
                date_scheduled=target_date,
                role_tag=rep_task.role_tag,
                context_tag=rep_task.context_tag,
                is_repeatable=True,
                repeat_count=days_diff + 1,  # Dia 1 no dia da criação
                created_at=rep_task.created_at,
                updated_at=datetime.utcnow()
            )
            virtual_tasks.append(virtual_task)

    # Combinar tarefas reais + virtuais
    all_tasks = tasks + virtual_tasks

    # Ordenar por prioridade da Tríade
    tasks_sorted = sorted(all_tasks, key=lambda t: get_triad_order_value(t.triad_category))

    # CALCULAR HORAS USADAS (incluindo virtuais)
    total_minutes = sum(task.duration_minutes for task in all_tasks)
    used_hours = round(total_minutes / 60, 2)

    available_hours = get_available_hours(target_date)

    return jsonify({
        'date': date_str,
        'tasks': [task.to_dict() for task in tasks_sorted],
        'summary': {
            'total_tasks': len(tasks_sorted),
            'used_hours': used_hours,
            'available_hours': available_hours,
            'remaining_hours': round(available_hours - used_hours, 2)
        }
    }), 200


@api_bp.route('/tasks/pending_review', methods=['GET'])
def get_pending_review():
    """Retorna tarefas do dia anterior que não foram concluídas"""
    date_str = request.args.get('date')

    if not date_str:
        return jsonify({'error': 'Parâmetro date obrigatório (YYYY-MM-DD)'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Formato de data inválido. Use YYYY-MM-DD'}), 400

    tasks = Task.query.filter(
        Task.date_scheduled == target_date,
        Task.status == TaskStatus.PENDING_REVIEW
    ).all()

    return jsonify({
        'date': date_str,
        'pending_tasks': [task.to_dict() for task in tasks],
        'count': len(tasks)
    }), 200


@api_bp.route('/tasks', methods=['POST'])
def create_task():
    """Criar nova tarefa com validação de timebox"""
    data = request.get_json()

    # Validações obrigatórias
    required_fields = ['title', 'triad_category', 'duration_minutes', 'date_scheduled']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Campo obrigatório: {field}'}), 400

    # Validar categoria
    try:
        category = TriadCategory[data['triad_category']]
    except KeyError:
        return jsonify({'error': 'triad_category inválido. Use: IMPORTANT, URGENT ou CIRCUMSTANTIAL'}), 400

    # Validar data
    try:
        target_date = datetime.strptime(data['date_scheduled'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date_scheduled inválido. Use YYYY-MM-DD'}), 400

    # Validar timebox
    valid, error_data = validate_timebox(target_date, data['duration_minutes'])
    if not valid:
        return jsonify(error_data), 400

    # Criar tarefa
    task = Task(
        title=data['title'],
        triad_category=category,
        duration_minutes=data['duration_minutes'],
        date_scheduled=target_date,
        role_tag=data.get('role_tag'),
        context_tag=data.get('context_tag'),
        delegated_to=data.get('delegated_to'),
        follow_up_date=datetime.strptime(data['follow_up_date'], '%Y-%m-%d').date() if data.get('follow_up_date') else None,
        is_repeatable=data.get('is_repeatable', False),
        status=TaskStatus.DELEGATED if data.get('delegated_to') else TaskStatus.ACTIVE
    )

    db.session.add(task)
    db.session.commit()

    return jsonify({
        'message': 'Tarefa criada com sucesso',
        'task': task.to_dict()
    }), 201


@api_bp.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    """Atualizar tarefa (status, campos, etc)"""
    task = Task.query.get_or_404(task_id)
    data = request.get_json()

    # Atualizar status se fornecido
    if 'status' in data:
        try:
            task.status = TaskStatus[data['status']]
        except KeyError:
            return jsonify({'error': 'Status inválido'}), 400

    # Atualizar outros campos
    if 'title' in data:
        task.title = data['title']

    if 'duration_minutes' in data:
        # Revalidar timebox se mudar duração
        old_duration = task.duration_minutes
        new_duration = data['duration_minutes']
        delta = new_duration - old_duration

        if delta > 0:
            valid, error_data = validate_timebox(task.date_scheduled, delta)
            if not valid:
                return jsonify(error_data), 400

        task.duration_minutes = new_duration

    if 'triad_category' in data:
        try:
            task.triad_category = TriadCategory[data['triad_category']]
        except KeyError:
            return jsonify({'error': 'triad_category inválido'}), 400

    if 'date_scheduled' in data:
        try:
            task.date_scheduled = datetime.strptime(data['date_scheduled'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'date_scheduled inválido'}), 400

    if 'role_tag' in data:
        task.role_tag = data['role_tag']

    if 'context_tag' in data:
        task.context_tag = data['context_tag']

    if 'delegated_to' in data:
        task.delegated_to = data['delegated_to']
        if data['delegated_to']:
            task.status = TaskStatus.DELEGATED

    if 'follow_up_date' in data:
        try:
            task.follow_up_date = datetime.strptime(data['follow_up_date'], '%Y-%m-%d').date() if data['follow_up_date'] else None
        except ValueError:
            return jsonify({'error': 'follow_up_date inválido'}), 400

    task.updated_at = datetime.utcnow()
    db.session.commit()

    return jsonify({
        'message': 'Tarefa atualizada',
        'task': task.to_dict()
    }), 200


@api_bp.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Excluir tarefa"""
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()

    return jsonify({'message': 'Tarefa excluída com sucesso'}), 200


# ==================== FOLLOW-UP (DELEGAÇÕES) ====================

@api_bp.route('/tasks/delegated', methods=['GET'])
def get_delegated_tasks():
    """Retorna todas as tarefas delegadas pendentes de follow-up"""
    delegated = Task.query.filter(
        Task.status == TaskStatus.DELEGATED
    ).order_by(Task.follow_up_date.asc()).all()

    return jsonify({
        'total': len(delegated),
        'tasks': [task.to_dict() for task in delegated]
    }), 200


# ==================== STATS & DASHBOARD ====================

@api_bp.route('/stats/triad', methods=['GET'])
def get_triad_stats():
    """Retorna estatísticas da Tríade por período (default: últimos 30 dias)"""
    start_str = request.args.get('start_date')
    end_str = request.args.get('end_date')

    # Default: últimos 30 dias se não passar parâmetros
    if not start_str or not end_str:
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=30)
    else:
        try:
            start_date = datetime.strptime(start_str, '%Y-%m-%d').date()
            end_date = datetime.strptime(end_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Formato de data inválido. Use YYYY-MM-DD'}), 400

    tasks = Task.query.filter(
        Task.date_scheduled >= start_date,
        Task.date_scheduled <= end_date,
        Task.status == TaskStatus.DONE
    ).all()

    # Calcular minutos por categoria
    urgent_minutes = sum(t.duration_minutes for t in tasks if t.triad_category == TriadCategory.URGENT)
    important_minutes = sum(t.duration_minutes for t in tasks if t.triad_category == TriadCategory.IMPORTANT)
    circumstantial_minutes = sum(t.duration_minutes for t in tasks if t.triad_category == TriadCategory.CIRCUMSTANTIAL)

    total_minutes = urgent_minutes + important_minutes + circumstantial_minutes

    return jsonify({
        'period': {
            'start': start_date.isoformat(),
            'end': end_date.isoformat()
        },
        'total_hours': round(total_minutes / 60, 2),
        'urgent': {
            'hours': round(urgent_minutes / 60, 2),
            'percentage': round((urgent_minutes / total_minutes * 100) if total_minutes > 0 else 0, 1)
        },
        'important': {
            'hours': round(important_minutes / 60, 2),
            'percentage': round((important_minutes / total_minutes * 100) if total_minutes > 0 else 0, 1)
        },
        'circumstantial': {
            'hours': round(circumstantial_minutes / 60, 2),
            'percentage': round((circumstantial_minutes / total_minutes * 100) if total_minutes > 0 else 0, 1)
        },
        'tasks_completed': len(tasks)
    }), 200


# ==================== HISTÓRICO ====================

@api_bp.route('/tasks/history', methods=['GET'])
def get_tasks_history():
    """Retorna histórico de tarefas concluídas"""
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    if not start_date_str or not end_date_str:
        return jsonify({'error': 'Parâmetros start_date e end_date obrigatórios (YYYY-MM-DD)'}), 400

    try:
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Formato de data inválido. Use YYYY-MM-DD'}), 400

    tasks = Task.query.filter(
        Task.date_scheduled.between(start_date, end_date),
        Task.status == TaskStatus.DONE
    ).order_by(Task.date_scheduled.desc()).all()

    return jsonify({
        'period': {
            'start': start_date_str,
            'end': end_date_str
        },
        'total': len(tasks),
        'tasks': [task.to_dict() for task in tasks]
    }), 200


# ==================== CONFIG ====================

@api_bp.route('/config/daily', methods=['POST'])
def set_daily_config():
    """Criar/atualizar horas disponíveis do dia"""
    data = request.get_json()

    if 'date' not in data or 'available_hours' not in data:
        return jsonify({'error': 'Campos obrigatórios: date, available_hours'}), 400

    try:
        target_date = datetime.strptime(data['date'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date inválido. Use YYYY-MM-DD'}), 400

    config = DailyConfig.query.filter_by(date=target_date).first()

    if config:
        config.available_hours = data['available_hours']
    else:
        config = DailyConfig(
            date=target_date,
            available_hours=data['available_hours']
        )
        db.session.add(config)

    db.session.commit()

    return jsonify({
        'message': 'Configuração salva',
        'config': config.to_dict()
    }), 200


@api_bp.route('/config/daily', methods=['GET'])
def get_daily_config():
    """Retornar horas disponíveis do dia"""
    date_str = request.args.get('date')

    if not date_str:
        return jsonify({'error': 'Parâmetro date obrigatório'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date inválido. Use YYYY-MM-DD'}), 400

    config = DailyConfig.query.filter_by(date=target_date).first()

    if not config:
        return jsonify({
            'date': date_str,
            'available_hours': 8.0,
            'is_default': True
        }), 200

    return jsonify(config.to_dict()), 200


# ==================== HEALTH CHECK ====================

@api_bp.route('/health', methods=['GET'])
def health_check():
    """Verifica se API está online"""
    return jsonify({
        'status': 'online',
        'message': 'API Tríade do Tempo rodando',
        'timestamp': datetime.now().isoformat()
    }), 200


# ==================== DEBUG/TESTE ====================

@api_bp.route('/test/midnight-job', methods=['POST'])
def test_midnight_job():
    """APENAS TESTE - Remove em produção"""
    from app.scheduler import midnight_job
    from flask import current_app

    with current_app.app_context():
        midnight_job()

    return jsonify({'message': 'Job de meia-noite executado com sucesso'}), 200
