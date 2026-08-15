class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String role;

  AppUser({required this.id, required this.fullName, required this.email, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        fullName: j['full_name'],
        email: j['email'],
        role: j['role'],
      );
}

class OwnershipRecord {
  final String ownerName;
  final String acquisitionType;
  final String documentNumber;
  final String? registrationDate;
  final String? registrarOffice;
  final double? saleAmount;

  OwnershipRecord({
    required this.ownerName,
    required this.acquisitionType,
    required this.documentNumber,
    this.registrationDate,
    this.registrarOffice,
    this.saleAmount,
  });

  factory OwnershipRecord.fromJson(Map<String, dynamic> j) => OwnershipRecord(
        ownerName: j['owner_name'] ?? '',
        acquisitionType: j['acquisition_type'] ?? '',
        documentNumber: j['document_number'] ?? '',
        registrationDate: j['registration_date'],
        registrarOffice: j['registrar_office'],
        saleAmount: (j['sale_amount'] as num?)?.toDouble(),
      );
}

class Encumbrance {
  final String type;
  final String holderName;
  final double? amount;
  final String status;

  Encumbrance({required this.type, required this.holderName, this.amount, required this.status});

  factory Encumbrance.fromJson(Map<String, dynamic> j) => Encumbrance(
        type: j['encumbrance_type'] ?? '',
        holderName: j['holder_name'] ?? '',
        amount: (j['amount'] as num?)?.toDouble(),
        status: j['status'] ?? '',
      );
}

class CourtCase {
  final String caseNumber;
  final String courtName;
  final String caseType;
  final String status;
  final String? filedDate;
  final String? nextHearingDate;
  final String summary;
  final double severityWeight;

  CourtCase({
    required this.caseNumber,
    required this.courtName,
    required this.caseType,
    required this.status,
    this.filedDate,
    this.nextHearingDate,
    required this.summary,
    required this.severityWeight,
  });

  factory CourtCase.fromJson(Map<String, dynamic> j) => CourtCase(
        caseNumber: j['case_number'] ?? '',
        courtName: j['court_name'] ?? '',
        caseType: j['case_type'] ?? '',
        status: j['status'] ?? '',
        filedDate: j['filed_date'],
        nextHearingDate: j['next_hearing_date'],
        summary: j['summary'] ?? '',
        severityWeight: (j['severity_weight'] as num?)?.toDouble() ?? 0.5,
      );
}

class PropertyModel {
  final int id;
  final String surveyNumber;
  final String? district;
  final String? taluk;
  final String? village;
  final double? areaSqft;
  final String? propertyType;
  final String? currentOwner;
  final String? pattaNumber;
  final String? chittaNumber;
  final double? marketValueEst;
  final List<OwnershipRecord> owners;
  final List<Encumbrance> encumbrances;
  final List<CourtCase> courtCases;

  PropertyModel({
    required this.id,
    required this.surveyNumber,
    this.district,
    this.taluk,
    this.village,
    this.areaSqft,
    this.propertyType,
    this.currentOwner,
    this.pattaNumber,
    this.chittaNumber,
    this.marketValueEst,
    this.owners = const [],
    this.encumbrances = const [],
    this.courtCases = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> j) => PropertyModel(
        id: j['id'],
        surveyNumber: j['survey_number'],
        district: j['district'],
        taluk: j['taluk'],
        village: j['village'],
        areaSqft: (j['area_sqft'] as num?)?.toDouble(),
        propertyType: j['property_type'],
        currentOwner: j['current_owner'],
        pattaNumber: j['patta_number'],
        chittaNumber: j['chitta_number'],
        marketValueEst: (j['market_value_est'] as num?)?.toDouble(),
        owners: (j['owners'] as List? ?? []).map((e) => OwnershipRecord.fromJson(e)).toList(),
        encumbrances: (j['encumbrances'] as List? ?? []).map((e) => Encumbrance.fromJson(e)).toList(),
        courtCases: (j['court_cases'] as List? ?? []).map((e) => CourtCase.fromJson(e)).toList(),
      );
}

class RiskAssessment {
  final String surveyNumber;
  final double riskScore;
  final String riskLevel;
  final List<String> factors;
  final int activeCases;
  final int activeEncumbrances;
  final String recommendation;

  RiskAssessment({
    required this.surveyNumber,
    required this.riskScore,
    required this.riskLevel,
    required this.factors,
    required this.activeCases,
    required this.activeEncumbrances,
    required this.recommendation,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> j) => RiskAssessment(
        surveyNumber: j['survey_number'],
        riskScore: (j['risk_score'] as num).toDouble(),
        riskLevel: j['risk_level'],
        factors: List<String>.from(j['factors'] ?? []),
        activeCases: j['active_cases'] ?? 0,
        activeEncumbrances: j['active_encumbrances'] ?? 0,
        recommendation: j['recommendation'] ?? '',
      );
}

class AlertModel {
  final int id;
  final int propertyId;
  final String message;
  final String severity;
  final String createdAt;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.propertyId,
    required this.message,
    required this.severity,
    required this.createdAt,
    required this.isRead,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: j['id'],
        propertyId: j['property_id'],
        message: j['message'],
        severity: j['severity'],
        createdAt: j['created_at'],
        isRead: j['is_read'] ?? false,
      );
}
