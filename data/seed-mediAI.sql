-- ============================================================
-- MediAI – Données de test réalistes
-- Chapitre 2 : Distributed Databases – ENSTA 3A
-- ============================================================

-- ── Patients (répartis sur 4 sites géographiques) ───────────

INSERT INTO Patients (name, age, city, country, siteOrigin) VALUES
-- Site Paris (France)
('Alice Dupont',       34, 'Paris',      'France',  'Paris'),
('Bernard Martin',     67, 'Lyon',       'France',  'Paris'),
('Camille Rousseau',   28, 'Bordeaux',   'France',  'Paris'),
('David Leclerc',      52, 'Marseille',  'France',  'Paris'),
('Emma Fontaine',      41, 'Toulouse',   'France',  'Paris'),

-- Site Tunis (Tunisia)
('Mohamed Benali',     45, 'Tunis',      'Tunisia', 'Tunis'),
('Fatima Khelifi',     38, 'Sfax',       'Tunisia', 'Tunis'),
('Karim Mansouri',     29, 'Sousse',     'Tunisia', 'Tunis'),
('Nadia Chaouachi',    55, 'Tunis',      'Tunisia', 'Tunis'),
('Yassine Trabelsi',   33, 'Bizerte',    'Tunisia', 'Tunis'),

-- Site Montréal (Canada)
('Sophie Tremblay',    47, 'Montreal',   'Canada',  'Montreal'),
('Marc Gauthier',      61, 'Quebec',     'Canada',  'Montreal'),
('Julie Bouchard',     25, 'Ottawa',     'Canada',  'Montreal'),
('Pierre Lavoie',      58, 'Montreal',   'Canada',  'Montreal'),
('Isabelle Cote',      36, 'Laval',      'Canada',  'Montreal'),

-- Site Tokyo (Japan)
('Yuki Tanaka',        42, 'Tokyo',      'Japan',   'Tokyo'),
('Hiroshi Yamamoto',   68, 'Osaka',      'Japan',   'Tokyo'),
('Sakura Nakamura',    31, 'Kyoto',      'Japan',   'Tokyo'),
('Kenji Suzuki',       49, 'Nagoya',     'Japan',   'Tokyo'),
('Aiko Watanabe',      27, 'Tokyo',      'Japan',   'Tokyo');


-- ── MedicalRecords (dossiers médicaux) ──────────────────────

INSERT INTO MedicalRecords (idPatient, country, date, examType, result, aiModelUsed, aiScore, aiVersion) VALUES
-- Patients France (idPatient 1-5)
(1, 'France', '2024-01-15', 'IRM Cérébrale',    'Résultat normal, pas d anomalie détectée',               'DiagNet-3',  0.9812, 'v3.2'),
(1, 'France', '2024-03-20', 'Scanner Thoracique','Légère opacité pulmonaire, surveillance recommandée',    'PulmoAI-2',  0.8745, 'v2.1'),
(2, 'France', '2024-02-10', 'Bilan sanguin',     'Glycémie élevée : 1.32 g/L, risque diabète type 2',     'BiologIA-1', 0.9234, 'v1.5'),
(3, 'France', '2024-04-05', 'Échographie',       'RAS – examen dans les normes',                           'EchoScan-4', 0.9567, 'v4.0'),
(4, 'France', '2024-05-12', 'IRM Lombaire',      'Hernie discale L4-L5 confirmée',                        'SpineAI-2',  0.9921, 'v2.3'),

-- Patients Tunisia (idPatient 6-10)
(6, 'Tunisia', '2024-01-22', 'Scanner Abdominal','Calcul rénal droit détecté 8mm',                        'NephroAI-1', 0.9678, 'v1.8'),
(7, 'Tunisia', '2024-02-28', 'ECG',              'Extrasystoles ventriculaires isolées, bénignes',        'CardioNet-3',0.8912, 'v3.1'),
(8, 'Tunisia', '2024-03-15', 'IRM Genou',        'Lésion ménisque médial grade 2',                        'OrthoAI-2',  0.9345, 'v2.0'),
(9, 'Tunisia', '2024-04-18', 'Bilan sanguin',    'Cholestérol LDL élevé : 1.85 g/L',                     'BiologIA-1', 0.9102, 'v1.5'),

-- Patients Canada (idPatient 11-15)
(11,'Canada',  '2024-01-30', 'Mammographie',     'Microcalcifications suspectes – biopsie recommandée',   'MammoAI-5',  0.9456, 'v5.1'),
(12,'Canada',  '2024-02-14', 'IRM Cérébrale',    'Leucoaraïose modérée compatible avec l âge',            'DiagNet-3',  0.8234, 'v3.2'),
(13,'Canada',  '2024-03-22', 'Scanner Thoracique','Nodule pulmonaire 6mm – contrôle dans 6 mois',         'PulmoAI-2',  0.9789, 'v2.1'),

-- Patients Japan (idPatient 16-20)
(16,'Japan',   '2024-01-18', 'Endoscopie',       'Gastrite chronique modérée – H. pylori positif',        'GastroAI-2', 0.9623, 'v2.4'),
(17,'Japan',   '2024-02-25', 'Scanner Cardiaque','Calcifications coronaires légères (score Agatston: 85)','CardioNet-3',0.9012, 'v3.1'),
(18,'Japan',   '2024-04-10', 'IRM Genou',        'Rupture partielle ligament croisé antérieur',           'OrthoAI-2',  0.9834, 'v2.0');


-- ── TrainingData (données pour entraîner les modèles IA) ────

