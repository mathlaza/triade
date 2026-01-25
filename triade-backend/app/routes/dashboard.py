"""
Dashboard Routes - Estatísticas e insights

Endpoints:
- GET /stats/dashboard - Estatísticas da Tríade com insights
"""

from flask import request, jsonify
from datetime import datetime, timedelta
from app.routes import api_bp
from app.models import Task, EnergyLevel, TaskStatus, TaskCompletion, get_brazil_time
from app.auth import token_required


@api_bp.route('/stats/dashboard', methods=['GET'])
@token_required
def get_dashboard_stats(current_user):
    """
    Retorna estatísticas da Tríade com insights para o Dashboard.
    Parâmetro: period = 'week' ou 'month'
    """
    period = request.args.get('period', 'week')
    
    if period not in ['week', 'month']:
        return jsonify({'error': "Parâmetro 'period' deve ser 'week' ou 'month'"}), 400
    
    try:
        today = get_brazil_time().date()
        
        if period == 'week':
            start_date = today - timedelta(days=today.weekday())
            end_date = start_date + timedelta(days=6)
        else:
            start_date = today.replace(day=1)
            if today.month == 12:
                end_date = today.replace(day=31)
            else:
                end_date = (today.replace(month=today.month + 1, day=1) - timedelta(days=1))
        
        # Tarefas normais DONE
        normal_tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.status == TaskStatus.DONE,
            Task.completed_at.isnot(None),
            Task.completed_at >= datetime.combine(start_date, datetime.min.time()),
            Task.completed_at <= datetime.combine(end_date, datetime.max.time()),
            Task.is_repeatable == False
        ).all()

        # Tarefas repetíveis
        repeatable_tasks = Task.query.filter(
            Task.user_id == current_user.id,
            Task.is_repeatable == True
        ).all()

        all_done_tasks = list(normal_tasks)

        for rep_task in repeatable_tasks:
            completions = TaskCompletion.query.filter(
                TaskCompletion.user_id == current_user.id,
                TaskCompletion.task_id == rep_task.id,
                TaskCompletion.status == TaskStatus.DONE,
                TaskCompletion.date >= start_date,
                TaskCompletion.date <= end_date
            ).all()

            for completion in completions:
                virtual_task = Task(
                    id=rep_task.id,
                    title=rep_task.title,
                    energy_level=rep_task.energy_level,
                    duration_minutes=rep_task.duration_minutes,
                    status=TaskStatus.DONE,
                    date_scheduled=completion.date,
                    is_repeatable=True
                )
                all_done_tasks.append(virtual_task)

        # Calcular minutos por categoria
        high_energy_minutes = sum(t.duration_minutes for t in all_done_tasks if t.energy_level == EnergyLevel.HIGH_ENERGY)
        renewal_minutes = sum(t.duration_minutes for t in all_done_tasks if t.energy_level == EnergyLevel.RENEWAL)
        low_energy_minutes = sum(t.duration_minutes for t in all_done_tasks if t.energy_level == EnergyLevel.LOW_ENERGY)

        total_minutes = high_energy_minutes + renewal_minutes + low_energy_minutes

        if total_minutes > 0:
            high_energy_pct = round((high_energy_minutes / total_minutes) * 100, 1)
            renewal_pct = round((renewal_minutes / total_minutes) * 100, 1)
            low_energy_pct = round((low_energy_minutes / total_minutes) * 100, 1)
        else:
            high_energy_pct = renewal_pct = low_energy_pct = 0.0
        
        insight = _calculate_insight(high_energy_pct, renewal_pct, low_energy_pct)
        
        return jsonify({
            'period': period,
            'date_range': {
                'start': start_date.isoformat(),
                'end': end_date.isoformat()
            },
            'total_minutes_done': total_minutes,
            'distribution': {
                'HIGH_ENERGY': high_energy_pct,
                'RENEWAL': renewal_pct,
                'LOW_ENERGY': low_energy_pct
            },
            'insight': insight
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def _calculate_insight(high_energy_pct, renewal_pct, low_energy_pct):
    """
    Calcula o insight baseado nas porcentagens dos Níveis de Energia.
    """
    
    # Burnout
    if high_energy_pct > 60:
        return {
            'type': 'BURNOUT',
            'title': 'Cuidado com Burnout',
            'message': f'Você está dedicando {high_energy_pct:.0f}% do tempo em tarefas de Alta Energia. Inclua pausas de Renovação para manter a produtividade sustentável e evitar esgotamento mental.',
            'color_hex': '#FF453A'
        }
    
    # Lazy
    if low_energy_pct > 50:
        return {
            'type': 'LAZY',
            'title': 'Foco Insuficiente',
            'message': f'{low_energy_pct:.0f}% do seu tempo está em tarefas de Baixa Energia. Reserve blocos dedicados para tarefas de Alta Energia e avance em projetos importantes.',
            'color_hex': '#FF9F0A'
        }
    
    # Negligenciando renovação
    if renewal_pct < 10 and (high_energy_pct + low_energy_pct) > 80:
        return {
            'type': 'NEGLECTING_RENEWAL',
            'title': 'Pause e Recarregue',
            'message': f'Apenas {renewal_pct:.0f}% do tempo em Renovação. Atividades como exercício, meditação ou hobbies são essenciais para manter energia e criatividade ao longo do tempo.',
            'color_hex': '#BF5AF2'
        }
    
    # Alta performance
    if high_energy_pct >= 35 and high_energy_pct <= 55 and renewal_pct >= 15:
        return {
            'type': 'HIGH_PERFORMER',
            'title': 'Excelente Equilíbrio',
            'message': f'Você está distribuindo bem sua energia: {high_energy_pct:.0f}% em foco, {renewal_pct:.0f}% em renovação. Continue alternando para manter alta performance sustentável.',
            'color_hex': '#32D74B'
        }
    
    # Balanced
    if renewal_pct >= 15 and high_energy_pct >= 25 and low_energy_pct <= 45:
        return {
            'type': 'BALANCED',
            'title': 'Ritmo Saudável',
            'message': 'Sua distribuição de energia está adequada. Continue alternando entre foco intenso, tarefas rotineiras e momentos de renovação.',
            'color_hex': '#30D158'
        }
    
    # Default
    return {
        'type': 'UNDEFINED',
        'title': 'Ajuste sua Energia',
        'message': f'Sua distribuição atual ({high_energy_pct:.0f}% alta, {low_energy_pct:.0f}% baixa, {renewal_pct:.0f}% renovação) pode ser otimizada. Busque mais equilíbrio entre as categorias.',
        'color_hex': '#8E8E93'
    }
