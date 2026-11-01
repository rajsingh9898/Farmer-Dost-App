/// Day 24 — Report Result Status Enum
enum ReportStatus {
  success,
  alreadyReported,
  notSignedIn,
  invalidInput,
  networkError,
  permissionDenied,
}

/// Day 24 — Structured result returned by ReportService.submitReport()
class ReportResult {
  final ReportStatus status;
  final String? reportId;
  final String? productCode;
  final String message;

  const ReportResult({
    required this.status,
    this.reportId,
    this.productCode,
    required this.message,
  });

  bool get isSuccess => status == ReportStatus.success;
  bool get isAlreadyReported => status == ReportStatus.alreadyReported;
  bool get isNotSignedIn => status == ReportStatus.notSignedIn;
  bool get isInvalidInput => status == ReportStatus.invalidInput;
  bool get isNetworkError => status == ReportStatus.networkError;
  bool get isPermissionDenied => status == ReportStatus.permissionDenied;

  @override
  String toString() => 'ReportResult(status: ${status.name}, id: $reportId, message: $message)';
}
