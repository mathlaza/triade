import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/screens/add_task_screen.dart';

class PendingReviewModal extends StatelessWidget {
  final List<Task> tasks;

  const PendingReviewModal({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Bloqueia fechar com botão voltar
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ritual do Boot',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você tem tarefas de ontem não concluídas. Decida o que fazer:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: task.energyLevel.color, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Reagendar
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddTaskScreen(
                                            selectedDate: DateTime.now(),
                                            taskToEdit: task,
                                          ),
                                        ),
                                      );
                                      if (result == true && context.mounted) {
                                        _removeFromList(context, task.id);
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: const Text('Reagendar', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Delegar
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showDelegateDialog(context, task);
                                    },
                                    icon: const Icon(Icons.forward, size: 16),
                                    label: const Text('Delegar', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Excluir
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _deleteTask(context, task.id);
                                    },
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Excluir', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDelegateDialog(BuildContext context, Task task) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delegar Tarefa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da pessoa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome obrigatório';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = context.read<TaskProvider>();
                await provider.updateTask(task.id, {
                  'delegated_to': nameController.text.trim(),
                  'status': 'DELEGATED',
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _removeFromList(context, task.id);
                }
              }
            },
            child: const Text('Delegar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, int taskId) async {
    final provider = context.read<TaskProvider>();
    await provider.deleteTask(taskId);
    _removeFromList(context, taskId);
  }

  void _removeFromList(BuildContext context, int taskId) {
    tasks.removeWhere((t) => t.id == taskId);
    if (tasks.isEmpty && context.mounted) {
      Navigator.pop(context);
    }
  }
}
