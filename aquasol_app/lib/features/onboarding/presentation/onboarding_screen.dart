import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/auth_provider.dart';
import 'package:aquasol_app/providers/farm_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _farmNameCtrl = TextEditingController(text: 'My AquaFarm');
  int _step = 0;
  bool _isSyncing = false;

  // Farm Data
  String _cropType   = 'Wheat';
  String _soilType   = 'Alluvial';
  double _growthStage = 0.45;
  int    _gridCols   = 2; // Zones per acre
  bool   _autoMode   = true;
  String _waterSource = 'Borewell';
  int    _acresCount  = 1;
  final List<TextEditingController> _zoneNameCtrls = [];

  static const int _totalSteps = 7;

  @override
  void initState() {
    super.initState();
    _updateZoneCtrls();
  }

  void _updateZoneCtrls() {
    final totalZones = _acresCount * (_gridCols * _gridCols);
    while (_zoneNameCtrls.length < totalZones) {
      _zoneNameCtrls.add(TextEditingController());
    }
  }

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      await _submitData();
    }
  }

  Future<void> _submitData() async {
    setState(() => _isSyncing = true);
    final api = ref.read(apiServiceProvider);
    final userId = ref.read(authProvider).userId ?? "00000000-0000-0000-0000-000000000000";

    try {
      // 1. Create Farm
      final farm = await api.createFarm(_farmNameCtrl.text.trim(), "Punjab, India", userId);
      final farmId = farm['id'];

      // 2. Create Acres & Zones
      for (int i = 0; i < _acresCount; i++) {
        final acre = await api.createAcre(farmId, "Acre ${i + 1}", 4046.86);
        final acreId = acre['id'];

        // Zones for this acre
        final zonesInAcre = _gridCols * _gridCols;
        for (int j = 0; j < zonesInAcre; j++) {
          final ctrlIndex = (i * zonesInAcre) + j;
          final customName = _zoneNameCtrls[ctrlIndex].text.trim();
          final zoneName = customName.isEmpty ? "Zone ${i + 1}-${j + 1}" : customName;

          await api.createZone(
            acreId: acreId,
            name: zoneName,
            cropType: _cropType,
            soilType: _soilType,
          );
        }
      }

      // 3. Refresh Farm Provider and Navigate
      await ref.read(farmProvider.notifier).refresh();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: ${e.toString()}')),
        );
      }
    }
  }

  void _back() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _farmNameCtrl.dispose();
    for (var c in _zoneNameCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _stepFarm(),
                    _stepAcres(),
                    _stepCrop(),
                    _stepZone(),
                    _stepSensor(),
                    _stepIrrigation(),
                    _stepAiInit(),
                  ],
                ),
              ),
              if (!_isSyncing) _buildFooter(),
            ]),
          ),
          if (_isSyncing) _buildSyncingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSyncingOverlay() {
    return Container(
      color: Colors.black.withAlpha(150),
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.emerald),
              const SizedBox(height: 24),
              const Text(
                'Syncing your farm to AquaCloud...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aura is configuring your sensors and AI models.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Farm Setup', style: Theme.of(context).textTheme.headlineMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_step + 1} / $_totalSteps',
                style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.emerald,
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (_step > 0)
          TextButton.icon(
              onPressed: _back,
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Back'))
        else
          const SizedBox(width: 80),
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          child: Text(_step == _totalSteps - 1 ? '🚀  Start Farming' : 'Next  →'),
        ),
      ]),
    );
  }

  Widget _stepFarm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏡', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text("What's your farm called?", style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        TextFormField(
          controller: _farmNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Farm Name',
            hintText: 'e.g. Green Valley Estates',
            prefixIcon: Icon(LucideIcons.home, color: AppColors.emerald),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200)),
          child: ListTile(
            leading: const Icon(LucideIcons.mapPin, color: AppColors.info),
            title: const Text('Detected Location', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Punjab, India  (30.90°N  75.85°E)'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.emerald.withAlpha(26), borderRadius: BorderRadius.circular(20)),
              child: const Text('GPS', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stepAcres() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌾', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('How many acres?', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 48),
        Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _circleBtn(LucideIcons.minus, () => setState(() {
              _acresCount = (_acresCount - 1).clamp(1, 10);
              _updateZoneCtrls();
            })),
            const SizedBox(width: 28),
            Column(children: [
              Text('$_acresCount', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900)),
              const Text('Acres', style: TextStyle(color: AppColors.textSecondary)),
            ]),
            const SizedBox(width: 28),
            _circleBtn(LucideIcons.plus, () => setState(() {
              _acresCount = (_acresCount + 1).clamp(1, 10);
              _updateZoneCtrls();
            })),
          ]),
        ),
        const SizedBox(height: 32),
        _infoBox('Each acre is fixed at 1 Acre (4046.86 m²).', LucideIcons.info),
      ]),
    );
  }

  Widget _stepCrop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌱', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Crop Configuration', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        DropdownButtonFormField<String>(
          initialValue: _cropType,
          decoration: const InputDecoration(
            labelText: 'Primary Crop',
            prefixIcon: Icon(LucideIcons.sprout, color: AppColors.emerald),
          ),
          items: ['Wheat', 'Rice', 'Corn', 'Cotton', 'Sugarcane', 'Pulses']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _cropType = v ?? _cropType),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _soilType,
          decoration: const InputDecoration(
            labelText: 'Soil Type',
            prefixIcon: Icon(LucideIcons.layers, color: AppColors.emerald),
          ),
          items: ['Alluvial', 'Black', 'Sandy', 'Loamy', 'Clayey']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _soilType = v ?? _soilType),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Growth Stage', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            _growthStage < 0.33 ? 'Seedling' : _growthStage < 0.66 ? 'Vegetative' : 'Maturity',
            style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold),
          ),
        ]),
        Slider(value: _growthStage, onChanged: (v) => setState(() => _growthStage = v),
            activeColor: AppColors.emerald,
            inactiveColor: Colors.grey.shade200),
      ]),
    );
  }

  Widget _stepZone() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🗺️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Zone Configuration', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Row(children: [
          _gridChip('2×2', 2), const SizedBox(width: 8),
          _gridChip('3×3', 3),
        ]),
        const SizedBox(height: 16),
        const Text('Name your zones (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _acresCount * (_gridCols * _gridCols),
            itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: _zoneNameCtrls[i],
                    decoration: InputDecoration(
                      hintText: 'Zone ${i + 1} Name',
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
                    ),
                  ),
                );
            },
          ),
        ),
      ]),
    );
  }

  Widget _gridChip(String label, int cols) {
    final active = _gridCols == cols;
    return GestureDetector(
      onTap: () => setState(() {
        _gridCols = cols;
        _updateZoneCtrls();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.emerald : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.emerald),
        ),
        child: Text(label,
            style: TextStyle(color: active ? Colors.white : AppColors.emerald,
                fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _stepSensor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📡', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Sensor Mapping', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        _sensorTile('Node-88A', true, 'Zone 1'),
        _sensorTile('Node-92F', true, 'Zone 2'),
        _sensorTile('Node-15B', true, 'Zone 3'),
        _sensorTile('Node-09D', false, 'Unassigned'),
        const SizedBox(height: 20),
        _infoBox('Nodes are auto-detected via LoRa.', LucideIcons.checkCircle),
      ]),
    );
  }

  Widget _sensorTile(String node, bool active, String zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(LucideIcons.rss, color: active ? AppColors.emerald : AppColors.warning),
        title: Text(node, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(active ? 'Active · Transmitting' : 'Pending · Offline'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.emerald.withAlpha(26) : AppColors.warning.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(zone,
              style: TextStyle(
                  color: active ? AppColors.emerald : AppColors.warning,
                  fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _stepIrrigation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💧', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Irrigation Setup', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        const Text('Water Source', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, children: ['Borewell', 'Canal', 'Rain Harvesting']
            .map((s) => GestureDetector(
                  onTap: () => setState(() => _waterSource = s),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _waterSource == s ? AppColors.emerald : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _waterSource == s ? AppColors.emerald : Colors.grey.shade300),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            color: _waterSource == s ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                )).toList()),
        const SizedBox(height: 28),
        const Text('Operation Mode', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200)),
          child: SwitchListTile(
            value: _autoMode,
            onChanged: (v) => setState(() => _autoMode = v),
            title: Text(_autoMode ? 'AI Autonomous Mode' : 'Manual Control',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_autoMode ? 'Aura manages all decisions' : 'You control all valves'),
            activeTrackColor: AppColors.emerald,
          ),
        ),
      ]),
    );
  }

  Widget _stepAiInit() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SpinPerfect(
            infinite: true,
            duration: const Duration(seconds: 3),
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.emerald.withAlpha(80), blurRadius: 24, spreadRadius: 4)],
              ),
              child: const Icon(LucideIcons.brain, size: 52, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),
          FadeInDown(child: Text('Initializing Aura AI...',
              style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Aura is analyzing soil patterns, crop requirements,\nand weather forecasts to build your irrigation model.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          ...[
            ('Calibrating soil sensors', true),
            ('Training zone moisture model', true),
            ('Generating prediction engine', false),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(e.$2 ? LucideIcons.checkCircle : LucideIcons.loader,
                  size: 16, color: e.$2 ? AppColors.emerald : AppColors.warning),
              const SizedBox(width: 10),
              Text(e.$1,
                  style: TextStyle(
                      color: e.$2 ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: e.$2 ? FontWeight.w600 : FontWeight.normal)),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.emerald.withAlpha(26),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.emerald.withAlpha(60)),
        ),
        child: Icon(icon, color: AppColors.emerald, size: 22),
      ),
    );
  }

  Widget _infoBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withAlpha(50)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.info, size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.info, fontSize: 13))),
      ]),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: child,
    );
  }
}
