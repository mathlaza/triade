from flask import Blueprint, request, jsonify
from datetime import datetime, date, timedelta
from app import db
from app.models import Task, DailyConfig, TriadCategory, TaskStatus, TaskCompletion 
from app.utils import validate_timebox, get_available_hours, get_triad_order_value
from sqlalchemy import and_, or_
from app.backup import backup_database, restore_backup, list_backups

api_bp = Blueprint('api', __name__)

# ==================== TASKS ====================

@api_bp.route('/tasks/daily', methods=['GET'])
def get_daily_tasks():
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'error': 'Parâmetro date é obrigatório'}), 400

    try:
        target_date = datetime.strptime(date_str, '%Y-%m-%d').date()

        # 1. Buscar tarefas REAIS agendadas para hoje
        real_tasks = Task.query.filter_by(date_scheduled=target_date).all()

        # 2. Buscar tarefas REPETÍVEIS (Active) que começaram antes de hoje
        repeatable_candidates = Task.query.filter(
            Task.is_repeatable == True,
            Task.date_scheduled < target_date,
            Task.status == TaskStatus.ACTIVE
        ).all()

        # 3. Buscar conclusões salvas para este dia específico
        completions = TaskCompletion.query.filter_by(date=target_date).all()
        completion_map = {c.task_id: c.status for c in completions}

        # ✅ CORREÇÃO: Aplicar conclusões também às real_tasks repetíveis
        processed_real_tasks = []
        for task in real_tasks:
            if task.is_repeatable and task.id in completion_map:
                # Tarefa repetível com conclusão registrada para hoje
                # Criar uma cópia com o status correto
                processed_task = Task(
                    id=task.id,
                    title=task.title,
                    triad_category=task.triad_category,
                    duration_minutes=task.duration_minutes,
                    status=completion_map[task.id],  # ✅ Status da conclusão
                    date_scheduled=task.date_scheduled,
                    role_tag=task.role_tag,
                    context_tag=task.context_tag,
                    delegated_to=task.delegated_to,
                    is_repeatable=task.is_repeatable,
                    repeat_count=1,  # Dia 1 da série
                    repeat_days=task.repeat_days,
                    created_at=task.created_at,
                    updated_at=datetime.utcnow()
                )
                processed_real_tasks.append(processed_task)
            else:
                # Tarefa normal ou repetível sem conclusão
                processed_real_tasks.append(task)

        virtual_tasks = []
        for rep_task in repeatable_candidates:
            days_diff = (target_date - rep_task.date_scheduled).days

            # Lógica de Limite de Repetição
            if rep_task.repeat_days and rep_task.repeat_days > 0:
                if days_diff >= rep_task.repeat_days:
                    continue

            # Define status: Se tiver na tabela de completions, usa o status dela (DONE). Se não, ACTIVE.
            current_status = completion_map.get(rep_task.id, TaskStatus.ACTIVE)

            virtual_task = Task(
                id=rep_task.id,
                title=rep_task.title,
                triad_category=rep_task.triad_category,
                duration_minutes=rep_task.duration_minutes,
                status=current_status,
                date_scheduled=target_date,
                role_tag=rep_task.role_tag,
                context_tag=rep_task.context_tag,
                delegated_to=rep_task.delegated_to,
                is_repeatable=True,
                repeat_count=days_diff + 1,
                repeat_days=rep_task.repeat_days,
                created_at=rep_task.created_at,
                updated_at=datetime.utcnow()
            )
            virtual_tasks.append(virtual_task)

        # ✅ Usar processed_real_tasks ao invés de real_tasks
        all_tasks = processed_real_tasks + virtual_tasks
        tasks_sorted = sorted(all_tasks, key=lambda t: get_triad_order_value(t.triad_category))

        # Filtra explicitamente. Se tiver 'delegated_to', NÃO SOMA, independente do status.
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




