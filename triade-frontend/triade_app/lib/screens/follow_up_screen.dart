import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/widgets/task_card.dart';
import 'package:triade_app/widgets/user_avatar_menu.dart';
import 'package:triade_app/config/constants.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => FollowUpScreenState();
}

class FollowUpScreenState extends State<FollowUpScreen> {
  @override
  void initState() {
    super.initState();
  }

  void onBecameVisible() {
    _loadDelegatedTasks();
  }

  Future<void> _loadDelegatedTasks() async {
    if (!mounted) return;
    await context.read<TaskProvider>().loadDelegatedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppConstants.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
              left: 16,
              right: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Follow-up de Delegações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const UserAvatarMenu(
                  radius: 22,
                  showBorder: true,
                  borderColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
  child: Consumer<TaskProvider>(
    builder: (context, provider, child) {
      // ✅ Só mostra loading se não tiver dados ainda
      if (provider.isLoading && provider.delegatedTasks.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (provider.errorMessage != null && provider.delegatedTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDelegatedTasks,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      }

      final delegatedTasks = provider.delegatedTasks;

      if (delegatedTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma tarefa delegada',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarefas delegadas aparecerão aqui',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      final overdue = <dynamic>[];
      final today = <dynamic>[];
      final upcoming = <dynamic>[];
      final noDate = <dynamic>[];

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      for (var task in delegatedTasks) {
        if (task.followUpDate == null) {
          noDate.add(task);
        } else {
          final followUpDate = DateTime(
            task.followUpDate!.year,
            task.followUpDate!.month,
            task.followUpDate!.day,
          );

          if (followUpDate.isBefore(todayDate)) {
            overdue.add(task);
          } else if (followUpDate.isAtSameMomentAs(todayDate)) {
            today.add(task);
          } else {
            upcoming.add(task);
          }
        }
      }

      return RefreshIndicator(
        onRefresh: _loadDelegatedTasks,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildStatsCard(delegatedTasks.length, overdue.length),
            if (overdue.isNotEmpty)
              _buildSection('🔴 Atrasadas', overdue, Colors.red),
            if (today.isNotEmpty)
              _buildSection('🟡 Follow-up Hoje', today, Colors.orange),
            if (upcoming.isNotEmpty)
              _buildSection('🟢 Próximas', upcoming, Colors.green),
            if (noDate.isNotEmpty)
              _buildSection('⚪ Sem Data Definida', noDate, Colors.grey),
          ],
        ),
      );
    },
  ),
),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int total, int overdue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.forward, 'Total Delegadas', total.toString()),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem(Icons.warning, 'Atrasadas', overdue.toString(),
              color: overdue > 0 ? Colors.red[300] : Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: (color ?? Colors.white).withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List tasks, Color color) {
    tasks.sort((a, b) {
      if (a.followUpDate == null && b.followUpDate == null) return 0;
      if (a.followUpDate == null) return 1;
      if (b.followUpDate == null) return -1;
      return a.followUpDate!.compareTo(b.followUpDate!);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => Column(
          children: [
            TaskCard(
              task: task,
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showFollowUpDialog(task);
              },
              onDelete: () async {
                await context.read<TaskProvider>().deleteTask(task.id);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Delegada para: ${task.delegatedTo ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      task.followUpDate != null
                          ? DateFormat('dd/MM').format(task.followUpDate!)
                          : 'Sem data',
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Future<void> _showFollowUpDialog(dynamic task) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Follow-up: ${task.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delegado para: ${task.delegatedTo}'),
          const SizedBox(height: 8),
          if (task.followUpDate != null)
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(task.followUpDate!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          const Text('O que deseja fazer?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 'DONE'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Concluída'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 'ACTIVE'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Reassumir'),
        ),
      ],
    ),
  );

  if (result != null && mounted) {
    final provider = context.read<TaskProvider>();
    
    if (result == 'ACTIVE') {
      // 🔥 CORREÇÃO: Reassumir tarefa DONE
      // Precisa PRIMEIRO voltar para ACTIVE, DEPOIS limpar delegação
      if (task.status == TaskStatus.done) {
        // Passo 1: Voltar para ACTIVE
        await provider.updateTask(task.id, {'status': 'ACTIVE'});
        
        // Passo 2: Limpar delegação (agora funciona porque não é mais DONE)
        await provider.updateTask(task.id, {'delegated_to': null});
      } else {
        // Se já estiver ACTIVE, só limpar delegação
        await provider.updateTask(task.id, {'delegated_to': null});
      }
      
      // Optimistic Update - Remove da lista visualmente
      setState(() {
        provider.delegatedTasks.removeWhere((t) => t.id == task.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa reassumida'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // Marcar como DONE
      await provider.updateTask(task.id, {'status': result});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa marcada como concluída'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
}