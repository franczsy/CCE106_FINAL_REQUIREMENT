import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
                                                          import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../core/supabase_config.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) setState(() {});
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabaseAnonKey.isEmpty
        ? null
        : Supabase.instance.client.auth.currentUser;
    final studentName = currentUser?.userMetadata?['full_name']
        ?.toString()
        .trim();
    final studentLabel = studentName == null || studentName.isEmpty
        ? 'Student account'
        : studentName;
    final isAdmin = currentUser?.appMetadata['role']
        ?.toString()
        .toLowerCase() ==
      'admin';
    final products = ref.watch(productsProvider);
    final productSections = {
      'Meals': products
          .where((product) => product.category == 'Meals')
          .toList(),
      'Drinks': products
          .where((product) => product.category == 'Drinks')
          .toList(),
      'Snacks': products
          .where(
            (product) =>
                product.category == 'Snacks' || product.category == 'Desserts',
          )
          .toList(),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('University of Mindanao'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/student'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Order'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What are you craving?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Fresh canteen favorites, ready when you are.'),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  for (final section in productSections.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.key,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  mainAxisExtent: 230,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: section.value.length,
                            itemBuilder: (context, index) {
                              final product = section.value[index];
                              final menuCategory =
                                  product.category == 'Desserts'
                                  ? 'Snacks'
                                  : product.category;
                              return _FoodCard(
                                productName: product.name,
                                price: product.price,
                                emoji: product.emoji,
                                imageBytes: product.imageBytes,
                                imageUrl: product.imageUrl,
                                onTap: () => context.push(
                                  '/student?category=$menuCategory',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final accountActions = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      if (currentUser == null) ...[
                        OutlinedButton.icon(
                          onPressed: () => context.push('/login?mode=student'),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Student sign in'),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.push('/login?mode=staff'),
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Staff login'),
                        ),
                      ] else if (isAdmin) ...[
                        OutlinedButton.icon(
                          onPressed: () => context.go('/admin'),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Admin dashboard'),
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: () => context.push('/student'),
                          icon: const Icon(Icons.person_outline),
                          label: Text(studentLabel),
                        ),
                    ],
                  );

                  if (currentUser == null) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: accountActions,
                    );
                  }

                  final signOutButton = TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  );

                  if (constraints.maxWidth < 430) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: signOutButton,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: accountActions,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [signOutButton, const Spacer(), accountActions],
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

class _FoodCard extends StatelessWidget {
  final String productName;
  final double price;
  final String emoji;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onTap;

  const _FoodCard({
    required this.productName,
    required this.price,
    required this.emoji,
    this.imageBytes,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        )
                      : imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Text(emoji, style: const TextStyle(fontSize: 68)),
                        )
                      : Text(emoji, style: const TextStyle(fontSize: 68)),
                ),
              ),
              Text(
                productName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₱${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  