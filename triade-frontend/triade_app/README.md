-- PERSISTIR TAREFAS rrepetiveis futuras marcadas como done no backeend. Arquivos:
app\models.py
app\routes.py
triade_app\lib\services\api_service.dart
triade_app\lib\providers\task_provider.dart
triade_app\lib\models\task.dart


-- Dashboard com gráficos + Histórico
O coração do método é saber se você está vivendo na esfera da Importância, Urgência ou Circunstância.

Feature: Um gráfico de pizza simples na tela inicial ou perfil.
Lógica: O app calcula o tempo das tarefas concluídas. Se o usuário fez 5 tarefas urgentes de 1 hora cada, o gráfico mostra que o dia dele foi 100% reativo. Isso gera o "choque de realidade" que o método propõe.