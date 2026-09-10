/// Centralized API Endpoint routes for Durva Eco Ware.
/// All repositories must reference endpoints from this single source of truth.
abstract class ApiEndpoints {
  // Auth & Settings (Epic #01)
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String appSettings = '/api/app-settings';
  static const String companySettings = '/api/company-settings';
  static const String roles = '/api/roles';

  // Core Master Data (Epic #02)
  static const String categories = '/api/categories';
  static const String units = '/api/units';
  static const String products = '/api/products';
  static const String warehouses = '/api/warehouses';
  static const String documentSequences = '/api/document-sequences';

  // Partner Masters & Fleet (Epic #03)
  static const String suppliers = '/api/suppliers';
  static const String customers = '/api/customers';
  static const String transporters = '/api/transporters';
  static const String vehicles = '/api/vehicles';
  static const String paymentMethods = '/api/payment-methods';

  // Purchasing & GRN (Epic #04)
  static const String purchases = '/api/purchases';
  static const String purchaseDetails = '/api/purchase-details';
  static const String goodsReceipts = '/api/goods-receipts';
  static const String goodsReceiptDetails = '/api/goods-receipt-details';
  static const String vendorPayments = '/api/vendor-payments';

  // Inventory & Stock (Epic #05)
  static const String stockBalances = '/api/stock-balances';
  static const String stockTransactions = '/api/stock-transactions';
  static const String stockAdjustments = '/api/stock-adjustments';
  static const String auditLogs = '/api/audit-logs';

  // BOM & Recipe Engineering (Epic #06)
  static const String bomHeaders = '/api/b-o-m-headers';
  static const String bomDetails = '/api/b-o-m-details';

  // Production & Quality Control (Epic #07)
  static const String productionOrders = '/api/production-orders';
  static const String productionStages = '/api/production-stages';
  static const String productionStageEntries = '/api/production-stage-entries';
  static const String productionMaterialIssues = '/api/production-material-issues';
  static const String productionOutputs = '/api/production-outputs';
  static const String qualityChecks = '/api/quality-checks';

  // Waste & Scrap Management (Epic #08)
  static const String wasteReasons = '/api/waste-reasons';
  static const String wasteEntries = '/api/waste-entries';

  // Sales & Customer Payments (Epic #09)
  static const String sales = '/api/sales';
  static const String saleDetails = '/api/sale-details';
  static const String customerPayments = '/api/customer-payments';

  // Dispatch Logistics & Fleet (Epic #10)
  static const String deliveries = '/api/deliveries';
  static const String deliveryDetails = '/api/delivery-details';

  // Expense Management (Epic #11)
  static const String expenseCategories = '/api/expense-categories';
  static const String expenses = '/api/expenses';

  // Dashboard, Notifications & Reports (Epic #12)
  static const String notifications = '/api/notifications';
  static const String dashboardSummary = '/api/dashboard/summary';
  static const String stockSummaryReport = '/api/reports/stock-summary';
  static const String productionSummaryReport = '/api/reports/production-summary';
  static const String salesSummaryReport = '/api/reports/sales-summary';
  static const String wasteSummaryReport = '/api/reports/waste-summary';
}
