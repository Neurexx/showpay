// screens/transactions_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../models/payment.dart';
import '../utils/constants.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  Timer? _debounceTimer;
  String _searchQuery = '';
  
  // Filters
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedPaymentMethod;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _payments.clear();
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final response = await ApiService.getPayments(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus,
        paymentMethod: _selectedPaymentMethod,
        dateFrom: _selectedDateRange?.start,
        dateTo: _selectedDateRange?.end,
      );

      final newPayments = response['payments'] as List<Payment>;
      _totalCount = response['total'] as int;
      _totalPages = (_totalCount / 20).ceil();
      _hasMore = _currentPage < _totalPages;

      setState(() {
        if (isRefresh) {
          _payments = newPayments;
        } else {
          _payments.addAll(newPayments);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _currentPage++;
    });
    await _loadPayments();
  }

  void _applyFilters() {
    _loadPayments(isRefresh: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _selectedDateRange = null;
      _searchController.clear();
    });
    _loadPayments(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPayments(isRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStatsHeader(),
          Expanded(
            child: _isLoading && _payments.isEmpty
                ? const Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 50,
                    ),
                  )
                : _error.isNotEmpty && _payments.isEmpty
                    ? _buildErrorWidget()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          
          const SizedBox(height: 12),
          _buildActiveFilters(),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final activeFilters = <Widget>[];

    if (_selectedStatus != null) {
      activeFilters.add(_buildFilterChip(
        label: 'Status: ${_selectedStatus!.name}',
        onDeleted: () {
          setState(() {
            _selectedStatus = null;
          });
          _applyFilters();
        },
      ));
    }

    if (_selectedPaymentMethod != null) {
      activeFilters.add(_buildFilterChip(
        label: 'Method: ${_selectedPaymentMethod!.name.replaceAll('_', ' ')}',
        onDeleted: () {
          setState(() {
            _selectedPaymentMethod = null;
          });
          _applyFilters();
        },
      ));
    }

    if (_selectedDateRange != null) {
      activeFilters.add(_buildFilterChip(
        label: 'Date: ${_formatDateRange(_selectedDateRange!)}',
        onDeleted: () {
          setState(() {
            _selectedDateRange = null;
          });
          _applyFilters();
        },
      ));
    }

    if (activeFilters.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Active Filters:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: activeFilters,
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: const BorderSide(color: AppColors.primary),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Total Transactions',
              value: _totalCount.toString(),
              icon: Icons.receipt,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              label: 'Total Amount',
              value: '\$${_calculateTotalAmount()}',
              icon: Icons.attach_money,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            style: const TextStyle(color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadPayments(isRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: () => _loadPayments(isRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _payments.length) {
            if (_hasMore) {
              _loadMore();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SpinKitCircle(
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              );
            }
            return const SizedBox();
          }

          final payment = _payments[index];
          return _buildTransactionCard(payment);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(payment.status).withOpacity(0.1),
                    child: Icon(
                      _getPaymentMethodIcon(payment.paymentMethod),
                      color: _getStatusColor(payment.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.receiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.receiverEmail ?? 'No email',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(payment.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(payment.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment.paymentMethod.name.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(payment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (payment.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  payment.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PaymentStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Statuses')),
                  ...PaymentStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Methods')),
                  ...PaymentMethod.values.map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.name.replaceAll('_', ' ').toUpperCase()),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDateRange == null
                            ? 'Select date range'
                            : _formatDateRange(_selectedDateRange!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showTransactionDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Transaction ID', payment.transactionId),
              _buildDetailRow('Amount', '\$${payment.amount.toStringAsFixed(2)} ${payment.currency}'),
              _buildDetailRow('Status', payment.status.name.toUpperCase()),
              _buildDetailRow('Payment Method', payment.paymentMethod.name.replaceAll('_', ' ').toUpperCase()),
              _buildDetailRow('Receiver', payment.receiverName),
              if (payment.receiverEmail != null)
                _buildDetailRow('Receiver Email', payment.receiverEmail!),
              if (payment.description != null)
                _buildDetailRow('Description', payment.description!),
              _buildDetailRow('Created At', _formatDateTime(payment.createdAt)),
              _buildDetailRow('Updated At', _formatDateTime(payment.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _calculateTotalAmount() {
    final total = _payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    return total.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateRange(DateTimeRange range) {
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return AppColors.success;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.pending:
        return AppColors.pending;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.credit_card:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.paypal;
      case PaymentMethod.bank_transfer:
        return Icons.account_balance;
      case PaymentMethod.crypto:
        return Icons.currency_bitcoin;
    }
  }
}