@api_bp.route('/tasks/<int:task_id>/toggle-date', methods=['POST'])
def toggle_task_date(task_id):
    data = request.get_json()
    date_str = data.get('date')

    if not date_str:
        return jsonify({'error': 'Data obrigatória'}), 400

    target_date = datetime.strptime(date_str, '%Y-%m-%d').date()

    # Buscar a tarefa original
    task = Task.query.get_or_404(task_id)

    # Verifica se já existe conclusão
    completion = TaskCompletion.query.filter_by(task_id=task_id, date=target_date).first()

    new_status = TaskStatus.ACTIVE

    if completion:
        # CASO 1: Desmarcar DONE → ACTIVE
        db.session.delete(completion)
        new_status = TaskStatus.ACTIVE
        
        # Se for a data original da tarefa, limpar completed_at
        if task.date_scheduled == target_date:
            task.completed_at = None
    else:
        # CASO 2: Marcar ACTIVE → DONE
        now = datetime.utcnow()  # ✅ Captura hora exata
        
        completion = TaskCompletion(
            task_id=task_id,
            date=target_date,
            status=TaskStatus.DONE,
            completed_at=now  # ✅ NOVO: Salva timestamp real
        )
        db.session.add(completion)
        new_status = TaskStatus.DONE
        
        # Se for a data original da tarefa, preencher completed_at
        if task.date_scheduled == target_date:
            task.completed_at = now

    task.updated_at = datetime.utcnow()
    db.session.commit()

    return jsonify({'status': new_status.value, 'task_id': task_id, 'date': date_str}), 200




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
        # Campos opcionais
        role_tag=data.get('role_tag'),
        context_tag=data.get('context_tag'),
        delegated_to=data.get('delegated_to'),
        # CORREÇÃO: Adicionando persistência da repetição
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