INSERT INTO TrainingData (idRecord, siteOrigin, featureVector, label, quality) VALUES
-- Site Paris
(1, 'Paris',    '{"age":34,"gender":"F","exam":"IRM","region":"brain","features":[0.12,0.87,0.34,0.95,0.11]}',  'normal',    'premium'),
(2, 'Paris',    '{"age":34,"gender":"F","exam":"CT","region":"chest","features":[0.45,0.23,0.78,0.56,0.89]}',   'suspicious','standard'),
(3, 'Paris',    '{"age":67,"gender":"M","exam":"blood","glycemia":1.32,"features":[0.91,0.45,0.67,0.23,0.88]}', 'diabete_risk','premium'),
(4, 'Paris',    '{"age":28,"gender":"F","exam":"echo","features":[0.22,0.11,0.94,0.76,0.33]}',                  'normal',    'standard'),

-- Site Tunis
(6, 'Tunis',    '{"age":45,"gender":"M","exam":"CT","region":"abdomen","features":[0.78,0.92,0.15,0.67,0.43]}', 'kidney_stone','premium'),
(7, 'Tunis',    '{"age":38,"gender":"F","exam":"ECG","features":[0.34,0.56,0.82,0.29,0.71]}',                   'arrhythmia','standard'),
(8, 'Tunis',    '{"age":29,"gender":"M","exam":"IRM","region":"knee","features":[0.63,0.47,0.85,0.22,0.91]}',   'meniscus_lesion','premium'),

-- Site Montréal
(11,'Montreal', '{"age":47,"gender":"F","exam":"mammo","features":[0.89,0.76,0.34,0.92,0.18]}',                 'suspicious','premium'),
(12,'Montreal', '{"age":61,"gender":"M","exam":"IRM","region":"brain","features":[0.41,0.63,0.27,0.85,0.52]}',  'leucoaraiose','standard'),
(13,'Montreal', '{"age":25,"gender":"F","exam":"CT","region":"chest","features":[0.77,0.88,0.55,0.33,0.96]}',   'nodule',    'premium'),

-- Site Tokyo
(16,'Tokyo',    '{"age":42,"gender":"F","exam":"endo","features":[0.58,0.74,0.91,0.36,0.63]}',                  'gastritis', 'standard'),
(17,'Tokyo',    '{"age":68,"gender":"M","exam":"CT","region":"heart","agatston":85,"features":[0.82,0.67,0.43,0.91,0.25]}','calcification','premium'),
(18,'Tokyo',    '{"age":31,"gender":"F","exam":"IRM","region":"knee","features":[0.95,0.83,0.71,0.59,0.47]}',   'ACL_rupture','premium');


-- ── Transactions financières ─────────────────────────────────

INSERT INTO Transactions (idPatient, country, type, amount, currency, status, date) VALUES
-- France
(1, 'France',  'consultation',  75.00,  'EUR', 'committed',  '2024-01-15 09:30:00'),
(1, 'France',  'consultation',  75.00,  'EUR', 'committed',  '2024-03-20 14:15:00'),
(2, 'France',  'consultation',  120.00, 'EUR', 'committed',  '2024-02-10 11:00:00'),
(3, 'France',  'abonnement',    49.99,  'EUR', 'committed',  '2024-04-01 00:00:00'),
(4, 'France',  'consultation',  95.00,  'EUR', 'pending',    '2024-05-12 10:45:00'),
(5, 'France',  'remboursement', -75.00, 'EUR', 'committed',  '2024-05-20 16:00:00'),

-- Tunisia
(6, 'Tunisia', 'consultation',  120.00, 'TND', 'committed',  '2024-01-22 10:00:00'),
(7, 'Tunisia', 'consultation',   85.00, 'TND', 'committed',  '2024-02-28 09:30:00'),
(8, 'Tunisia', 'abonnement',     39.99, 'TND', 'committed',  '2024-03-01 00:00:00'),
(9, 'Tunisia', 'consultation',  100.00, 'TND', 'pending',    '2024-04-18 14:00:00'),

-- Canada
(11,'Canada',  'consultation',  200.00, 'CAD', 'committed',  '2024-01-30 08:45:00'),
(12,'Canada',  'abonnement',     59.99, 'CAD', 'committed',  '2024-02-01 00:00:00'),
(13,'Canada',  'consultation',  180.00, 'CAD', 'committed',  '2024-03-22 11:30:00'),
(14,'Canada',  'remboursement',-200.00, 'CAD', 'aborted',    '2024-04-05 15:00:00'),

-- Japan
(16,'Japan',   'consultation',  15000,  'JPY', 'committed',  '2024-01-18 09:00:00'),
(17,'Japan',   'abonnement',     7500,  'JPY', 'committed',  '2024-02-01 00:00:00'),
(18,'Japan',   'consultation',  12000,  'JPY', 'pending',    '2024-04-10 13:00:00'),
(19,'Japan',   'remboursement',-15000,  'JPY', 'committed',  '2024-04-25 10:00:00');


-- ── Vérification rapide ──────────────────────────────────────
DO $$
DECLARE
    nb_patients     INTEGER;
    nb_records      INTEGER;
    nb_training     INTEGER;
    nb_trans        INTEGER;
BEGIN
    SELECT COUNT(*) INTO nb_patients    FROM Patients;
    SELECT COUNT(*) INTO nb_records     FROM MedicalRecords;
    SELECT COUNT(*) INTO nb_training    FROM TrainingData;
    SELECT COUNT(*) INTO nb_trans       FROM Transactions;

    RAISE NOTICE '📊 Données insérées avec succès :';
    RAISE NOTICE '   - Patients      : %', nb_patients;
    RAISE NOTICE '   - MedicalRecords: %', nb_records;
    RAISE NOTICE '   - TrainingData  : %', nb_training;
    RAISE NOTICE '   - Transactions  : %', nb_trans;
END $$;
