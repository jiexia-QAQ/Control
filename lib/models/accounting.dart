/// V1.6 记账数据模型：支出 / 收入 / 借贷账单
library;

/// 支出分类（含 emoji 与颜色语义由 UI 层映射）
const expenseCategories = ['餐饮', '购物', '出行', '居住', '娱乐', '医疗', '教育', '其他'];
const incomeCategories = ['工资', '兼职', '理财', '红包', '其他'];

/// 账户选项
const accountOptions = ['微信', '支付宝', '银行卡', '现金', '花呗', '白条', '其他'];

/// 借贷渠道
const creditProviders = ['花呗', '京东白条', '信用卡', '其他'];

/// 一笔支出
class Expense {
  final int? id;
  final String date; // yyyy-MM-dd
  final double amount;
  final String category;
  final String note;
  final String account;
  final String source; // 'manual' 手动 | 未来通知解析为来源 App 名

  Expense({
    this.id,
    required this.date,
    required this.amount,
    this.category = '其他',
    this.note = '',
    this.account = '其他',
    this.source = 'manual',
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'date': date,
        'amount': amount,
        'category': category,
        'note': note,
        'account': account,
        'source': source,
      };

  factory Expense.fromRow(Map<String, Object?> r) => Expense(
        id: r['id'] as int?,
        date: r['date'] as String,
        amount: (r['amount'] as num).toDouble(),
        category: (r['category'] as String?) ?? '其他',
        note: (r['note'] as String?) ?? '',
        account: (r['account'] as String?) ?? '其他',
        source: (r['source'] as String?) ?? 'manual',
      );
}

/// 一笔收入
class Income {
  final int? id;
  final String date;
  final double amount;
  final String category;
  final String note;
  final String account;
  final String source;

  Income({
    this.id,
    required this.date,
    required this.amount,
    this.category = '其他',
    this.note = '',
    this.account = '其他',
    this.source = 'manual',
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'date': date,
        'amount': amount,
        'category': category,
        'note': note,
        'account': account,
        'source': source,
      };

  factory Income.fromRow(Map<String, Object?> r) => Income(
        id: r['id'] as int?,
        date: r['date'] as String,
        amount: (r['amount'] as num).toDouble(),
        category: (r['category'] as String?) ?? '其他',
        note: (r['note'] as String?) ?? '',
        account: (r['account'] as String?) ?? '其他',
        source: (r['source'] as String?) ?? 'manual',
      );
}

/// 借贷待还账单（花呗/白条等）
class CreditBill {
  final int? id;
  final String provider; // 花呗/京东白条/信用卡/其他
  final double amount; // 账单总金额
  final double remaining; // 剩余应还
  final String dueDate; // yyyy-MM-dd 到期日
  final String note;
  final bool paid; // 是否已还清
  final String source; // manual / 通知解析

  CreditBill({
    this.id,
    required this.provider,
    required this.amount,
    required this.remaining,
    required this.dueDate,
    this.note = '',
    this.paid = false,
    this.source = 'manual',
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'provider': provider,
        'amount': amount,
        'remaining': remaining,
        'due_date': dueDate,
        'note': note,
        'paid': paid ? 1 : 0,
        'source': source,
      };

  factory CreditBill.fromRow(Map<String, Object?> r) => CreditBill(
        id: r['id'] as int?,
        provider: (r['provider'] as String?) ?? '其他',
        amount: (r['amount'] as num).toDouble(),
        remaining: (r['remaining'] as num).toDouble(),
        dueDate: r['due_date'] as String,
        note: (r['note'] as String?) ?? '',
        paid: ((r['paid'] as int?) ?? 0) == 1,
        source: (r['source'] as String?) ?? 'manual',
      );
}

/// 本月收支汇总
class MonthSummary {
  final double income;
  final double expense;
  final double creditRemaining; // 借贷剩余应还总额
  const MonthSummary({this.income = 0, this.expense = 0, this.creditRemaining = 0});

  /// 当前可用余额 = 初始资产 + 历史总收入 - 历史总支出 - 借贷待还
  double balance(double initialAssets) =>
      initialAssets + income - expense - creditRemaining;
}

// ============ V1.6 愿望清单 ============

const wishCategories = ['3C数码', '服饰', '家居', '美妆', '美食', '旅行', '学习', '其他'];
const wishEmoji = {
  '3C数码': '💻', '服饰': '👗', '家居': '🏠',
  '美妆': '💄', '美食': '🍔', '旅行': '✈️',
  '学习': '📚', '其他': '🎁',
};
const _prioLabels = ['低', '中', '高'];

/// 愿望清单条目
class WishItem {
  final int? id;
  final String name;
  final double price;
  final String category;
  final int priority; // 0低 1中 2高
  final String note;
  final bool achieved;

  WishItem({
    this.id,
    required this.name,
    this.price = 0,
    this.category = '其他',
    this.priority = 1,
    this.note = '',
    this.achieved = false,
  });

  String get priorityLabel => _prioLabels[priority.clamp(0, 2)];

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'category': category,
        'priority': priority,
        'note': note,
        'achieved': achieved ? 1 : 0,
      };

  factory WishItem.fromRow(Map<String, Object?> r) => WishItem(
        id: r['id'] as int?,
        name: r['name'] as String,
        price: (r['price'] as num?)?.toDouble() ?? 0,
        category: (r['category'] as String?) ?? '其他',
        priority: (r['priority'] as int?) ?? 1,
        note: (r['note'] as String?) ?? '',
        achieved: ((r['achieved'] as int?) ?? 0) == 1,
      );
}

// ============ V1.7 阶段目标 ============

/// 阶段目标：'weight' 体重联动（最新体重）| 'balance' 余额联动
class Goal {
  final int? id;
  final String name;
  final String type; // weight / balance
  final double target;
  final double start;

  Goal({
    this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.start,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'target': target,
        'start': start,
      };

  factory Goal.fromRow(Map<String, Object?> r) => Goal(
        id: r['id'] as int?,
        name: r['name'] as String,
        type: (r['type'] as String?) ?? 'weight',
        target: (r['target'] as num).toDouble(),
        start: (r['start'] as num).toDouble(),
      );
}

