import 'package:flutter/material.dart';

void main() {
  runApp(const SupermarketApp());
}

class SupermarketApp extends StatelessWidget {
  const SupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スーパーお得計算',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 起動時は単価比較

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('スーパーお得計算', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              DiscountScreen(),
              CompareScreen(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.green.shade800,
          unselectedItemColor: Colors.grey.shade600,
          selectedIconTheme: const IconThemeData(size: 28),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: '割引計算'),
            BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: '単価比較'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. 割引計算画面（5, 10, 20, 30, 40, 50%の2段表示）
// ==========================================
class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});
  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}
class _DiscountScreenState extends State<DiscountScreen> {
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isPercent = true;
  int _finalPrice = 0;
  int _savedAmount = 0;

  void _calculate() {
    final price = int.tryParse(_priceController.text) ?? 0;
    final discount = int.tryParse(_discountController.text) ?? 0;
    if (price <= 0) {
      setState(() { _finalPrice = 0; _savedAmount = 0; });
      return;
    }
    setState(() {
      if (_isPercent) {
        _savedAmount = (price * (discount / 100)).round();
      } else {
        _savedAmount = discount;
      }
      _finalPrice = price - _savedAmount;
      if (_finalPrice < 0) _finalPrice = 0;
    });
  }

  void _clearAll() {
    _priceController.clear();
    _discountController.clear();
    _calculate();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: _clearAll,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.delete_outline, color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('割引計算', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '元の値段 (円)', border: OutlineInputBorder()),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '割引', border: OutlineInputBorder()),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('%引')),
                      ButtonSegment(value: false, label: Text('円引')),
                    ],
                    selected: {_isPercent},
                    onSelectionChanged: (newSel) => setState(() { _isPercent = newSel.first; _calculate(); }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ★ 5, 10, 20, 30, 40, 50% の2段チップ表示
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [5, 10, 20].map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ActionChip(
                        label: Center(child: Text('$p%引', style: const TextStyle(fontSize: 12))),
                        onPressed: () => setState(() { _isPercent = true; _discountController.text = p.toString(); _calculate(); }),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [30, 40, 50].map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ActionChip(
                        label: Center(child: Text('$p%引', style: const TextStyle(fontSize: 12))),
                        onPressed: () => setState(() { _isPercent = true; _discountController.text = p.toString(); _calculate(); }),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text('おトク額: -$_savedAmount円', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('$_finalPrice 円', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. 単価比較画面（標準で商品A・B・Cの3つ計算可能）
// ==========================================
enum CompareMode { weight, piece, liquid, roll, tissue, pack }

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  CompareMode _currentMode = CompareMode.weight;
  
  // 商品A
  final _nameA = TextEditingController();
  final _priceA = TextEditingController();
  final _discountA = TextEditingController();
  final _amountA = TextEditingController();
  final _subCountA = TextEditingController();
  final _subAmountA = TextEditingController();
  
  // 商品B
  final _nameB = TextEditingController();
  final _priceB = TextEditingController();
  final _discountB = TextEditingController();
  final _amountB = TextEditingController();
  final _subCountB = TextEditingController();
  final _subAmountB = TextEditingController();
  
  // 商品C (標準搭載)
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _discountC = TextEditingController();
  final _amountC = TextEditingController();
  final _subCountC = TextEditingController();
  final _subAmountC = TextEditingController();

  String _resultText = "数値を入力してください";
  String _cheapestTarget = "";

  double _calculateUnitPrice(
    TextEditingController priceCtrl, 
    TextEditingController discountCtrl,
    TextEditingController amountCtrl, 
    TextEditingController subCountCtrl, 
    TextEditingController subAmountCtrl
  ) {
    final rawPrice = double.tryParse(priceCtrl.text) ?? 0;
    if (rawPrice <= 0) return 0;
    
    final discountPercent = double.tryParse(discountCtrl.text) ?? 0;
    final effectivePrice = rawPrice * (1.0 - (discountPercent / 100.0));
    
    if (_currentMode == CompareMode.weight || _currentMode == CompareMode.piece || _currentMode == CompareMode.liquid) {
      final a = double.tryParse(amountCtrl.text) ?? 0;
      if (a <= 0) return 0;
      double multiplier = (_currentMode == CompareMode.piece) ? 1 : 100;
      return (effectivePrice / a) * multiplier;
    } else if (_currentMode == CompareMode.roll || _currentMode == CompareMode.tissue || _currentMode == CompareMode.pack) {
      final c = double.tryParse(subCountCtrl.text) ?? 0;
      final l = double.tryParse(subAmountCtrl.text) ?? 0;
      if (c <= 0 || l <= 0) return 0;

      if (_currentMode == CompareMode.roll) {
        return effectivePrice / (c * l); // 1mあたり
      } else if (_currentMode == CompareMode.tissue) {
        return (effectivePrice / (c * l)) * 100; // 100組あたり
      } else if (_currentMode == CompareMode.pack) {
        return (effectivePrice / (c * l)) * 100; // 100gあたり
      }
    }
    return 0;
  }

  void _calculate() {
    final unitPriceA = _calculateUnitPrice(_priceA, _discountA, _amountA, _subCountA, _subAmountA);
    final unitPriceB = _calculateUnitPrice(_priceB, _discountB, _amountB, _subCountB, _subAmountB);
    final unitPriceC = _calculateUnitPrice(_priceC, _discountC, _amountC, _subCountC, _subAmountC);

    final Map<String, double> validPrices = {};
    if (unitPriceA > 0) validPrices['A'] = unitPriceA;
    if (unitPriceB > 0) validPrices['B'] = unitPriceB;
    if (unitPriceC > 0) validPrices['C'] = unitPriceC;

    String unitText = _getUnitLabel();

    if (validPrices.isEmpty) {
      setState(() {
        _cheapestTarget = "";
        _resultText = "数値を入力してください";
      });
      return;
    }

    if (validPrices.length == 1) {
      final singleEntry = validPrices.entries.first;
      setState(() {
        _cheapestTarget = singleEntry.key;
        _resultText = "商品 ${singleEntry.key} : ${singleEntry.value.toStringAsFixed(1)}円 ($unitText)";
      });
      return;
    }

    var cheapestEntry = validPrices.entries.reduce((curr, next) => curr.value < next.value ? curr : next);

    setState(() {
      _cheapestTarget = cheapestEntry.key;
      _resultText = "商品 ${cheapestEntry.key} が一番おトク！\n($unitText)";
    });
  }

  String _getUnitLabel() {
    switch (_currentMode) {
      case CompareMode.weight: return "100gあたり";
      case CompareMode.liquid: return "100mlあたり";
      case CompareMode.piece: return "1個あたり";
      case CompareMode.roll: return "1mあたり";
      case CompareMode.tissue: return "100組あたり";
      case CompareMode.pack: return "100gあたり";
    }
  }

  void _clearInputs() {
    _nameA.clear(); _priceA.clear(); _discountA.clear(); _amountA.clear(); _subCountA.clear(); _subAmountA.clear();
    _nameB.clear(); _priceB.clear(); _discountB.clear(); _amountB.clear(); _subCountB.clear(); _subAmountB.clear();
    _nameC.clear(); _priceC.clear(); _discountC.clear(); _amountC.clear(); _subCountC.clear(); _subAmountC.clear();
    _calculate();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildModeButton(CompareMode mode, String label) {
    final bool isSelected = (_currentMode == mode);
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() {
            _currentMode = mode;
            _clearInputs();
          });
        },
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildItemCard(
    String targetKey, String defaultTitle, 
    TextEditingController nameCtrl, TextEditingController priceCtrl, TextEditingController discountCtrl,
    TextEditingController amountCtrl, TextEditingController subCountCtrl, TextEditingController subAmountCtrl
  ) {
    final bool isCheaper = (_cheapestTarget == targetKey);
    final double currentUnitPrice = _calculateUnitPrice(priceCtrl, discountCtrl, amountCtrl, subCountCtrl, subAmountCtrl);
    
    String amountLabel = '個数';
    String subCountLabel = '本数';
    String subAmountLabel = '1本(m)';

    if (_currentMode == CompareMode.weight) amountLabel = '量(g)';
    if (_currentMode == CompareMode.liquid) amountLabel = '容量(ml)';
    
    if (_currentMode == CompareMode.tissue) {
      subCountLabel = '箱数';
      subAmountLabel = '1箱(組)';
    } else if (_currentMode == CompareMode.pack) {
      subCountLabel = 'パック数';
      subAmountLabel = '1個(g)';
    }

    final bool isTwoFieldMode = (_currentMode == CompareMode.roll || _currentMode == CompareMode.tissue || _currentMode == CompareMode.pack);

    return Card(
      color: isCheaper ? Colors.orange.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isCheaper ? Colors.orange : Colors.grey.shade300, width: isCheaper ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCheaper ? Colors.orange.shade800 : Colors.black87),
              decoration: InputDecoration(
                hintText: 'メモ ($defaultTitle)',
                hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 4),
            const SizedBox(height: 4),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(labelText: '定価(円)', isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: '割引(%引)', 
                hintText: '20', 
                isDense: true, 
                contentPadding: EdgeInsets.all(8), 
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 6),
            if (!isTwoFieldMode)
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(labelText: amountLabel, isDense: true, contentPadding: const EdgeInsets.all(8), border: const OutlineInputBorder()),
                onChanged: (_) => _calculate(),
              )
            else ...[
              TextField(
                controller: subCountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(labelText: subCountLabel, isDense: true, contentPadding: const EdgeInsets.all(8), border: const OutlineInputBorder()),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: subAmountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(labelText: subAmountLabel, isDense: true, contentPadding: const EdgeInsets.all(8), border: const OutlineInputBorder()),
                onChanged: (_) => _calculate(),
              ),
            ],
            const SizedBox(height: 8),
            if (currentUnitPrice > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${currentUnitPrice.toStringAsFixed(1)}円',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: _clearInputs,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.delete_outline, color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2段（3×2）のモード切替ボタン
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildModeButton(CompareMode.weight, '🥩 食(g)')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildModeButton(CompareMode.piece, '🥟 食(個)')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildModeButton(CompareMode.liquid, '🧴 液体')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildModeButton(CompareMode.roll, '🧻 トイペ')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildModeButton(CompareMode.tissue, '🧻 ティッシュ')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildModeButton(CompareMode.pack, '📦 パックg')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 商品A・B・C のカード横並び（標準で3つ利用可能）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildItemCard('A', '商品A', _nameA, _priceA, _discountA, _amountA, _subCountA, _subAmountA)),
                const SizedBox(width: 4),
                Expanded(child: _buildItemCard('B', '商品B', _nameB, _priceB, _discountB, _amountB, _subCountB, _subAmountB)),
                const SizedBox(width: 4),
                Expanded(child: _buildItemCard('C', '商品C', _nameC, _priceC, _discountC, _amountC, _subCountC, _subAmountC)),
              ],
            ),
            const SizedBox(height: 12),
            // 判定結果エリア
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text(
                _resultText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}