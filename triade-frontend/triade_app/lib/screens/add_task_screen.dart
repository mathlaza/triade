import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? taskToEdit;

  const AddTaskScreen({
    super.key,
    required this.selectedDate,
    this.taskToEdit,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _roleTagController = TextEditingController();
  final _delegatedToController = TextEditingController();

  TriadCategory _selectedCategory = TriadCategory.important;
  String? _selectedContext;
  DateTime? _selectedDate;
  DateTime? _followUpDate;
  bool _isRepeatable = false;
  bool _originalIsRepeatable = false; // trava o valor ao editar
  bool _isDelegated = false; // VARIÁVEL ADICIONADA
  bool _isLoading = false;

  @override
void initState() {
  super.initState();

  _selectedDate = widget.selectedDate;

  if (widget.taskToEdit != null) {
    final task = widget.taskToEdit!;
    _titleController.text = task.title;
    _durationController.text = task.durationMinutes.toString();
    _selectedCategory = task.triadCategory;
    _selectedContext = task.contextTag;
    _selectedDate = task.dateScheduled;
    _roleTagController.text = task.roleTag ?? '';
    _delegatedToController.text = task.delegatedTo ?? '';
    _isDelegated = task.delegatedTo != null && task.delegatedTo!.isNotEmpty;
    _followUpDate = task.followUpDate;

    _isRepeatable = task.isRepeatable;
    _originalIsRepeatable = task.isRepeatable; // ✅ trava ao editar
  } else {
    _originalIsRepeatable = _isRepeatable;
  }

  _delegatedToController.addListener(() {
    final delegatedNow = _delegatedToController.text.trim().isNotEmpty;
    if (delegatedNow != _isDelegated) {
      setState(() => _isDelegated = delegatedNow);
    }
  });
}


  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _roleTagController.dispose();
    _delegatedToController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final provider = context.read<TaskProvider>();

  String fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool success = false;

  try {
    // ✅ EDITAR
    if (widget.taskToEdit != null) {
      final editing = widget.taskToEdit!;

      // ✅ EDITAR REPETÍVEL: NÃO ENVIA date_scheduled / is_repeatable / repeat_count
      if (editing.isRepeatable) {
        final delegatedTo = _delegatedToController.text.trim().isNotEmpty
            ? _delegatedToController.text.trim()
            : null;

        final updates = <String, dynamic>{
          'title': _titleController.text.trim(),
          'triad_category': _selectedCategory.value,
          'duration_minutes': int.parse(_durationController.text),
          'role_tag': _roleTagController.text.trim().isNotEmpty ? _roleTagController.text.trim() : null,
          'context_tag': _selectedContext,
          'delegated_to': delegatedTo,
          'follow_up_date': _followUpDate != null ? fmtDate(_followUpDate!) : null,
          'status': delegatedTo != null ? 'DELEGATED' : 'ACTIVE',
        };

        success = await provider.updateTask(editing.id, updates);
      } else {
        // ✅ EDITAR NORMAL
        final task = Task(
          id: editing.id,
          title: _titleController.text.trim(),
          triadCategory: _selectedCategory,
          durationMinutes: int.parse(_durationController.text),
          status: _delegatedToController.text.trim().isNotEmpty ? TaskStatus.delegated : TaskStatus.active,
          dateScheduled: _selectedDate!,
          roleTag: _roleTagController.text.trim().isNotEmpty ? _roleTagController.text.trim() : null,
          contextTag: _selectedContext,
          delegatedTo: _delegatedToController.text.trim().isNotEmpty ? _delegatedToController.text.trim() : null,
          followUpDate: _followUpDate,
          isRepeatable: editing.isRepeatable,
          repeatCount: editing.repeatCount,
          createdAt: editing.createdAt,
          updatedAt: DateTime.now(),
        );

        success = await provider.updateTask(editing.id, task.toJson());
      }
    } else {
      // ✅ CRIAR
      final task = Task(
        id: 0,
        title: _titleController.text.trim(),
        triadCategory: _selectedCategory,
        durationMinutes: int.parse(_durationController.text),
        status: _delegatedToController.text.trim().isNotEmpty ? TaskStatus.delegated : TaskStatus.active,
        dateScheduled: _selectedDate!,
        roleTag: _roleTagController.text.trim().isNotEmpty ? _roleTagController.text.trim() : null,
        contextTag: _selectedContext,
        delegatedTo: _delegatedToController.text.trim().isNotEmpty ? _delegatedToController.text.trim() : null,
        followUpDate: _followUpDate,
        isRepeatable: _isRepeatable,
        repeatCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      success = await provider.createTask(task);
    }
  } finally {
    setState(() => _isLoading = false);
  }

  if (success) {
    if (mounted) Navigator.pop(context, true);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao salvar tarefa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Editar Tarefa' : 'Nova Tarefa'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Título obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoria da Tríade
                    DropdownButtonFormField<TriadCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria da Tríade *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: TriadCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duração
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duração (minutos) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        hintText: 'Ex: 60',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Duração obrigatória';
                        }
                        final duration = int.tryParse(value);
                        if (duration == null || duration < AppConstants.minTaskDuration) {
                          return 'Mínimo ${AppConstants.minTaskDuration} minutos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Data
                    ListTile(
  title: const Text('Data Agendada *'),
  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
  leading: const Icon(Icons.calendar_today),
  trailing: Icon(
    (widget.taskToEdit != null && widget.taskToEdit!.isRepeatable) ? Icons.lock : Icons.edit,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: Colors.grey[400]!),
  ),
  onTap: (widget.taskToEdit != null && widget.taskToEdit!.isRepeatable)
      ? null
      : () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate!,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (date != null) {
            setState(() => _selectedDate = date);
          }
        },
),

                    const SizedBox(height: 16),

                    // Contexto
                    // ... (código anterior)

                    // Contexto
                    DropdownButtonFormField<String>(
                      value: _selectedContext,
                      decoration: const InputDecoration(
                        labelText: 'Contexto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Nenhum'),
                        ),
                        // ✅ CORREÇÃO: Usar ContextColors.colors.keys para listar os contextos
                        ...ContextColors.colors.keys.map((contextTag) {
                          final color = ContextColors.getColor(contextTag);
                          return DropdownMenuItem(
                            value: contextTag,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(contextTag),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedContext = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Role Tag
                    TextFormField(
                      controller: _roleTagController,
                      decoration: const InputDecoration(
                        labelText: 'Papel/Função',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Ex: Pai, Gestor, Atleta',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delegação
                    TextFormField(
                      controller: _delegatedToController,
                      decoration: const InputDecoration(
                        labelText: 'Delegar para',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.forward),
                        hintText: 'Nome da pessoa',
                      ),
                      onChanged: (value) {
  setState(() {
    _isDelegated = value.trim().isNotEmpty;
    if (_isDelegated) _isRepeatable = false; // ✅ força desligar
  });
},
                    ),
                    const SizedBox(height: 16),

                    // Follow-up Date (só aparece se delegado)
                    if (_isDelegated)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Esta tarefa foi delegada. Defina quando você vai fazer o follow-up.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _followUpDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() => _followUpDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _followUpDate != null
                                            ? 'Follow-up: ${DateFormat('dd/MM/yyyy').format(_followUpDate!)}'
                                            : 'Definir data de follow-up',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _followUpDate != null ? Colors.black87 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isDelegated) const SizedBox(height: 16),

                    // Repetível
                    SwitchListTile(
  title: const Text('Tarefa repetível'),
  value: widget.taskToEdit != null ? _originalIsRepeatable : _isRepeatable,
  onChanged: (widget.taskToEdit != null || _isDelegated)
      ? null
      : (v) => setState(() => _isRepeatable = v),
),

                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          widget.taskToEdit != null ? 'Atualizar' : 'Criar Tarefa',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
