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
  final _repeatDaysController = TextEditingController(text: '7');

  EnergyLevel _selectedEnergyLevel = EnergyLevel.renewal;
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
    _selectedEnergyLevel = task.energyLevel;
    _selectedContext = task.contextTag;
    _selectedDate = task.dateScheduled;
    _roleTagController.text = task.roleTag ?? '';
    _delegatedToController.text = task.delegatedTo ?? '';
    _isDelegated = task.delegatedTo != null && task.delegatedTo!.isNotEmpty;
    _followUpDate = task.followUpDate;

    _isRepeatable = task.isRepeatable;
    _originalIsRepeatable = task.isRepeatable;
    
    // ✅ CORREÇÃO: Preenche o campo de dias com o valor real da tarefa
    if (task.isRepeatable && task.repeatDays != null) {
      _repeatDaysController.text = task.repeatDays.toString();
    }
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
    final delegatedToText = _delegatedToController.text.trim();
    final isDelegated = delegatedToText.isNotEmpty;
    final delegatedToSend = isDelegated ? delegatedToText : "";
    final followUpToSend = isDelegated && _followUpDate != null 
        ? fmtDate(_followUpDate!) 
        : "";

    // 🔥 LÓGICA ESPECIAL: Converter repetível para normal
    if (widget.taskToEdit != null && 
        _originalIsRepeatable && 
        !_isRepeatable) {
      
      // 1. Deletar a repetível original
      await provider.deleteTask(widget.taskToEdit!.id);
      
      // 2. Criar nova tarefa normal
      final newTask = Task(
        id: 0,
        title: _titleController.text.trim(),
        energyLevel: _selectedEnergyLevel,
        durationMinutes: int.parse(_durationController.text),
        status: isDelegated ? TaskStatus.delegated : TaskStatus.active,
        dateScheduled: _selectedDate!,
        roleTag: _roleTagController.text.trim().isNotEmpty 
            ? _roleTagController.text.trim() 
            : null,
        contextTag: _selectedContext,
        delegatedTo: isDelegated ? delegatedToSend : null,
        followUpDate: followUpToSend.isNotEmpty ? _followUpDate : null,
        isRepeatable: false,
        repeatDays: null,
        repeatCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await provider.createTask(newTask);
      
      if (mounted) Navigator.pop(context, true);
      setState(() => _isLoading = false);
      return;
    }

    // Lógica normal
    final Map<String, dynamic> taskData = {
      'title': _titleController.text.trim(),
      'energy_level': _selectedEnergyLevel.value,
      'duration_minutes': int.parse(_durationController.text),
      'role_tag': _roleTagController.text.trim().isNotEmpty 
          ? _roleTagController.text.trim() 
          : null,
      'context_tag': _selectedContext,
      'delegated_to': delegatedToSend,
      'follow_up_date': followUpToSend,
      'is_repeatable': _isRepeatable,
      'repeat_days': _isRepeatable 
          ? (int.tryParse(_repeatDaysController.text) ?? 7) 
          : null,
    };

    // ✅ CORREÇÃO: Só altera o status se mudou a delegação
    // Se está editando e não mudou delegação, NÃO envia status
    if (widget.taskToEdit != null) {
      final wasDelegate = widget.taskToEdit!.delegatedTo != null && 
                          widget.taskToEdit!.delegatedTo!.isNotEmpty;
      
      // Só envia status se houve mudança na delegação
      if (wasDelegate != isDelegated) {
        taskData['status'] = isDelegated ? 'DELEGATED' : 'ACTIVE';
      }
      // Se não mudou delegação, não envia 'status' para preservar o atual
    } else {
      // Tarefa nova sempre define o status
      taskData['status'] = isDelegated ? 'DELEGATED' : 'ACTIVE';
    }

    if (widget.taskToEdit == null || !widget.taskToEdit!.isRepeatable) {
       taskData['date_scheduled'] = fmtDate(_selectedDate!);
    }

    if (widget.taskToEdit != null) {
      success = await provider.updateTask(widget.taskToEdit!.id, taskData);
    } else {
      taskData['repeat_count'] = 0;
      final newTask = Task(
        id: 0,
        title: taskData['title'],
        energyLevel: _selectedEnergyLevel,
        durationMinutes: taskData['duration_minutes'],
        status: isDelegated ? TaskStatus.delegated : TaskStatus.active,
        dateScheduled: _selectedDate!,
        roleTag: taskData['role_tag'],
        contextTag: taskData['context_tag'],
        delegatedTo: isDelegated ? delegatedToSend : null,
        followUpDate: followUpToSend.isNotEmpty ? _followUpDate : null,
        isRepeatable: taskData['is_repeatable'],
        repeatDays: taskData['repeat_days'],
        repeatCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await provider.createTask(newTask);
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



  bool _isFutureTask() {
    if (widget.taskToEdit == null) return false;
    final now = DateTime.now();
    // Normaliza para meia-noite para comparar apenas datas
    final today = DateTime(now.year, now.month, now.day);
    final tDate = widget.taskToEdit!.dateScheduled;
    final taskDay = DateTime(tDate.year, tDate.month, tDate.day);
    return taskDay.isAfter(today);
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
                    DropdownButtonFormField<EnergyLevel>(
                      value: _selectedEnergyLevel,
                      decoration: const InputDecoration(
                        labelText: 'Nível de Energia *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.battery_charging_full),
                      ),
                      items: EnergyLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: level.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(level.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEnergyLevel = value!);
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
                      // ✅ CORREÇÃO: Bloqueia o campo se a tarefa for repetível
                      enabled: !_isRepeatable,
                      decoration: InputDecoration(
                        labelText: 'Delegar para',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.forward),
                        hintText: 'Nome da pessoa',
                        // Visual cinza para indicar que está bloqueado
                        filled: _isRepeatable,
                        fillColor: _isRepeatable ? Colors.grey.shade200 : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isDelegated = value.trim().isNotEmpty;
                          // Segurança extra: se digitou algo, desliga o repetível
                          if (_isDelegated) _isRepeatable = false;
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
                      value: _isRepeatable,
                      // Trava se estiver delegada OU se for tarefa futura
                      onChanged: (_isDelegated || _isFutureTask())
                          ? null
                          : (v) => setState(() => _isRepeatable = v),
                    ),


                    // ✅ NOVO CAMPO: Dias de Repetição (Só aparece se for repetível)
                    if (_isRepeatable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: TextFormField(
                          controller: _repeatDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Repetir por quantos dias?',
                            hintText: 'Ex: 7',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                            helperText: 'Define a duração do ciclo de repetição',
                          ),
                          validator: (value) {
                            if (_isRepeatable) {
                              if (value == null || value.isEmpty) return 'Informe os dias';
                              final n = int.tryParse(value);
                              if (n == null || n < 1) return 'Mínimo 1 dia';
                            }
                            return null;
                          },
                        ),
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
