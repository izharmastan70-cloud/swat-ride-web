import 'package:flutter/material.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  bool promoEnabled = true;

  String promoCode = 'SWAT50';
  double discountPercent = 10;
  double maxDiscount = 500;
  double minimumFare = 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Code & Discount'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Promo Status
          Card(
            child: SwitchListTile(
              title: const Text(
                'Promo Code Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                promoEnabled
                    ? 'Promo code is currently ON'
                    : 'Promo code is currently OFF',
              ),
              value: promoEnabled,
              onChanged: (value) {
                setState(() {
                  promoEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Promo Code
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Promo Code'),
              subtitle: Text(promoCode),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _editPromoCode();
              },
            ),
          ),

          const SizedBox(height: 12),

          // Discount Percentage
          Card(
            child: ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('Discount Percentage'),
              subtitle: Text(
                '${discountPercent.toStringAsFixed(0)}%',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _editDiscount();
              },
            ),
          ),

          const SizedBox(height: 12),

          // Maximum Discount
          Card(
            child: ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Maximum Discount'),
              subtitle: Text(
                'Rs. ${maxDiscount.toStringAsFixed(0)}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _editMaxDiscount();
              },
            ),
          ),

          const SizedBox(height: 12),

          // Minimum Fare
          Card(
            child: ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text('Minimum Ride Fare'),
              subtitle: Text(
                'Rs. ${minimumFare.toStringAsFixed(0)}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _editMinimumFare();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Example
          Card(
            color: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Promo Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text('Status: ${promoEnabled ? "ON" : "OFF"}'),
                  Text('Code: $promoCode'),
                  Text(
                    'Discount: ${discountPercent.toStringAsFixed(0)}%',
                  ),
                  Text(
                    'Max Discount: Rs. ${maxDiscount.toStringAsFixed(0)}',
                  ),
                  Text(
                    'Minimum Fare: Rs. ${minimumFare.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPromoCode() {
    final controller = TextEditingController(
      text: promoCode,
    );

    _showEditDialog(
      title: 'Change Promo Code',
      controller: controller,
      onSave: () {
        setState(() {
          promoCode = controller.text.toUpperCase();
        });
      },
    );
  }

  void _editDiscount() {
    final controller = TextEditingController(
      text: discountPercent.toStringAsFixed(0),
    );

    _showEditDialog(
      title: 'Change Discount %',
      controller: controller,
      keyboardType: TextInputType.number,
      onSave: () {
        final value = double.tryParse(controller.text);

        if (value != null) {
          setState(() {
            discountPercent = value;
          });
        }
      },
    );
  }

  void _editMaxDiscount() {
    final controller = TextEditingController(
      text: maxDiscount.toStringAsFixed(0),
    );

    _showEditDialog(
      title: 'Change Maximum Discount',
      controller: controller,
      keyboardType: TextInputType.number,
      onSave: () {
        final value = double.tryParse(controller.text);

        if (value != null) {
          setState(() {
            maxDiscount = value;
          });
        }
      },
    );
  }

  void _editMinimumFare() {
    final controller = TextEditingController(
      text: minimumFare.toStringAsFixed(0),
    );

    _showEditDialog(
      title: 'Change Minimum Fare',
      controller: controller,
      keyboardType: TextInputType.number,
      onSave: () {
        final value = double.tryParse(controller.text);

        if (value != null) {
          setState(() {
            minimumFare = value;
          });
        }
      },
    );
  }

  void _showEditDialog({
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}