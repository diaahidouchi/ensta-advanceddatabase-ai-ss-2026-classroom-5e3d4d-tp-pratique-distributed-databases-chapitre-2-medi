-- ============================================================
-- MediAI – CORRECTION RÉFÉRENCE (réservée au professeur)
-- Chapitre 2 : Distributed Databases – ENSTA 3A
-- ============================================================

-- ════════════════════════════════════════════════════════════
-- PARTIE 2 – FRAGMENTATION
-- ════════════════════════════════════════════════════════════

-- ── 2.1 Fragmentation horizontale TrainingData ───────────────

CREATE OR REPLACE VIEW TrainingData_Paris AS
    SELECT * FROM TrainingData WHERE siteOrigin = 'Paris';

CREATE OR REPLACE VIEW TrainingData_Tunis AS
    SELECT * FROM TrainingData WHERE siteOrigin = 'Tunis';

CREATE OR REPLACE VIEW TrainingData_Montreal AS
    SELECT * FROM TrainingData WHERE siteOrigin = 'Montreal';

CREATE OR REPLACE VIEW TrainingData_Tokyo AS
    SELECT * FROM TrainingData WHERE siteOrigin = 'Tokyo';

-- Vérification complétude
SELECT 'Paris'    AS fragment, COUNT(*) FROM TrainingData WHERE siteOrigin = 'Paris'
UNION ALL
SELECT 'Tunis',                COUNT(*) FROM TrainingData WHERE siteOrigin = 'Tunis'
UNION ALL
SELECT 'Montreal',             COUNT(*) FROM TrainingData WHERE siteOrigin = 'Montreal'
UNION ALL
SELECT 'Tokyo',                COUNT(*) FROM TrainingData WHERE siteOrigin = 'Tokyo'
UNION ALL
SELECT 'TOTAL',                COUNT(*) FROM TrainingData;


-- ── 2.2 Fragmentation verticale MedicalRecords ──────────────

-- Fragment A : Données cliniques
CREATE TABLE MedRec_Clinical (
    idRecord    INTEGER     NOT NULL,
    idPatient   INTEGER     NOT NULL,
    country     VARCHAR(100) NOT NULL,
    date        DATE,
    examType    VARCHAR(100),
    result      TEXT,
    PRIMARY KEY (idRecord)
);

-- Fragment B : Données IA
CREATE TABLE MedRec_AI (
    idRecord    INTEGER     NOT NULL,
    idPatient   INTEGER     NOT NULL,
    country     VARCHAR(100) NOT NULL,
    aiModelUsed VARCHAR(50),
    aiScore     DECIMAL(5,4),
    aiVersion   VARCHAR(20),
    PRIMARY KEY (idRecord)
);

-- Peupler les fragments
INSERT INTO MedRec_Clinical
    SELECT idRecord, idPatient, country, date, examType, result
    FROM MedicalRecords;

INSERT INTO MedRec_AI
    SELECT idRecord, idPatient, country, aiModelUsed, aiScore, aiVersion
    FROM MedicalRecords;

-- Test de reconstruction
SELECT fc.idRecord, fc.idPatient, fc.date, fc.examType, fc.result,
       fi.aiModelUsed, fi.aiScore, fi.aiVersion
FROM MedRec_Clinical fc
JOIN MedRec_AI fi ON fc.idRecord = fi.idRecord
ORDER BY fc.idRecord;


-- ── 2.3 Fragmentation hybride Transactions ───────────────────

-- France
CREATE OR REPLACE VIEW Trans_FR_Financial AS
    SELECT idTrans, idPatient, date, amount, currency
    FROM Transactions WHERE country = 'France';

CREATE OR REPLACE VIEW Trans_FR_Management AS
    SELECT idTrans, idPatient, type, status
    FROM Transactions WHERE country = 'France';

-- Tunisia
CREATE OR REPLACE VIEW Trans_TN_Financial AS
    SELECT idTrans, idPatient, date, amount, currency
    FROM Transactions WHERE country = 'Tunisia';

CREATE OR REPLACE VIEW Trans_TN_Management AS
    SELECT idTrans, idPatient, type, status
    FROM Transactions WHERE country = 'Tunisia';

