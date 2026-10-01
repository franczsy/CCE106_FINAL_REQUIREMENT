import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/cloudinary_service.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/supabase_config.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  bool _sidebarCollapsed = false;
  final _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requireAdmin());
  }

  void _requireAdmin() {
    if (supabaseAnonKey.isEmpty) {
      if (mounted) context.go('/login?mode=staff');
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? user?.appMetadata['role'];
    if (!mounted || role?.toString().toLowerCase() == 'admin') return;
    context.go('/login?mode=staff');
  }

  void _showReports(double sales, int orderCount) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total orders: $orderCount'),
            const SizedBox(height: 8),
            Text('Total sales: ₱${sales.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  Future<void> _showAddDishDialog() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const _AddDishDialog(),
    );
    if (product != null) {
      ref.read(productsProvider.notifier).add(product);
    }
  }

  Future<void> _editDish(Product product) async {
    final updatedProduct = await showDialog<Product>(
      context: context,
      builder: (_) => _EditDishDialog(product: product),
    );
    if (updatedProduct != null) {
      ref.read(productsProvider.notifier).update(updatedProduct);
    }
  }

  Future<void> _removeDish(Product product) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove dish?'),
        content: Text('Remove ${product.name} from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (shouldRemove == true) {
      ref.read(productsProvider.notifier).remove(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final orders = ref.watch(ordersProvider);
    final sales = orders.where((o) => o.status != OrderStatus.cancelled).fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _sidebarCollapsed ? 92 : 220,
              color: const Color(0xFF151D28),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!_sidebarCollapsed)
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text('Canteen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                        ),
                      IconButton(
                        onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                        tooltip: _sidebarCollapsed ? 'Show sidebar' : 'Hide sidebar',
                        icon: Icon(_sidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    active: true,
                    collapsed: _sidebarCollapsed,
                    onTap: () => Scrollable.ensureVisible(context, alignment: 0, duration: const Duration(milliseconds: 250)),
                  ),
                  _SidebarItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    collapsed: _sidebarCollapsed,
                    onTap: () => context.push('/kitchen'),
                  ),
                  _SidebarItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Pickup',
                    collapsed: _sidebarCollapsed,
                    onTap: () => context.push('/pickup'),
                  ),
                  _SidebarItem(
                    icon: Icons.fastfood_rounded,
                    label: 'Products',
                    collapsed: _sidebarCollapsed,
                    onTap: () {
                      final menuContext = _menuKey.currentContext;
                      if (menuContext != null) {
                        Scrollable.ensureVisible(menuContext, duration: const Duration(milliseconds: 250));
                      }
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    collapsed: _sidebarCollapsed,
                    onTap: () => _showReports(sales, orders.length),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _sidebarCollapsed
                            ? const Icon(Icons.home_rounded, color: Colors.white)
                            : const Text('Back to site', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    const Text('Product Environment', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2330),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.cloud_done_rounded, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Cloud name', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                          const Text('jbxtv7p', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 18),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('Go to API Keys'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2330),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded, color: Colors.white70),
                          const SizedBox(width: 12),
                          const Text('Today sales', style: TextStyle(color: Colors.white70)),
                          const Spacer(),
                          Text('₱${sales.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('Plan Current Usage', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2330),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Credit usage for last 30 days', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFFF26A6A), size: 10),
                                    SizedBox(width: 8),
                                    Text('Plan ahead as you grow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('0 / 25', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 18),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Upgrade Plan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _UsageStat('Image Impressions', '0', Icons.image_rounded),
                        const SizedBox(width: 14),
                        _UsageStat('Transformations', '0', Icons.auto_fix_high_rounded),
                        const SizedBox(width: 14),
                        _UsageStat('Bandwidth', '0 B', Icons.speed_rounded),
                        const SizedBox(width: 14),
                        _UsageStat('Storage', '0 B', Icons.storage_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Menu', key: _menuKey, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _showAddDishDialog,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('ADD DISH'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonal(
                          onPressed: () => context.push('/pos'),
                          child: const Text('Cashier POS'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...products.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2330),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: p.imageUrl != null
                                ? Image.network(p.imageUrl!, width: 74, height: 74, fit: BoxFit.cover)
                                : p.imageBytes == null
                                    ? Container(
                                        width: 74,
                                        height: 74,
                                        alignment: Alignment.center,
                                        color: const Color(0xFF2D3748),
                                        child: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                                      )
                                    : Image.memory(p.imageBytes!, width: 74, height: 74, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(p.description.isEmpty ? p.category : '${p.category} • ${p.description}', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₱${p.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit dish',
                                    onPressed: () => _editDish(p),
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove dish',
                                    onPressed: () => _removeDish(p),
                                    icon: const Icon(Icons.delete_outline, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.collapsed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2B313E) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: active ? Colors.white : Colors.white70, size: 18),
              if (!collapsed) const SizedBox(width: 10),
              if (!collapsed)
                Expanded(
                  child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _UsageStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2330),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDishDialog extends StatefulWidget {
  const _AddDishDialog();

  @override
  State<_AddDishDialog> createState() => _AddDishDialogState();
}

class _AddDishDialogState extends State<_AddDishDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  String _category = 'Meals';
  XFile? _image;
  String? _imageError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() { _image = image; _imageError = null; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      setState(() => _imageError = 'Upload a photo of the dish');
      return;
    }

    setState(() => _imageError = null);

    final bytes = await _image!.readAsBytes();
    final uploadedUrl = await CloudinaryService.uploadImage(
      bytes: bytes,
      fileName: _image!.name,
      folder: 'canteen/menu',
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      Product(
        id: 'p-${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        emoji: '🍽️',
        imageBytes: uploadedUrl == null ? bytes : null,
        imageUrl: uploadedUrl,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add dish'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: Text(_image == null ? 'UPLOAD DISH PHOTO' : 'CHANGE PHOTO'),
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              FutureBuilder<List<int>>(
                future: _image!.readAsBytes(),
                builder: (_, snapshot) => snapshot.hasData
                    ? Image.memory(Uint8List.fromList(snapshot.data!), height: 120, fit: BoxFit.cover)
                    : const SizedBox(height: 120),
              ),
            ],
            if (_imageError != null) Text(_imageError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Dish name *'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a dish name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price *', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                return price == null || price < 0 ? 'Enter a valid price' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Meals', 'Snacks', 'Drinks', 'Desserts'].map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: _submit, child: const Text('ADD DISH')),
      ],
    );
  }
}

class _EditDishDialog extends StatefulWidget {
  final Product product;

  const _EditDishDialog({required this.product});

  @override
  State<_EditDishDialog> createState() => _EditDishDialogState();
}

class _EditDishDialogState extends State<_EditDishDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  final _picker = ImagePicker();
  late String _category;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _category = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _image = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    Uint8List? bytes;
    if (_image != null) {
      bytes = await _image!.readAsBytes();
    } else {
      bytes = widget.product.imageBytes;
    }

    String? uploadedUrl;
    if (_image != null) {
      uploadedUrl = await CloudinaryService.uploadImage(
        bytes: bytes!,
        fileName: _image!.name,
        folder: 'canteen/menu',
      );
      if (uploadedUrl != null) {
        bytes = null;
      }
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      Product(
        id: widget.product.id,
        name: _nameController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        emoji: widget.product.emoji,
        imageBytes: uploadedUrl == null ? bytes : null,
        imageUrl: uploadedUrl ?? widget.product.imageUrl,
        description: _descriptionController.text.trim(),
        available: widget.product.available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit dish'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.product.imageBytes != null && _image == null)
              Image.memory(widget.product.imageBytes!, height: 120, fit: BoxFit.cover),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: Text(_image == null ? 'REPLACE PHOTO (OPTIONAL)' : 'PHOTO SELECTED'),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Dish name *'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a dish name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price *', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                return price == null || price < 0 ? 'Enter a valid price' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Meals', 'Snacks', 'Drinks', 'Desserts'].map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: _submit, child: const Text('SAVE CHANGES')),
      ],
    );
  }
}

