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

  // Acre Details
  int _numberOfAcres = 1;
  String _selectedSoilType = MockDataService.soilTypes.first;
  String _selectedCropType = MockDataService.cropTypes.first;

  // Zone Details (List of acres, each containing a list of zones with node configurations)
  final List<Map<String, dynamic>> _acresConfig = [];

  @override
  void initState() {
    super.initState();
    _rebuildAcresConfig();
  }
  void _rebuildAcresConfig() {
    final oldConfig = List.of(_acresConfig);
    _acresConfig.clear();
    for (int i = 0; i < _numberOfAcres; i++) {
      if (i < oldConfig.length) {
        _acresConfig.add(oldConfig[i]);
      } else {
        // Enforce 4 Zones strictly per Acre, each having 3 nodes (Start, Mid, End)
        _acresConfig.add({
          'name': 'Acre ${i + 1}',
          'zones': [
            {'name': 'Zone 1', 'startNode': 'Node-${i + 1}A-S', 'midNode': 'Node-${i + 1}A-M', 'endNode': 'Node-${i + 1}A-E'},
            {'name': 'Zone 2', 'startNode': 'Node-${i + 1}B-S', 'midNode': 'Node-${i + 1}B-M', 'endNode': 'Node-${i + 1}B-E'},
            {'name': 'Zone 3', 'startNode': 'Node-${i + 1}C-S', 'midNode': 'Node-${i + 1}C-M', 'endNode': 'Node-${i + 1}C-E'},
            {'name': 'Zone 4', 'startNode': 'Node-${i + 1}D-S', 'midNode': 'Node-${i + 1}D-M', 'endNode': 'Node-${i + 1}D-E'},
          ]
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage == 1) {
      // Rebuild zones right before moving to the zones configuration page
      _rebuildAcresConfig();
    }

    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishSetup() async {
    final auth = ref.read(authProvider);
    final userId = auth.userId ?? 'demo-user-001';
    final api = ref.read(apiServiceProvider);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
    );

    try {
      // 1. Create Farm
      final farmData = await api.createFarm(
        _farmNameController.text.trim(),
        _farmLocationController.text.trim(),
        userId,
      );
      final farmId = farmData['id'].toString();

      // 2. Create Acres and Zones sequentially
      for (var acreEntry in _acresConfig) {
        final acreData = await api.createAcre(
          farmId,
          acreEntry['name'],
          1.0, // Default size 1.0 per acre for now
        );
        final acreId = acreData['id'].toString();

        final List zones = acreEntry['zones'];
        for (var zoneEntry in zones) {
          await api.createZone(
            acreId: acreId,
            name: zoneEntry['name'],
            cropType: _selectedCropType,
            soilType: _selectedSoilType,
            startNode: zoneEntry['startNode'],
            midNode: zoneEntry['midNode'],
            endNode: zoneEntry['endNode'],
          );
        }
      }

      // 3. Refresh Provider & Navigate
      await ref.read(farmProvider.notifier).reloadAfterSetup();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildStep1FarmDetails(),
                  _buildStep2SoilAndCrop(),
                  _buildStep3Acres(),
                  _buildStep4HardwareMapping(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.emerald : AppColors.emerald.withAlpha(30),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _prevPage,
              child: const Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox(width: 80), // spacer
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              children: [
                Text(
                  _currentPage == 3 ? 'Complete Setup' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STEPS ===================== //

  Widget _buildStepWrapper(String title, String subtitle, Widget child) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 48),
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1FarmDetails() {
    return _buildStepWrapper(
      'Welcome to AquaSol',
      "Let's set up your intelligent farm.",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Farm Name', _farmNameController, LucideIcons.tent),
          const SizedBox(height: 24),
          _buildTextField('Location / Region', _farmLocationController, LucideIcons.mapPin),
        ],
      ),
    );
  }

  Widget _buildStep2SoilAndCrop() {
    return _buildStepWrapper(
      'Profile Configuration',
      'Tell the AI about your soil and primary crop.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Soil Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildDropdown(_selectedSoilType, MockDataService.soilTypes, (val) => setState(() => _selectedSoilType = val!)),
          const SizedBox(height: 32),
          const Text('Primary Crop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildDropdown(_selectedCropType, MockDataService.cropTypes, (val) => setState(() => _selectedCropType = val!)),
        ],
      ),
    );
  }

  Widget _buildStep3Acres() {
    return _buildStepWrapper(
      'Farm Size',
      'How many acres are you actively monitoring limit is 10?',
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularBtn(LucideIcons.minus, () {
                if (_numberOfAcres > 1) setState(() => _numberOfAcres--);
              }),
              Text('\$_numberOfAcres', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900)),
              _buildCircularBtn(LucideIcons.plus, () {
                if (_numberOfAcres < 10) setState(() => _numberOfAcres++);
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Acres', style: TextStyle(fontSize: 24, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStep4HardwareMapping() {
    return _buildStepWrapper(
      'Hardware Mapping',
      'Name your 4 zones per acre and configure sensors for Start, Middle, and End positions.',
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _acresConfig.length,
        itemBuilder: (context, acreIndex) {
          final acre = _acresConfig[acreIndex];
          final List<Map<String, dynamic>> zones = List.from(acre['zones']);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: AppColors.textSecondary.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: acre['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Acre Name',
                          isDense: true,
                          border: InputBorder.none,
                          icon: const Icon(LucideIcons.edit2, size: 16, color: AppColors.emerald),
                        ),
                        onChanged: (val) => acre['name'] = val,
                      ),
                    ),
                    const Text('4 Zones', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
                const Divider(height: 32),
                ...zones.asMap().entries.map((entry) {
                  final zone = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 16, color: AppColors.emerald),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: zone['name'],
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Zone Name',
                                  isDense: true,
                                ),
                                onChanged: (val) => zone['name'] = val,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: zone['startNode'],
                                decoration: InputDecoration(
                                  labelText: 'Start Node',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => zone['startNode'] = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: zone['midNode'],
                                decoration: InputDecoration(
                                  labelText: 'Mid Node',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => zone['midNode'] = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: zone['endNode'],
                                decoration: InputDecoration(
                                  labelText: 'End Node',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => zone['endNode'] = val,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== HELPERS ===================== //

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.emerald),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, color: AppColors.emerald),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _buildCircularBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.emerald.withAlpha(20), blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Icon(icon, color: AppColors.emerald, size: 32),
      ),
    );
  }
}
