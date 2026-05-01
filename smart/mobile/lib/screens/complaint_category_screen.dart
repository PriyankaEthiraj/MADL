import 'package:flutter/material.dart';
import 'complaint_create_screen.dart';

class ComplaintCategoryScreen extends StatefulWidget {
  const ComplaintCategoryScreen({super.key});

  @override
  State<ComplaintCategoryScreen> createState() => _ComplaintCategoryScreenState();
}

class _ComplaintCategoryScreenState extends State<ComplaintCategoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Road Maintenance',
      'icon': Icons.engineering,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Public Toilet & Sanitation',
      'icon': Icons.cleaning_services,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Street Light',
      'icon': Icons.light_mode,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Public Transport – Bus',
      'icon': Icons.directions_bus_filled,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Water Supply',
      'icon': Icons.opacity,
      'color': const Color(0xFF06B6D4),
    },
    {
      'name': 'Garbage & Waste Management',
      'icon': Icons.recycling,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Others',
      'icon': Icons.category,
      'color': const Color(0xFF6B7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Complaint',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF9FAFB).withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a category to continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280).withValues(alpha: 0.7),
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Category List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryCard(
                      name: category['name'],
                      icon: category['icon'],
                      color: category['color'],
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                ComplaintCreateScreen(category: category['name']),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = 0.0;
                              const end = 1.0;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end).chain(
                                CurveTween(curve: curve),
                              );
                              return FadeTransition(
                                opacity: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isHovered
                        ? widget.color.withValues(alpha: 0.3)
                        : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: widget.color.withValues(alpha: 0.1),
                    highlightColor: widget.color.withValues(alpha: 0.05),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Main Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Row(
                              children: [
                                // Left Side - Icon Container
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: widget.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.color.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: widget.color,
                                    size: 26,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Right Side - Content
                                Expanded(
                                  child: Text(
                                    widget.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                      height: 1.3,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Right Chevron Arrow
                                Icon(
                                  Icons.chevron_right,
                                  color: _isHovered
                                      ? widget.color
                                      : const Color(0xFF9CA3AF),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                          
                          // Bottom Hover Strip
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isHovered
                                      ? [
                                          widget.color.withValues(alpha: 0.8),
                                          widget.color,
                                        ]
                                      : [
                                          Colors.transparent,
                                          Colors.transparent,
                                        ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
