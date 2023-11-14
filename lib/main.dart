import 'dart:math';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

part 'main.g.dart';

late Box<List<String>> taskBox;
late Box<List> choreBox;
late Box<List> weightBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive
    ..init((await getApplicationDocumentsDirectory()).path)
    ..registerAdapter(ChoreAdapter())
    ..registerAdapter(WeightDataAdapter());
  taskBox = await Hive.openBox<List<String>>('taskList');
  choreBox = await Hive.openBox<List>('choreBox');
  weightBox = await Hive.openBox<List>('weightList');
  runApp(const MyApp());
}

@HiveType(typeId: 1)
class WeightData {
  WeightData({
    required this.weight,
    required this.date,
  });

  @HiveField(0)
  double weight;
  @HiveField(1)
  DateTime date;
}

@HiveType(typeId: 0)
class Chore {
  Chore({
    required this.name,
    required this.isDone,
  });

  @HiveField(0)
  String name;
  @HiveField(1)
  bool isDone;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  late List<Chore> chores;

  late List<WeightData> progressData;

  @override
  void initState() {
    super.initState();
    chores = choreBox.containsKey(0)
        ? (choreBox.getAt(0) ?? []).cast<Chore>()
        : <Chore>[];
    progressData = weightBox.containsKey(0)
        ? (weightBox.getAt(0) ?? []).cast<WeightData>()
        : <WeightData>[];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade200,
          toolbarHeight: 40,
          title: const Text(
            'Tummy Tracker',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        body: Container(
          height: double.infinity,
          color: _selectedIndex == 0 ? Colors.teal.shade50 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _selectedIndex == 0
                ? ProgressView(
                    chores: chores,
                    progressData: progressData,
                    onChoreTap: (index) async {
                      setState(() {
                        chores[index].isDone = !chores[index].isDone;
                      });
                      await choreBox.putAll({0: chores});
                    },
                  )
                : _selectedIndex == 1
                    ? const ChoreView()
                    : const WeightTrackingView(),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Progresso',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Tarefas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center),
                label: 'Pesagem',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue.shade800,
            onTap: (index) {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
                if (_selectedIndex == 0) {
                  chores = choreBox.containsKey(0)
                      ? (choreBox.getAt(0) ?? []).cast<Chore>()
                      : <Chore>[];
                }
              }
            }),
      );
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    required this.progressData,
    super.key,
  });

  final List<WeightData> progressData;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: false,
                ),
                titlesData: const FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                maxY: progressData.isNotEmpty
                    ? progressData
                            .map((e) => e.weight)
                            .reduce(max)
                            .roundToDouble() +
                        5
                    : 100,
                minY: progressData.isNotEmpty
                    ? progressData
                            .map((e) => e.weight)
                            .reduce(min)
                            .roundToDouble() -
                        5
                    : 40,
                lineBarsData: [
                  LineChartBarData(
                    spots: progressData.indexed
                        .mapIndexed((index, item) =>
                            FlSpot(index.toDouble(), item.$2.weight))
                        .toList(),
                    isCurved: true,
                    gradient: const LinearGradient(colors: [
                      Colors.lightBlue,
                      Colors.blueAccent,
                      Colors.blue
                    ]),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class ProgressView extends StatelessWidget {
  const ProgressView({
    required this.chores,
    required this.progressData,
    required this.onChoreTap,
    super.key,
  });

  final List<Chore> chores;
  final List<WeightData> progressData;
  final void Function(int) onChoreTap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progresso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ProgressCard(
              progressData: progressData,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tarefas Diárias',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              itemCount: chores.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  onChoreTap(index);
                },
                child: Card(
                  color: chores[index].isDone
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(chores[index].name),
                        Icon(chores[index].isDone ? Icons.check : Icons.close,
                            color: chores[index].isDone
                                ? Colors.green
                                : Colors.red,
                            size: 24)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class ChoreView extends StatefulWidget {
  const ChoreView({super.key});

  @override
  State<ChoreView> createState() => _ChoreViewState();
}

class _ChoreViewState extends State<ChoreView> {
  late TextEditingController _controller;
  List<String> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasks = taskBox.get('taskList') ?? [];
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Tarefa'),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(_controller.text);
                  });
                  await taskBox.put('taskList', _tasks);
                  final chores = (choreBox.containsKey(0)
                      ? choreBox.getAt(0)!.cast<Chore>()
                      : <Chore>[]);
                  // ignore: cascade_invocations
                  chores.add(Chore(name: _controller.text, isDone: false));
                  await choreBox.putAll({0: chores});
                  _controller.text = '';
                }

                FocusScope.of(context).unfocus();
              },
              child: const Text(
                'Adicionar tarefa',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            ..._tasks.mapIndexed(
              (index, task) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(task),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final chores = (choreBox.containsKey(0)
                              ? choreBox.getAt(0)!.cast<Chore>()
                              : <Chore>[])
                            ..removeAt(index);
                          await choreBox.putAll({0: chores});
                          setState(() {
                            _tasks.removeAt(index);
                          });
                          await taskBox.put('taskList', _tasks);
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class WeightTrackingView extends StatefulWidget {
  const WeightTrackingView({super.key});

  @override
  State<WeightTrackingView> createState() => _WeightTrackingViewState();
}

class _WeightTrackingViewState extends State<WeightTrackingView> {
  late TextEditingController _controller;
  List<WeightData> _weightList = [];

  @override
  void initState() {
    super.initState();
    _weightList = weightBox.containsKey(0)
        ? (weightBox.getAt(0) ?? []).cast<WeightData>()
        : <WeightData>[];
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Peso'),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                final value = double.tryParse(_controller.text);
                if (_controller.text.isNotEmpty && value != null) {
                  final weightData =
                      WeightData(weight: value, date: DateTime.now());

                  setState(() {
                    _weightList.add(weightData);
                  });

                  final weightList = (weightBox.containsKey(0)
                      ? weightBox.getAt(0)!.cast<WeightData>()
                      : <WeightData>[]);
                  // ignore: cascade_invocations
                  weightList.add(weightData);
                  await weightBox.putAll({0: weightList});
                  _controller.text = '';
                }

                FocusScope.of(context).unfocus();
              },
              child: const Text(
                'Adicionar peso',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            ..._weightList.mapIndexed(
              (index, weightData) => Card(
                color: Colors.blue.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Peso: ${weightData.weight}'),
                      const Spacer(),
                      Text(
                          'em ${weightData.date.day}/${weightData.date.month}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
