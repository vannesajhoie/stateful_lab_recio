import 'package:flutter/material.dart';

// Dark pink used as the main color of the whole app.
const Color kDarkPink = Color(0xFFAD1457);

void main() => runApp(
      MaterialApp(
        title: 'Mini Shopping Cart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Dark pink theme: seed generates matching light pink shades,
          // and primary is forced to the exact dark pink.
          colorScheme: ColorScheme.fromSeed(seedColor: kDarkPink).copyWith(
            primary: kDarkPink,
            onPrimary: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const CartScreen(),
      ),
    );

// ---------------- MODEL ----------------
// name and price never change; quantity and gotIt are changeable (not final).
class CartItem {
  final String name;
  final double price;
  int quantity;
  bool gotIt;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.gotIt = false,
  });
}

// ---------------- STATEFUL SCREEN ----------------
// Stateful because the items, totals and form errors change while the app runs.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // The State owns the list of items.
  final List<CartItem> _items = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Error messages shown under the TextFields (null = no error).
  String? _nameError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    // Preload 3 sample items.
    _items.addAll([
      CartItem(name: 'Rice', price: 60.00, quantity: 2),
      CartItem(name: 'Eggs', price: 8.00, quantity: 12),
      CartItem(name: 'Milk', price: 95.00, quantity: 1),
    ]);
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory.
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Plus button: stops at 99.
  void _increase(int i) {
    setState(() {
      if (_items[i].quantity < 99) {
        _items[i].quantity++;
      }
    });
  }

  // Minus button: never goes below 1.
  void _decrease(int i) {
    setState(() {
      if (_items[i].quantity > 1) {
        _items[i].quantity--;
      }
    });
  }

  // Checkbox: flip the gotIt value.
  void _toggle(int i) {
    setState(() {
      _items[i].gotIt = !_items[i].gotIt;
    });
  }

  // Validate the form, then add the item if everything is valid.
  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    setState(() {
      _nameError = name.isEmpty ? 'Name cannot be empty' : null;
      _priceError =
          (price == null || price <= 0) ? 'Enter a number greater than 0' : null;

      if (_nameError == null && _priceError == null) {
        _items.add(CartItem(name: name, price: price!));
        _nameController.clear();
        _priceController.clear();
      }
    });
  }

  // Remove every item that is marked "got it".
  void _clearChecked() {
    setState(() {
      _items.removeWhere((item) => item.gotIt);
    });
  }

  // Sum of price x quantity for all items.
  double get _total =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  int get _gotCount => _items.where((item) => item.gotIt).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Shopping Cart'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ListView inside Expanded to avoid unbounded height error.
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        return CartItemTile(
                          item: _items[i],
                          onIncrease: () => _increase(i),
                          onDecrease: () => _decrease(i),
                          onToggle: () => _toggle(i),
                        );
                      },
                    ),
            ),

            // ---------- Summary bar ----------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items: ${_items.length}  •  Got it: $_gotCount'),
                  Text(
                    'Total: PHP ${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Add item form ----------
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Item name',
                              border: const OutlineInputBorder(),
                              errorText: _nameError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Price',
                              border: const OutlineInputBorder(),
                              errorText: _priceError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _addItem,
                            child: const Text('Add'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearChecked,
                            child: const Text('Clear checked'),
                          ),
                        ),
                      ],
                    ),
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

// ---------------- STATELESS CHILD ----------------
// Stateless: it only draws the item it receives and calls the callbacks; the parent owns the state.
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onToggle;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: item.gotIt,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // line-through when checked
                      decoration:
                          item.gotIt ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    'PHP ${item.price.toStringAsFixed(2)} each',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrease,
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}