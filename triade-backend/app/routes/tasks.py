"""
Tasks Routes - CRUD e operações de tarefas

Endpoints:
- GET /tasks/daily - Listar tarefas do dia
- POST /tasks - Criar tarefa
- PUT /tasks/<id> - Atualizar tarefa
- DELETE /tasks/<id> - Excluir tarefa
- POST /tasks/<id>/toggle-date - Toggle status por data
- GET /tasks/pending_review - Tarefas pendentes de revisão
- GET /tasks/delegated - Tarefas delegadas
- GET /tasks/weekly - Tarefas da semana
- GET /tasks/history - Histórico de tarefas
- POST /tasks/cleanup - Limpar tarefas antigas
"""

from flask import request, jsonify
from datetime import datetime, timedelta
from app import db
from app.routes import api_bp
from app.models import Task, DailyConfig, EnergyLevel, TaskStatus, TaskCompletion, get_brazil_time
from app.utils import validate_timebox, get_available_hours, get_energy_level_order_value
from app.auth import token_required
from sqlalchemy import or_


# ==================== DAILY TASKS ====================

@api_bp.route('/tasks/daily', methods=['GET'])
@token_required
def get_daily_tasks(current_user):
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'error': 'Parâmetro date é obrigatório'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()

        # 1. Buscar tarefas REAIS agendadas para hoje
        real_tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.date_scheduled == target_date
        ).all()

        # 2. Buscar tarefas REPETÍVEIS (Active) que começaram antes de hoje
        repeatable_candidates = Task.query.filter(
            Task.user_id == current_user.id,
            Task.is_repeatable == True,
            Task.date_scheduled < target_date,
            Task.status == TaskStatus.ACTIVE
        ).all()

        # 3. Buscar conclusões salvas para este dia específico
        completions = TaskCompletion.query.filter(
            TaskCompletion.user_id == current_user.id,
            TaskCompletion.date == target_date
        ).all()
        completion_map = {c.task_id: c.status for c in completions}

        # Aplicar conclusões às real_tasks repetíveis
        processed_real_tasks = []
        for task in real_tasks:
            if task.is_repeatable and task.id in completion_map:
                processed_task = Task(
                    id=task.id,
                    title=task.title,
                    description=task.description,
                    energy_level=task.energy_level, 
                    duration_minutes=task.duration_minutes,
                    status=completion_map[task.id],
                    date_scheduled=task.date_scheduled,
                    scheduled_time=task.scheduled_time,
                    role_tag=task.role_tag,
                    context_tag=task.context_tag,
                    delegated_to=task.delegated_to,
                    is_repeatable=task.is_repeatable,
                    repeat_count=1,
                    repeat_days=task.repeat_days,
                    created_at=task.created_at,
                    updated_at=get_brazil_time()
                )
                processed_real_tasks.append(processed_task)
            else:
                processed_real_tasks.append(task)

        # Criar tarefas virtuais para repetíveis
        virtual_tasks = []
        for rep_task in repeatable_candidates:
            days_diff = (target_date - rep_task.date_scheduled).days

            if rep_task.repeat_days and rep_task.repeat_days > 0:
                if days_diff >= rep_task.repeat_days:
                    continue

            current_status = completion_map.get(rep_task.id, TaskStatus.ACTIVE)

            virtual_task = Task(
                id=rep_task.id,
                title=rep_task.title,
                description=rep_task.description,
                energy_level=rep_task.energy_level,
                duration_minutes=rep_task.duration_minutes,
                status=current_status,
                date_scheduled=target_date,
                scheduled_time=rep_task.scheduled_time,
                role_tag=rep_task.role_tag,
                context_tag=rep_task.context_tag,
                delegated_to=rep_task.delegated_to,
                is_repeatable=True,
                repeat_count=days_diff + 1,
                repeat_days=rep_task.repeat_days,
                created_at=rep_task.created_at,
                updated_at=get_brazil_time()
            )
            virtual_tasks.append(virtual_task)

        all_tasks = processed_real_tasks + virtual_tasks
        tasks_sorted = sorted(
            all_tasks, 
            key=lambda t: (
                get_energy_level_order_value(t.energy_level),
                t.context_tag or 'zzz',
                t.title.lower()
            )
        )

        # Calcular duração (exclui delegadas)
        my_tasks_duration = [
            t.duration_minutes for t in all_tasks 
            if t.delegated_to is None or t.delegated_to == ""
        ]
        total_minutes = sum(my_tasks_duration)
        used_hours = round(total_minutes / 60, 2)

        active_count = len([t for t in all_tasks if t.status == TaskStatus.ACTIVE])
        available_hours = get_available_hours(target_date)

        return jsonify({
            'date': date_str,
            'tasks': [task.to_dict() for task in tasks_sorted],
            'summary': {
                'total_tasks': active_count,
                'used_hours': used_hours,
                'available_hours': available_hours,
                'remaining_hours': round(available_hours - used_hours, 2)
            }
        }), 200

    except ValueError:
        return jsonify({'error': 'Formato de data inválido'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== TOGGLE TASK STATUS ====================

@api_bp.route('/tasks/<int:task_id>/toggle-date', methods=['POST'])
@token_required
def toggle_task_date(current_user, task_id):
    data = request.get_json()
    date_str = data.get('date')

    if not date_str:
        return jsonify({'error': 'Data obrigatória'}), 400

    target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    task = Task.query.filter(
        Task.id == task_id,
        Task.user_id == current_user.id
    ).first_or_404()

    completion = TaskCompletion.query.filter(
        TaskCompletion.user_id == current_user.id,
        TaskCompletion.task_id == task_id, 
        TaskCompletion.date == target_date
    ).first()

    new_status = TaskStatus.ACTIVE

    if completion:
        db.session.delete(completion)
        new_status = TaskStatus.ACTIVE
        
        if not task.is_repeatable and task.date_scheduled == target_date:
            task.completed_at = None
            task.status = TaskStatus.ACTIVE
    else:
        now = get_brazil_time()
        
        completion = TaskCompletion(
            user_id=current_user.id,
            task_id=task_id,
            date=target_date,
            status=TaskStatus.DONE,
            completed_at=now
        )
        db.session.add(completion)
        new_status = TaskStatus.DONE
        
        if not task.is_repeatable and task.date_scheduled == target_date:
            task.completed_at = now
            task.status = TaskStatus.DONE

    task.updated_at = get_brazil_time()
    db.session.commit()

    return jsonify({'status': new_status.value, 'task_id': task_id, 'date': date_str}), 200


# ==================== PENDING REVIEW ====================

@api_bp.route('/tasks/pending_review', methods=['GET'])
@token_required
def get_pending_review(current_user):
    """Retorna tarefas do dia anterior que não foram concluídas"""
    date_str = request.args.get('date')

    if not date_str:
        return jsonify({'error': 'Parâmetro date obrigatório (YYYY-MM-DD)'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Formato de data inválido. Use YYYY-MM-DD'}), 400

    tasks = Task.query.filter(
        Task.user_id == current_user.id,
        Task.date_scheduled == target_date,
        Task.status == TaskStatus.PENDING_REVIEW
    ).all()

    return jsonify({
        'date': date_str,
        'pending_tasks': [task.to_dict() for task in tasks],
        'count': len(tasks)
    }), 200


# ==================== CREATE TASK ====================

@api_bp.route('/tasks', methods=['POST'])
@token_required
def create_task(current_user):
    """Criar nova tarefa com validação de timebox"""
    data = request.get_json()

    required_fields = ['title', 'energy_level', 'duration_minutes', 'date_scheduled']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Campo obrigatório: {field}'}), 400

    try:
        energy = EnergyLevel[data['energy_level']]
    except KeyError:
        return jsonify({'error': 'energy_level inválido. Use: HIGH_ENERGY, LOW_ENERGY ou RENEWAL'}), 400

    try:
        target_date = datetime.strptime(data['date_scheduled'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'date_scheduled inválido. Use YYYY-MM-DD'}), 400

    valid, error_data = validate_timebox(target_date, data['duration_minutes'], current_user.id)
    if not valid:
        return jsonify(error_data), 400

    scheduled_time = None
    if data.get('scheduled_time'):
        try:
            scheduled_time = datetime.strptime(data['scheduled_time'], '%H:%M').time()
        except ValueError:
            return jsonify({'error': 'scheduled_time inválido. Use HH:MM'}), 400

    task = Task(
        user_id=current_user.id,
        title=data['title'][:40],
        description=data.get('description', '')[:100] if data.get('description') else None,
        energy_level=energy,
        duration_minutes=data['duration_minutes'],
        date_scheduled=target_date,
        scheduled_time=scheduled_time,
        role_tag=data.get('role_tag', '')[:30] if data.get('role_tag') else None,
        context_tag=data.get('context_tag'),
        delegated_to=data.get('delegated_to', '')[:50] if data.get('delegated_to') else None,
        is_repeatable=data.get('is_repeatable', False),
        repeat_count=data.get('repeat_count', 0),
        repeat_days=data.get('repeat_days')
    )

    if task.delegated_to:
        task.status = TaskStatus.DELEGATED

    if 'follow_up_date' in data and data['follow_up_date']:
        try:
            task.follow_up_date = datetime.strptime(data['follow_up_date'], '%Y-%m-%d').date()
        except ValueError:
            pass

    db.session.add(task)
    db.session.commit()

    return jsonify(task.to_dict()), 201


# ==================== UPDATE TASK ====================

@api_bp.route('/tasks/<int:task_id>', methods=['PUT'])
@token_required
def update_task(current_user, task_id):
    task = Task.query.filter(
        Task.id == task_id,
        Task.user_id == current_user.id
    ).first_or_404()
    data = request.get_json()

    was_repeatable = task.is_repeatable
    old_status = task.status

    # Campos simples
    if 'title' in data: 
        task.title = data['title'][:40] if data['title'] else data['title']
    if 'description' in data:
        task.description = data['description'][:100] if data['description'] else None
    if 'duration_minutes' in data: 
        task.duration_minutes = data['duration_minutes']
    if 'role_tag' in data: 
        task.role_tag = data['role_tag'][:30] if data['role_tag'] else None
    if 'context_tag' in data: 
        task.context_tag = data['context_tag']

    # Categoria e Data
    if 'energy_level' in data:
        try:
            task.energy_level = EnergyLevel[data['energy_level']]
        except KeyError:
            return jsonify({'error': 'Nível de energia inválido'}), 400

    if 'date_scheduled' in data:
        try:
            task.date_scheduled = datetime.strptime(data['date_scheduled'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Data inválida'}), 400

    # Scheduled Time
    if 'scheduled_time' in data:
        val = data['scheduled_time']
        if val:
            try:
                task.scheduled_time = datetime.strptime(val, '%H:%M').time()
            except ValueError:
                return jsonify({'error': 'scheduled_time inválido. Use HH:MM'}), 400
        else:
            task.scheduled_time = None

    # Status
    if 'status' in data:
        try:
            new_status = TaskStatus[data['status']]
            task.status = new_status
            
            if new_status == TaskStatus.DONE and old_status != TaskStatus.DONE:
                task.completed_at = get_brazil_time()
        
            elif new_status != TaskStatus.DONE and old_status == TaskStatus.DONE:
                task.completed_at = None
            
        except KeyError:
            return jsonify({'error': 'Status inválido'}), 400

    # Delegação
    if 'delegated_to' in data:
        val = data['delegated_to']

        if val and val.strip():
            task.delegated_to = val
            if task.status != TaskStatus.DONE:
                task.status = TaskStatus.DELEGATED
        else:
            task.delegated_to = None
            if task.status == TaskStatus.DELEGATED:
                task.status = TaskStatus.ACTIVE

    # Follow-up
    if 'follow_up_date' in data:
        val = data['follow_up_date']
        task.follow_up_date = datetime.strptime(val, '%Y-%m-%d').date() if val else None

    # Repetição
    if 'is_repeatable' in data:
        new_is_repeatable = data['is_repeatable']
        
        if not was_repeatable and new_is_repeatable:
            task.completed_at = None
            TaskCompletion.query.filter_by(task_id=task_id).delete()
            
            if task.status == TaskStatus.DONE:
                task.status = TaskStatus.ACTIVE
        
        task.is_repeatable = new_is_repeatable
    
    if 'repeat_days' in data: 
        task.repeat_days = data['repeat_days']

    task.updated_at = get_brazil_time()
    db.session.commit()

    return jsonify({'message': 'Tarefa atualizada', 'task': task.to_dict()})


# ==================== DELETE TASK ====================

@api_bp.route('/tasks/<int:task_id>', methods=['DELETE'])
@token_required
def delete_task(current_user, task_id):
    """Excluir tarefa"""
    task = Task.query.filter(
        Task.id == task_id,
        Task.user_id == current_user.id
    ).first_or_404()
    
    TaskCompletion.query.filter(
        TaskCompletion.user_id == current_user.id,
        TaskCompletion.task_id == task_id
    ).delete()

    db.session.delete(task)
    db.session.commit()

    return jsonify({'message': 'Tarefa excluída com sucesso'}), 200


# ==================== DELEGATED TASKS ====================

@api_bp.route('/tasks/delegated', methods=['GET'])
@token_required
def get_delegated_tasks(current_user):
    delegated = Task.query.filter(
        Task.user_id == current_user.id,
        Task.delegated_to.isnot(None),
        Task.delegated_to != ""
    ).order_by(Task.follow_up_date.asc()).all()

    return jsonify({
        'total': len(delegated),
        'tasks': [task.to_dict() for task in delegated]
    }), 200


# ==================== WEEKLY TASKS ====================

@api_bp.route('/tasks/weekly', methods=['GET'])
@token_required
def get_weekly_tasks(current_user):
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    if not start_date or not end_date:
        return jsonify({'error': 'start_date e end_date são obrigatórios'}), 400
    
    try:
        start = datetime.strptime(start_date, '%Y-%m-%d').date()
        end = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.date_scheduled >= start,
            Task.date_scheduled <= end,
            or_(
                Task.delegated_to == None,
                Task.delegated_to == ""
            )
        ).order_by(Task.date_scheduled, Task.energy_level).all()

        daily_configs = {}
        current_date = start
        while current_date <= end:
            config = DailyConfig.query.filter(
                DailyConfig.user_id == current_user.id,
                DailyConfig.date == current_date
            ).first()
            daily_configs[current_date.isoformat()] = config.available_hours if config else 8.0
            current_date += timedelta(days=1)

        return jsonify({
            'tasks': [task.to_dict() for task in tasks],
            'daily_configs': daily_configs,
            'start_date': start_date,
            'end_date': end_date
        }), 200

    except ValueError:
        return jsonify({'error': 'Formato de data inválido'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== HISTORY ====================

@api_bp.route('/tasks/history', methods=['GET'])
@token_required
def get_tasks_history(current_user):
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    search_term = request.args.get('search', '').strip()
    
    try:
        normal_tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.status == TaskStatus.DONE,
            Task.completed_at.isnot(None),
            Task.is_repeatable == False
        ).all()

        repeatable_tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.is_repeatable == True
        ).all()

        all_completed_tasks = []
        
        for task in normal_tasks:
            all_completed_tasks.append({
                'id': task.id,
                'title': task.title,
                'energy_level': task.energy_level.value,
                'duration_minutes': task.duration_minutes,
                'completed_at': task.completed_at,
                'date_scheduled': task.date_scheduled,
                'context_tag': task.context_tag,
                'role_tag': task.role_tag,
                'description': task.description
            })

        for rep_task in repeatable_tasks:
            completions = TaskCompletion.query.filter_by(
                task_id=rep_task.id,
                status=TaskStatus.DONE
            ).all()

            seen_keys = set()
            
            for completion in completions:
                key = f"{rep_task.id}_{completion.date}"
                
                if key in seen_keys:
                    continue
                    
                seen_keys.add(key)
                
                all_completed_tasks.append({
                    'id': rep_task.id,
                    'title': rep_task.title,
                    'energy_level': rep_task.energy_level.value,
                    'duration_minutes': rep_task.duration_minutes,
                    'completed_at': completion.completed_at or datetime.combine(completion.date, datetime.min.time()),
                    'date_scheduled': completion.date,
                    'context_tag': rep_task.context_tag,
                    'role_tag': rep_task.role_tag,
                    'description': rep_task.description
                })

        if search_term:
            all_completed_tasks = [
                t for t in all_completed_tasks 
                if search_term.lower() in t['title'].lower()
            ]

        all_completed_tasks.sort(key=lambda t: t['completed_at'], reverse=True)

        unique_tasks = []
        seen_final = set()
        
        for task in all_completed_tasks:
            key = f"{task['id']}_{task['date_scheduled']}_{task['completed_at']}"
            if key not in seen_final:
                unique_tasks.append(task)
                seen_final.add(key)

        total_items = len(unique_tasks)
        start_idx = (page - 1) * per_page
        end_idx = start_idx + per_page
        paginated_tasks = unique_tasks[start_idx:end_idx]

        for task in paginated_tasks:
            task['completed_at'] = task['completed_at'].isoformat()
            task['date_scheduled'] = task['date_scheduled'].isoformat()

        total_pages = (total_items + per_page - 1) // per_page

        return jsonify({
            'tasks': paginated_tasks,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_items': total_items,
                'total_pages': total_pages,
                'has_next': page < total_pages,
                'has_prev': page > 1
            },
            'search_term': search_term if search_term else None
        }), 200
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== CLEANUP ====================

@api_bp.route('/tasks/cleanup', methods=['POST'])
def cleanup_old_tasks():
    """Remove tarefas DONE com mais de 90 dias"""
    from datetime import date
    cutoff_date = date.today() - timedelta(days=90)
    
    deleted = Task.query.filter(
        Task.status == TaskStatus.DONE,
        Task.date_scheduled < cutoff_date
    ).delete()
    
    db.session.commit()
    return jsonify({'message': f'{deleted} tarefas antigas removidas'}), 200
