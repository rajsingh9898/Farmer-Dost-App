import '../models/product_model.dart';

/// 20 Realistic Sample Agricultural Products Catalog for Farmer Dost App.
/// Includes widely used Indian fertilizers and pesticides from registered manufacturers
/// (IFFCO, KRIBHCO, Bayer, Syngenta, UPL, Tata Rallis, Coromandel, etc.)
final List<ProductModel> sampleProductsCatalog = [
  // 1. Standard Demo Genuine Product
  ProductModel(
    code: 'GENUINE-123',
    name: 'KRIBHCO Neem Coated Urea 50kg',
    manufacturer: 'Krishak Bharati Cooperative Ltd',
    batch: 'BATCH-2026-99A',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 3, 15),
    expiryDate: DateTime(2028, 3, 14),
    createdAt: DateTime(2026, 3, 16),
    dosage: '45-50 kg per acre during first irrigation',
  ),

  // 2. IFFCO Urea
  ProductModel(
    code: 'IFFCO-UREA-45',
    name: 'IFFCO Neem Coated Urea 45kg',
    manufacturer: 'Indian Farmers Fertiliser Cooperative Ltd (IFFCO)',
    batch: 'IFFCO-UR-2026-08',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 2, 10),
    expiryDate: DateTime(2028, 2, 9),
    createdAt: DateTime(2026, 2, 12),
    dosage: '45 kg per acre for wheat and paddy',
  ),

  // 3. IFFCO DAP
  ProductModel(
    code: 'IFFCO-DAP-50KG',
    name: 'IFFCO Di-Ammonium Phosphate (DAP 18:46:0)',
    manufacturer: 'Indian Farmers Fertiliser Cooperative Ltd (IFFCO)',
    batch: 'BATCH-IFFCO-DAP-81',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 1, 20),
    expiryDate: DateTime(2028, 1, 19),
    createdAt: DateTime(2026, 1, 22),
    dosage: '50 kg per acre applied during basal sowing',
  ),

  // 4. NFL Kisan Urea
  ProductModel(
    code: 'NFL-KISSAN-UREA',
    name: 'NFL Kisan Neem Coated Urea 45kg',
    manufacturer: 'National Fertilizers Limited',
    batch: 'BATCH-NFL-2026-04',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 4, 1),
    expiryDate: DateTime(2028, 3, 31),
    createdAt: DateTime(2026, 4, 2),
    dosage: '45 kg per acre in split doses',
  ),

  // 5. Tata Paras DAP
  ProductModel(
    code: 'TATA-PARAS-DAP',
    name: 'Tata Paras DAP (18-46-0) 50kg',
    manufacturer: 'Paradeep Phosphates Ltd (Tata Chemicals)',
    batch: 'BATCH-TP-5021',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 2, 18),
    expiryDate: DateTime(2028, 2, 17),
    createdAt: DateTime(2026, 2, 20),
    dosage: '50 kg per acre as basal dressing',
  ),

  // 6. IPL Muriate of Potash
  ProductModel(
    code: 'IPL-MOP-POTASH',
    name: 'IPL Muriate of Potash (MOP 60% K2O)',
    manufacturer: 'Indian Potash Limited',
    batch: 'BATCH-IPL-MOP-11',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 3, 5),
    expiryDate: DateTime(2029, 3, 4),
    createdAt: DateTime(2026, 3, 7),
    dosage: '25-30 kg per acre for sugarcane and potato',
  ),

  // 7. IFFCO Water Soluble NPK 19-19-19
  ProductModel(
    code: 'IFFCO-NPK-191919',
    name: 'IFFCO WSF 19-19-19 1kg Foliar Spray',
    manufacturer: 'Indian Farmers Fertiliser Cooperative Ltd (IFFCO)',
    batch: 'BATCH-WSF-1919-44',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 5, 10),
    expiryDate: DateTime(2028, 5, 9),
    createdAt: DateTime(2026, 5, 12),
    dosage: '1 kg dissolved in 100 liters of water per acre',
  ),

  // 8. Coromandel Gromor 28-28-0
  ProductModel(
    code: 'COROMANDEL-GROMOR',
    name: 'Coromandel Gromor 28-28-0 Complex Fertilizer',
    manufacturer: 'Coromandel International Ltd',
    batch: 'BATCH-CR-2828-09',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 3, 25),
    expiryDate: DateTime(2028, 3, 24),
    createdAt: DateTime(2026, 3, 27),
    dosage: '50 kg per acre for cotton and paddy',
  ),

  // 9. Zuari Jai Kisaan Sampurna
  ProductModel(
    code: 'ZUARI-JAIKISAAN',
    name: 'Jai Kisaan Sampurna NPK 19-19-19 50kg',
    manufacturer: 'Zuari Agro Chemicals Ltd',
    batch: 'BATCH-ZK-7712',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 1, 15),
    expiryDate: DateTime(2028, 1, 14),
    createdAt: DateTime(2026, 1, 18),
    dosage: '50 kg per acre for vegetables and horticulture',
  ),

  // 10. GSFC Sardar DAP
  ProductModel(
    code: 'GSFC-SARDAR-DAP',
    name: 'GSFC Sardar DAP 50kg',
    manufacturer: 'Gujarat State Fertilizers & Chemicals Ltd',
    batch: 'BATCH-GS-8831',
    type: 'fertilizer',
    status: 'active',
    manufactureDate: DateTime(2026, 4, 12),
    expiryDate: DateTime(2028, 4, 11),
    createdAt: DateTime(2026, 4, 14),
    dosage: '50 kg per acre at sowing',
  ),

  // 11. FMC / Bayer Coragen Insecticide
  ProductModel(
    code: 'BAYER-CORAGEN',
    name: 'Coragen Insecticide (Chlorantraniliprole 18.5% SC)',
    manufacturer: 'FMC India / Bayer CropScience',
    batch: 'BATCH-CRG-2026-101',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 4, 20),
    expiryDate: DateTime(2028, 4, 19),
    createdAt: DateTime(2026, 4, 22),
    dosage: '60 ml in 200 liters of water per acre for stem borer',
  ),

  // 12. Syngenta Amistar Top
  ProductModel(
    code: 'SYNGENTA-AMISTAR',
    name: 'Amistar Top Broad Spectrum Fungicide',
    manufacturer: 'Syngenta India Ltd',
    batch: 'BATCH-SYN-AMT-31',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 3, 10),
    expiryDate: DateTime(2028, 3, 9),
    createdAt: DateTime(2026, 3, 12),
    dosage: '200 ml per acre for sheath blight and blast',
  ),

  // 13. UPL Saaf Fungicide
  ProductModel(
    code: 'UPL-SAAF-FUNGICIDE',
    name: 'Saaf Fungicide (Carbendazim 12% + Mancozeb 63% WP)',
    manufacturer: 'UPL Limited',
    batch: 'BATCH-UPL-SF-55',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 2, 28),
    expiryDate: DateTime(2028, 2, 27),
    createdAt: DateTime(2026, 3, 2),
    dosage: '300-500 gm per acre in 200 liters of water',
  ),

  // 14. Dhanuka Dhanucop
  ProductModel(
    code: 'DHANUKA-COP-50',
    name: 'Dhanucop Copper Oxychloride 50% WP',
    manufacturer: 'Dhanuka Agritech Ltd',
    batch: 'BATCH-DH-COP-22',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 1, 10),
    expiryDate: DateTime(2028, 1, 9),
    createdAt: DateTime(2026, 1, 12),
    dosage: '500-600 gm per acre against blight and rust',
  ),

  // 15. Bayer Confidor Super
  ProductModel(
    code: 'BAYER-CONFIDOR',
    name: 'Confidor Super (Imidacloprid 30.5% SC)',
    manufacturer: 'Bayer CropScience India Ltd',
    batch: 'BATCH-BY-CFD-99',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 4, 15),
    expiryDate: DateTime(2028, 4, 14),
    createdAt: DateTime(2026, 4, 17),
    dosage: '50-70 ml per acre for sucking pests',
  ),

  // 16. Rallis Tata Asata
  ProductModel(
    code: 'TATA-RALLIS-ASATA',
    name: 'Rallis Tata Asata (Acephate 75% SP)',
    manufacturer: 'Rallis India Limited',
    batch: 'BATCH-RL-AST-17',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 3, 1),
    expiryDate: DateTime(2028, 2, 29),
    createdAt: DateTime(2026, 3, 3),
    dosage: '300-400 gm per acre against aphids and jassids',
  ),

  // 17. Indofil Avatar
  ProductModel(
    code: 'INDOFIL-AVATAR',
    name: 'Indofil Avatar (Hexaconazole 5% SC)',
    manufacturer: 'Indofil Industries Ltd',
    batch: 'BATCH-ID-AVT-63',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 2, 14),
    expiryDate: DateTime(2028, 2, 13),
    createdAt: DateTime(2026, 2, 16),
    dosage: '200-300 ml per acre for powdery mildew',
  ),

  // 18. PI Industries Nominee Gold
  ProductModel(
    code: 'PI-NOMINEE-GOLD',
    name: 'Nominee Gold Herbicide (Bispyribac Sodium 10% SC)',
    manufacturer: 'PI Industries Ltd',
    batch: 'BATCH-PI-NG-408',
    type: 'pesticide',
    status: 'active',
    manufactureDate: DateTime(2026, 5, 2),
    expiryDate: DateTime(2028, 5, 1),
    createdAt: DateTime(2026, 5, 4),
    dosage: '80-100 ml per acre in paddy nursery and field',
  ),

  // 19. Expired Product Example (To verify expired state handling)
  ProductModel(
    code: 'EXPIRED-CHLORPYRIFOS',
    name: 'Dursban Chlorpyrifos 20% EC (Expired Stock)',
    manufacturer: 'Agro Chem Solutions India Ltd',
    batch: 'BATCH-AG-EXP-01',
    type: 'pesticide',
    status: 'expired',
    manufactureDate: DateTime(2022, 1, 10),
    expiryDate: DateTime(2024, 1, 9),
    createdAt: DateTime(2022, 1, 12),
    dosage: 'Do not use - product has expired and degraded',
  ),

  // 20. Recalled Batch Example (To verify recalled warning)
  ProductModel(
    code: 'RECALLED-ROUNDUP',
    name: 'Glyphosate 41% SL (Recalled Quality Batch)',
    manufacturer: 'Agro Allied Labs Ltd',
    batch: 'BATCH-RCL-2025-99',
    type: 'pesticide',
    status: 'recalled',
    manufactureDate: DateTime(2025, 5, 1),
    expiryDate: DateTime(2027, 4, 30),
    createdAt: DateTime(2025, 5, 3),
    dosage: 'RECALLED BATCH - Return immediately to authorized dealer',
  ),
];