@api_bp.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json()

    # --- 1. Atualização de Campos Simples ---
    if 'title' in data: 
        task.title = data['title']
    if 'duration_minutes' in data: 
        task.duration_minutes = data['duration_minutes']
    if 'role_tag' in data: 
        task.role_tag = data['role_tag']
    if 'context_tag' in data: 
        task.context_tag = data['context_tag']

    # --- 2. Categoria e Data ---
    if 'triad_category' in data:
        try:
            task.triad_category = TriadCategory[data['triad_category']]
        except KeyError:
            return jsonify({'error': 'Categoria inválida'}), 400

    if 'date_scheduled' in data:
        try:
            task.date_scheduled = datetime.strptime(data['date_scheduled'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Data inválida'}), 400

    # --- 3. Tratamento de Status (ANTES da delegação para capturar mudanças) ---
    old_status = task.status
    if 'status' in data:
        try:
            new_status = TaskStatus[data['status']]
            task.status = new_status
            
            # Gravar completed_at ao marcar como DONE
            if new_status == TaskStatus.DONE and old_status != TaskStatus.DONE:
                task.completed_at = datetime.utcnow()
        
            # Limpar completed_at ao desmarcar
            elif new_status != TaskStatus.DONE and old_status == TaskStatus.DONE:
                task.completed_at = None
            
        except KeyError:
            return jsonify({'error': 'Status inválido'}), 400

    # --- 4. Tratamento de Delegação (CORRIGIDO) ---
    if 'delegated_to' in data:
        val = data['delegated_to']

        if val and val.strip():
            # CASO A: Delegar (tem nome)
            task.delegated_to = val
            # Só muda status se não estiver DONE
            if task.status != TaskStatus.DONE:
                task.status = TaskStatus.DELEGATED
        else:
            # CASO B: Reassumir (limpar delegação)
            # 🔥 CORREÇÃO: Permite limpar delegação SEMPRE que vier null/vazio
            # Isso resolve o bug de reassumir tarefas DONE
            task.delegated_to = None
            
            # Se estava DELEGATED, volta para ACTIVE
            if task.status == TaskStatus.DELEGATED:
                task.status = TaskStatus.ACTIVE

    # --- 5. Follow-up e Repetição ---
    if 'follow_up_date' in data:
        val = data['follow_up_date']
        task.follow_up_date = datetime.strptime(val, '%Y-%m-%d').date() if val else None

    if 'is_repeatable' in data: 
        task.is_repeatable = data['is_repeatable']
    if 'repeat_days' in data: 
        task.repeat_days = data['repeat_days']

    task.updated_at = datetime.utcnow()
    db.session.commit()

    return jsonify({'message': 'Tarefa atualizada', 'task': task.to_dict()})






@api_bp.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):

    """Excluir tarefa"""
    task = Task.query.get_or_404(task_id)
    TaskCompletion.query.filter_by(task_id=task_id).delete()

    db.session.delete(task)
    db.session.commit()

    return jsonify({'message': 'Tarefa excluída com sucesso'}), 200


# ==================== FOLLOW-UP (DELEGAÇÕES) ====================

@api_bp.route('/tasks/delegated', methods=['GET'])
def get_delegated_tasks():
    # ✅ CORREÇÃO: Filtro blindado. Garante que não é Nulo e nem Vazio.
    delegated = Task.query.filter(
        Task.delegated_to.isnot(None),
        Task.delegated_to != ""
    ).order_by(Task.follow_up_date.asc()).all()

    return jsonify({
        'total': len(delegated),
        'tasks': [task.to_dict() for task in delegated]
    }), 200




# ==================== STATS & DASHBOARD ====================

@api_bp.route('/stats/dashboard', methods=['GET'])
def get_dashboard_stats():
    """
    Retorna estatísticas da Tríade com insights para o Dashboard.
    Parâmetro: period = 'week' ou 'month'
    """
    period = request.args.get('period', 'week')
    
    if period not in ['week', 'month']:
        return jsonify({'error': "Parâmetro 'period' deve ser 'week' ou 'month'"}), 400
    
    try:
        today = date.today()
        
        # Calcular intervalo de datas baseado no período
        if period == 'week':
            # Segunda-feira da semana atual
            start_date = today - timedelta(days=today.weekday())
            # Domingo da semana atual
            end_date = start_date + timedelta(days=6)
        else:  # month
            # Primeiro dia do mês atual
            start_date = today.replace(day=1)
            # Último dia do mês atual
            if today.month == 12:
                end_date = today.replace(day=31)
            else:
                end_date = (today.replace(month=today.month + 1, day=1) - timedelta(days=1))
        
        # ✅ CORREÇÃO: Buscar tarefas concluídas incluindo repetíveis
                
        # 1. Tarefas normais DONE com completed_at
        normal_tasks = Task.query.filter(
            Task.status == TaskStatus.DONE,
            Task.completed_at.isnot(None),
            Task.completed_at >= datetime.combine(start_date, datetime.min.time()),
            Task.completed_at <= datetime.combine(end_date, datetime.max.time()),
            Task.is_repeatable == False
        ).all()

        # 2. Tarefas repetíveis com conclusões no período
        repeatable_tasks = Task.query.filter(
            Task.is_repeatable == True
        ).all()

        # 3. Construir lista completa de tarefas concluídas
        all_done_tasks = list(normal_tasks)

        for rep_task in repeatable_tasks:
            # Buscar conclusões no intervalo
            completions = TaskCompletion.query.filter(
                TaskCompletion.task_id == rep_task.id,
                TaskCompletion.status == TaskStatus.DONE,
                TaskCompletion.date >= start_date,
                TaskCompletion.date <= end_date
            ).all()

            # Criar tarefa virtual para cada conclusão
            for completion in completions:
                virtual_task = Task(
                    id=rep_task.id,
                    title=rep_task.title,
                    triad_category=rep_task.triad_category,
                    duration_minutes=rep_task.duration_minutes,
                    status=TaskStatus.DONE,
                    date_scheduled=completion.date,
                    is_repeatable=True
                )
                all_done_tasks.append(virtual_task)

        # Calcular minutos por categoria (usando all_done_tasks)
        urgent_minutes = sum(t.duration_minutes for t in all_done_tasks if t.triad_category == TriadCategory.URGENT)
        important_minutes = sum(t.duration_minutes for t in all_done_tasks if t.triad_category == TriadCategory.IMPORTANT)
        circumstantial_minutes = sum(t.duration_minutes for t in all_done_tasks if t.triad_category == TriadCategory.CIRCUMSTANTIAL)
        

        total_minutes = urgent_minutes + important_minutes + circumstantial_minutes
        
        # Calcular porcentagens
        if total_minutes > 0:
            urgent_pct = round((urgent_minutes / total_minutes) * 100, 1)
            important_pct = round((important_minutes / total_minutes) * 100, 1)
            circumstantial_pct = round((circumstantial_minutes / total_minutes) * 100, 1)
        else:
            urgent_pct = important_pct = circumstantial_pct = 0.0
        
        # Determinar Insight (diagnóstico)
        insight = _calculate_insight(urgent_pct, important_pct, circumstantial_pct)
        
        return jsonify({
            'period': period,
            'date_range': {
                'start': start_date.isoformat(),
                'end': end_date.isoformat()
            },
            'total_minutes_done': total_minutes,
            'distribution': {
                'IMPORTANT': important_pct,
                'URGENT': urgent_pct,
                'CIRCUMSTANTIAL': circumstantial_pct
            },
            'insight': insight
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def _calculate_insight(urgent_pct, important_pct, circumstantial_pct):
    """
    Calcula o insight baseado nas porcentagens da Tríade.
    
    Regras:
    - FIREFIGHTER: URGENT > 30%
    - PROCRASTINATOR: CIRCUMSTANTIAL > 20%
    - EQUILIBRIUM: IMPORTANT > 60% E (URGENT < 30% E CIRCUMSTANTIAL < 20%)
    - UNDEFINED: Caso contrário
    """
    
    # Regra 1: Firefighter (Bombeiro)
    if urgent_pct > 30:
        return {
            'type': 'FIREFIGHTER',
            'title': 'Apagando Incêndios',
            'message': 'Cuidado! Semana reativa. Você está apagando incêndios. Tente antecipar o Importante antes que vire Urgente.',
            'color_hex': '#E53935'  # Vermelho
        }
    
    # Regra 2: Procrastinator (Procrastinador)
    if circumstantial_pct > 20:
        return {
            'type': 'PROCRASTINATOR',
            'title': 'Alerta de Foco',
            'message': 'Alerta de Foco! Muito tempo desperdiçado. Aprenda a dizer "não" e elimine distrações.',
            'color_hex': '#FFC107'  # Amarelo/Laranja
        }
    
    # Regra 3: Equilibrium (Equilíbrio)
    if important_pct > 60 and urgent_pct < 30 and circumstantial_pct < 20:
        return {
            'type': 'EQUILIBRIUM',
            'title': 'No Comando',
            'message': 'Excelente! Você está construindo seu futuro. A maior parte do tempo foi investida em resultados.',
            'color_hex': '#4CAF50'  # Verde
        }
    
    # Regra 4: Undefined (Indefinido)
    return {
        'type': 'UNDEFINED',
        'title': 'Tríade Desbalanceada',
        'message': 'Sua tríade está desbalanceada. Tente focar mais no Importante.',
        'color_hex': '#9E9E9E'  # Cinza
    }


# ==================== HISTÓRICO ====================

@api_bp.route('/tasks/history', methods=['GET'])
def get_tasks_history():
    """
    Retorna histórico de tarefas concluídas com paginação e busca.
    
    Query Params:
    - page: Número da página (default: 1)
    - per_page: Itens por página (default: 20)
    - search: Termo de busca no título (opcional, case-insensitive)
    """
    
    # Parâmetros de paginação
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    search_term = request.args.get('search', '').strip()
    
    try:
        # ✅ PASSO 1: Buscar tarefas NORMAIS concluídas (com completed_at)
        normal_tasks = Task.query.filter(
            Task.status == TaskStatus.DONE,
            Task.completed_at.isnot(None),
            Task.is_repeatable == False  # Apenas não-repetíveis
        ).all()

        # ✅ PASSO 2: Buscar tarefas REPETÍVEIS com conclusões registradas
        repeatable_tasks = Task.query.filter(
            Task.is_repeatable == True
        ).all()

        # ✅ PASSO 3: Expandir repetíveis com base em TaskCompletion
        all_completed_tasks = []
        
        # Adicionar tarefas normais
        for task in normal_tasks:
            all_completed_tasks.append({
                'id': task.id,
                'title': task.title,
                'triad_category': task.triad_category.value,
                'duration_minutes': task.duration_minutes,
                'completed_at': task.completed_at,
                'date_scheduled': task.date_scheduled,
                'context_tag': task.context_tag,
                'role_tag': task.role_tag
            })

        # Adicionar instâncias de repetíveis
        for rep_task in repeatable_tasks:
            # Buscar todas as datas em que foi marcada como DONE
            completions = TaskCompletion.query.filter_by(
                task_id=rep_task.id,
                status=TaskStatus.DONE
            ).all()

            for completion in completions:
                # Criar entrada virtual para cada data concluída
                all_completed_tasks.append({
                    'id': rep_task.id,
                    'title': rep_task.title,
                    'triad_category': rep_task.triad_category.value,
                    'duration_minutes': rep_task.duration_minutes,
                    'completed_at': completion.completed_at or datetime.combine(completion.date, datetime.min.time()),
                    'date_scheduled': completion.date,
                    'context_tag': rep_task.context_tag,
                    'role_tag': rep_task.role_tag
                })

        # ✅ PASSO 4: Filtrar por busca (se fornecido)
        if search_term:
            all_completed_tasks = [
                t for t in all_completed_tasks 
                if search_term.lower() in t['title'].lower()
            ]

        # ✅ PASSO 5: Ordenar por completed_at (mais recentes primeiro)
        all_completed_tasks.sort(key=lambda t: t['completed_at'], reverse=True)

        # ✅ PASSO 6: Paginação manual
        total_items = len(all_completed_tasks)
        start_idx = (page - 1) * per_page
        end_idx = start_idx + per_page
        paginated_tasks = all_completed_tasks[start_idx:end_idx]

        # Converter completed_at para string
        for task in paginated_tasks:
            task['completed_at'] = task['completed_at'].isoformat()
            task['date_scheduled'] = task['date_scheduled'].isoformat()

        total_pages = (total_items + per_page - 1) // per_page  # Ceil division

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



# ==================== TAREFAS SEMANAIS (CORRIGIDO) ====================
@api_bp.route('/tasks/weekly', methods=['GET'])
def get_weekly_tasks():
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    if not start_date or not end_date:
        return jsonify({'error': 'start_date e end_date são obrigatórios'}), 400
    
    try:
        start = datetime.strptime(start_date, '%Y-%m-%d').date()
        end = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        # ✅ CORREÇÃO: Exclui QUALQUER tarefa com delegated_to preenchido
        # Não importa se está ACTIVE, DONE ou DELEGATED
        tasks = Task.query.filter(
            Task.date_scheduled >= start,
            Task.date_scheduled <= end,
            # Exclui se tem delegado (não importa o status)
            or_(
                Task.delegated_to == None,
                Task.delegated_to == ""
            )
        ).order_by(Task.date_scheduled, Task.triad_category).all()

        # Configurações diárias
        daily_configs = {}
        current_date = start
        while current_date <= end:
            config = DailyConfig.query.filter_by(date=current_date).first()
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


# ==================== ARQUIVAR/LIMPAR HISTÓRICO ULTIMOS 90 DIAS ====================

@api_bp.route('/tasks/cleanup', methods=['POST'])
def cleanup_old_tasks():
    """Remove tarefas DONE com mais de 90 dias"""
    from datetime import timedelta
    cutoff_date = date.today() - timedelta(days=90)
    
    deleted = Task.query.filter(
        Task.status == TaskStatus.DONE,
        Task.date_scheduled < cutoff_date
    ).delete()
    
    db.session.commit()
    return jsonify({'message': f'{deleted} tarefas antigas removidas'}), 200



# ==================== BACKUP ====================
@api_bp.route('/backup/create', methods=['POST'])
def create_backup():
    """Criar backup manual do banco de dados"""
    try:
        backup_path = backup_database()
        return jsonify({
            'message': 'Backup criado com sucesso',
            'backup_file': backup_path
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@api_bp.route('/backup/list', methods=['GET'])
def list_available_backups():
    """Listar backups disponíveis"""
    try:
        backups = list_backups()
        return jsonify({
            'total': len(backups),
            'backups': backups
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@api_bp.route('/backup/restore', methods=['POST'])
def restore_from_backup():
    """Restaurar banco de um backup específico"""
    data = request.get_json()
    
    if 'filename' not in data:
        return jsonify({'error': 'Campo filename obrigatório'}), 400
    
    try:
        result = restore_backup(data['filename'])
        return jsonify(result), 200
    except FileNotFoundError as e:
        return jsonify({'error': str(e)}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
