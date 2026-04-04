import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/services/mock_data_service.dart';
import 'package:aquasol_app/providers/farm_provider.dart';
import 'package:aquasol_app/providers/auth_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Farm Details
  final _farmNameController = TextEditingController(text: 'My Aqua Farm');
  final _farmLocationController = TextEditingController(text: 'California, USA');

  // Dynamic Config
  int _numberOfAcres = 1;
  int _zonesPerAcre = 4;
  int _nodesPerZone = 3; // Brand new dynamic parameter
  String _selectedSoilType = MockDataService.soilTypes.first;
  String _selectedCropType = MockDataService.cropTypes.first;

  // Zone Details (List of acres, each containing a list of zones with node configurations)
  final List<Map<String, dynamic>> _acresConfig = [];

  @override
  void initState() {
    super.initState();
    _syncAcresConfig();
  }

  void _syncAcresConfig() {
    setState(() {
      final oldConfig = List.of(_acresConfig);
      _acresConfig.clear();
      for (int i = 0; i < _numberOfAcres; i++) {
        if (i < oldConfig.length) {
          final acre = oldConfig[i];
          final List<Map<String, dynamic>> zones = List.from(acre['zones']);
          
          if (zones.length < _zonesPerAcre) {
            for (int k = zones.length; k < _zonesPerAcre; k++) {
              zones.add({
                'name': 'Zone ${k + 1}',
                'nodes': List.generate(_nodesPerZone, (nIdx) => 'Node-${i + 1}${String.fromCharCode(65 + k)}-${nIdx + 1}'),
              });
            }
          } else if (zones.length > _zonesPerAcre) {
            zones.removeRange(_zonesPerAcre, zones.length);
          }

          // Force array length sync for nodes per zone inside existing zones
          for (var z in zones) {
            List<String> nodes = List.from(z['nodes'] ?? []);
            if (nodes.length < _nodesPerZone) {
               for (int n = nodes.length; n < _nodesPerZone; n++) {
                 nodes.add('Node-${i + 1}-Extra-${n+1}');
               }
            } else if (nodes.length > _nodesPerZone) {
               nodes.removeRange(_nodesPerZone, nodes.length);
            }
            z['nodes'] = nodes;
          }

          acre['zones'] = zones;
          _acresConfig.add(acre);
        } else {
          // New Acre entirely
          List<Map<String, dynamic>> zones = [];
          for (int k = 0; k < _zonesPerAcre; k++) {
            zones.add({
              'name': 'Zone ${k + 1}',
              'nodes': List.generate(_nodesPerZone, (nIdx) => 'Node-${i + 1}${String.fromCharCode(65 + k)}-${nIdx + 1}'),
            });
          }
          _acresConfig.add({
            'name': 'Acre ${i + 1}',
            'zones': zones,
          });
        }
      }
    });
  }

  void _nextPage() {
    if (_currentPage == 2) {
      _syncAcresConfig();
    }

    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      _finishSetup();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      )
    );
  }

  Future<void> _finishSetup() async {
      final auth = ref.read(authProvider);
      final userId = auth.userId;
      if (userId == null) {
        _showError("Identity verification failed. Please re-authenticate.");
        return;
      }
      final api = ref.read(apiServiceProvider);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => _buildMagicMoment(),
    );

    try {
      final farmData = await api.createFarm(_farmNameController.text.trim(), _farmLocationController.text.trim(), userId);
      final farmId = farmData['id'].toString();

      for (var acreEntry in _acresConfig) {
        final acreData = await api.createAcre(farmId, acreEntry['name'], 1.0);
        final acreId = acreData['id'].toString();

        final List zones = acreEntry['zones'];
        for (var zoneEntry in zones) {
          final List<String> stringNodes = List<String>.from(zoneEntry['nodes']);
          // Because API takes specific named args originally, we will just pack them or use the newly upgraded API mapping.
          // Wait, we need to pass nodes via API. We will use a dynamically created map for the backend upgrade!
          await api.createZone(
            acreId: acreId,
            name: zoneEntry['name'],
            cropType: _selectedCropType,
            soilType: _selectedSoilType,
            // Fallback for older interface, but we will upgrade api.createZone too
            nodes: stringNodes,
          );
        }
      }

      await ref.read(farmProvider.notifier).reloadAfterSetup();
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close overlay
        _showError('Registration failed: $e');
      }
    }
  }

  Widget _buildMagicMoment() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.brandGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoomIn(child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 80)),
            const SizedBox(height: 24),
            FadeInUp(child: const Text('Initializing AI Ecosystem...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            const SizedBox(width: 200, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.white24)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.70, 1.0]
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildStep1FarmDetails(),
                      _buildStep2SoilAndCrop(),
                      _buildStep3PrecisionCounts(),
                      _buildStep4HardwareMapping(),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isActive = index <= _currentPage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: isActive ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]) : null,
                    color: isActive ? null : Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: const Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox(width: 40),
          
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ).copyWith(
              elevation: const WidgetStatePropertyAll(0),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x6622C55E), blurRadius: 20, offset: Offset(0, 6))],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: [
                    Text(_currentPage == 3 ? 'Deploy Farm' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWrapper(String title, String subtitle, Widget child) {
    bool isFirstPageDarkHeader = _currentPage == 0; // if it sits on the gradient
    return FadeInRight(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: isFirstPageDarkHeader ? Colors.white : AppColors.textPrimary, letterSpacing: -1)),
            const SizedBox(height: 12),
            Text(subtitle, style: TextStyle(fontSize: 17, color: isFirstPageDarkHeader ? Colors.white70 : AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 48),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1FarmDetails() {
    return _buildStepWrapper(
      'Brand Identity',
      'Give your autonomous ecosystem a name and location.',
      Column(
        children: [
          _buildPremiumField('Farm Identity', _farmNameController, LucideIcons.tent),
          const SizedBox(height: 24),
          _buildPremiumField('Geographic Region', _farmLocationController, LucideIcons.map),
        ],
      ),
    );
  }

  Widget _buildStep2SoilAndCrop() {
    return _buildStepWrapper(
      'Biological Profile',
      'The AI uses soil composition and crop genetics to calculate dynamic ET rates.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Soil Character', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildPremiumDropdown(_selectedSoilType, MockDataService.soilTypes, (val) => setState(() => _selectedSoilType = val!)),
          const SizedBox(height: 32),
          const Text('Primary Genetics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildPremiumDropdown(_selectedCropType, MockDataService.cropTypes, (val) => setState(() => _selectedCropType = val!)),
        ],
      ),
    );
  }

  Widget _buildStep3PrecisionCounts() {
    return _buildStepWrapper(
      'Precision Metrics',
      'Define the scale of your monitoring.',
      SingleChildScrollView(
        child: Column(
          children: [
            _buildCounterCard('Acre Coverage', _numberOfAcres, 1, 10, (v) => setState(() => _numberOfAcres = v), LucideIcons.maximize),
            const SizedBox(height: 24),
            _buildCounterCard('Zones per Acre', _zonesPerAcre, 1, 8, (v) => setState(() => _zonesPerAcre = v), LucideIcons.grid),
            const SizedBox(height: 24),
            _buildCounterCard('Nodes per Zone', _nodesPerZone, 1, 10, (v) => setState(() => _nodesPerZone = v), LucideIcons.cpu),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))]),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.growthMid, size: 20),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Total monitoring points: \${_numberOfAcres * _zonesPerAcre * _nodesPerZone} sensors', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4HardwareMapping() {
    return _buildStepWrapper(
      'Hardware Topography',
      'Configure the hardware IDs across your zones.',
      ListView.builder(
        itemCount: _acresConfig.length,
        padding: const EdgeInsets.only(bottom: 24),
        itemBuilder: (context, acreIdx) {
          final acre = _acresConfig[acreIdx];
          final List zones = acre['zones'];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(acre['name'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textMuted, fontSize: 12, letterSpacing: 2)),
              ),
              ...zones.map((zone) => _buildZoneMappingCard(zone)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZoneMappingCard(Map<String, dynamic> zone) {
    final List<String> nodes = List<String>.from(zone['nodes']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
                const Icon(LucideIcons.mapPin, color: AppColors.brandEmerald, size: 18),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(initialValue: zone['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary), decoration: const InputDecoration(isDense: true, border: InputBorder.none), onChanged: (v) => zone['name'] = v)),
             ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Wrap(
            spacing: 8,
            runSpacing: 16,
            children: List.generate(nodes.length, (nIdx) {
               return FractionallySizedBox(
                 widthFactor: nodes.length <= 3 ? (1.0 / nodes.length) - 0.05 : 0.3,
                 child: _buildNodeInput(nodes, nIdx, 'N-${nIdx + 1}')
               );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildNodeInput(List<String> nodes, int index, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: nodes[index],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
          ),
          onChanged: (v) => nodes[index] = v,
        ),
      ],
    );
  }

  Widget _buildCounterCard(String label, int value, int min, int max, Function(int) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1)), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.brandEmerald.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.brandEmerald)),
          const SizedBox(width: 20),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary))),
          _buildCircleBtn(LucideIcons.minus, () => value > min ? onChanged(value - 1) : null),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('\$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
          _buildCircleBtn(LucideIcons.plus, () => value < max ? onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(shape: BoxShape.circle, color: onTap == null ? const Color(0xFFF1F5F9) : AppColors.brandEmerald.withAlpha(20)), 
        child: Icon(icon, size: 20, color: onTap == null ? AppColors.textMuted : AppColors.brandEmerald)
      ),
    );
  }

  Widget _buildPremiumField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1)), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))]),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        decoration: InputDecoration(icon: Icon(icon, color: AppColors.brandEmerald, size: 22), labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600), border: InputBorder.none),
      ),
    );
  }

  Widget _buildPremiumDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1)), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))]),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