-- Canada
CREATE OR REPLACE VIEW Trans_CA_Financial AS
    SELECT idTrans, idPatient, date, amount, currency
    FROM Transactions WHERE country = 'Canada';

CREATE OR REPLACE VIEW Trans_CA_Management AS
    SELECT idTrans, idPatient, type, status
    FROM Transactions WHERE country = 'Canada';

-- Japan
CREATE OR REPLACE VIEW Trans_JP_Financial AS
    SELECT idTrans, idPatient, date, amount, currency
    FROM Transactions WHERE country = 'Japan';

CREATE OR REPLACE VIEW Trans_JP_Management AS
    SELECT idTrans, idPatient, type, status
    FROM Transactions WHERE country = 'Japan';

-- Reconstruction France
SELECT fin.idTrans, fin.idPatient, fin.date, fin.amount, fin.currency,
       mgt.type, mgt.status
FROM Trans_FR_Financial fin
JOIN Trans_FR_Management mgt ON fin.idTrans = mgt.idTrans;


-- ════════════════════════════════════════════════════════════
-- PARTIE 3 – REQUÊTES DISTRIBUÉES
-- ════════════════════════════════════════════════════════════

-- Q1 : Profil complet Mohamed Benali
SELECT p.name, p.age, p.city, p.country,
       mr.date, mr.examType, mr.result, mr.aiModelUsed, mr.aiScore
FROM Patients p
JOIN MedicalRecords mr ON p.idPatient = mr.idPatient AND p.country = mr.country
WHERE p.name = 'Mohamed Benali'
ORDER BY mr.date DESC;

-- Q2 : Performance IA par site
SELECT p.siteOrigin, mr.aiModelUsed,
       COUNT(*) AS nb_examens,
       ROUND(AVG(mr.aiScore)::numeric, 4) AS score_moyen
FROM MedicalRecords mr
JOIN Patients p ON mr.idPatient = p.idPatient AND mr.country = p.country
WHERE mr.aiScore IS NOT NULL
GROUP BY p.siteOrigin, mr.aiModelUsed
ORDER BY p.siteOrigin, score_moyen DESC;

-- Q3 : Alertes IA score élevé
SELECT p.name, p.country, mr.examType, mr.aiModelUsed, mr.aiScore,
       CASE WHEN mr.aiScore >= 0.99 THEN 'Critique'
            WHEN mr.aiScore >= 0.97 THEN 'Élevé'
            ELSE 'Modéré' END AS niveau_alerte
FROM MedicalRecords mr
JOIN Patients p ON mr.idPatient = p.idPatient AND mr.country = p.country
WHERE mr.aiScore > 0.95
ORDER BY mr.aiScore DESC;

-- Q4 : CA par pays
SELECT country, currency, type,
       COUNT(*) AS nb_trans, SUM(amount) AS total, AVG(amount) AS moyenne
FROM Transactions
WHERE status = 'committed' AND amount > 0
GROUP BY country, currency, type
ORDER BY country, total DESC;


-- ════════════════════════════════════════════════════════════
-- PARTIE 4 – TRANSACTIONS DISTRIBUÉES 2PC
-- ════════════════════════════════════════════════════════════

-- Phase 1 : Prepare
BEGIN;
INSERT INTO MedicalRecords (idPatient, country, date, examType, result, aiModelUsed, aiScore, aiVersion)
VALUES (16, 'Japan', NOW()::DATE, 'Consultation urgence', 'Bilan en déplacement', 'DiagNet-3', 0.8934, 'v3.2');
INSERT INTO Transactions (idPatient, country, date, type, amount, currency, status)
VALUES (16, 'Japan', NOW(), 'consultation', 15000, 'JPY', 'pending');
PREPARE TRANSACTION 'mediAI_urgence_yuki_2024';

-- Vérification
SELECT gid, prepared FROM pg_prepared_xacts;

-- Phase 2 : Commit
COMMIT PREPARED 'mediAI_urgence_yuki_2024';

-- Ou Rollback (en cas d'échec)
-- ROLLBACK PREPARED 'mediAI_urgence_yuki_2024';

-- Mise à jour du status après commit
UPDATE Transactions SET status = 'committed'
WHERE idPatient = 16 AND type = 'consultation' AND status = 'pending'
ORDER BY date DESC
LIMIT 1;
