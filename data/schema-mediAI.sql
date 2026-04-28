-- ============================================================
-- MediAI – Schéma de base de données distribuée
-- Chapitre 2 : Distributed Databases – ENSTA 3A
-- ============================================================

-- Extension Citus (déjà installée dans l'image Docker)
CREATE EXTENSION IF NOT EXISTS citus;

-- ────────────────────────────────────────────────────────────
-- TABLE 1 : Patients
-- Clé de distribution : country (pour fragmentation horizontale)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS Patients (
    idPatient   SERIAL,
    name        VARCHAR(100)    NOT NULL,
    age         INTEGER         CHECK (age >= 0 AND age <= 150),
    city        VARCHAR(100),
    country     VARCHAR(100)    NOT NULL,
    siteOrigin  VARCHAR(50),    -- site qui gère ce patient
    createdAt   TIMESTAMP       DEFAULT NOW(),
    PRIMARY KEY (idPatient, country)  -- clé composite pour Citus
);

-- ────────────────────────────────────────────────────────────
-- TABLE 2 : MedicalRecords (Dossiers médicaux)
-- Fragmentation verticale candidate :
--   Fragment A (données cliniques)  → idRecord, idPatient, date, examType, result
--   Fragment B (données IA)         → idRecord, idPatient, aiModelUsed, aiScore, aiVersion
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS MedicalRecords (
    idRecord    SERIAL          PRIMARY KEY,
    idPatient   INTEGER         NOT NULL,
    country     VARCHAR(100)    NOT NULL,   -- pour co-localisation
    date        DATE            NOT NULL,
    examType    VARCHAR(100),              -- ex: 'IRM', 'Scanner', 'Bilan sanguin'
    result      TEXT,
    aiModelUsed VARCHAR(50),              -- ex: 'GPT-Med-4', 'DiagNet-3'
    aiScore     DECIMAL(5,4),            -- score de confiance IA (0.0000 – 1.0000)
    aiVersion   VARCHAR(20)
);

-- ────────────────────────────────────────────────────────────
-- TABLE 3 : TrainingData (Données d'entraînement IA)
-- Fragmentation horizontale par siteOrigin
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TrainingData (
    idData          SERIAL          PRIMARY KEY,
    idRecord        INTEGER         NOT NULL,
    siteOrigin      VARCHAR(50)     NOT NULL,  -- 'Paris'|'Tunis'|'Montreal'|'Tokyo'
    featureVector   TEXT,                      -- vecteur de features (JSON ou CSV)
    label           VARCHAR(50),               -- diagnostic cible
    quality         VARCHAR(20)     DEFAULT 'standard',  -- 'standard'|'premium'
    createdAt       TIMESTAMP       DEFAULT NOW()
);

-- ────────────────────────────────────────────────────────────
-- TABLE 4 : Transactions financières
-- Fragmentation hybride : H par country + V par type de données
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS Transactions (
    idTrans     SERIAL          PRIMARY KEY,
    idPatient   INTEGER         NOT NULL,
    country     VARCHAR(100)    NOT NULL,   -- pour fragmentation H
    date        TIMESTAMP       DEFAULT NOW(),
    type        VARCHAR(50),               -- 'consultation'|'abonnement'|'remboursement'
    amount      DECIMAL(10,2)   NOT NULL,
    currency    VARCHAR(10)     DEFAULT 'EUR',
    status      VARCHAR(20)     DEFAULT 'pending'  -- 'pending'|'committed'|'aborted'
);

-- ────────────────────────────────────────────────────────────
-- VUES pour la fragmentation verticale de MedicalRecords
-- ────────────────────────────────────────────────────────────

-- Fragment A : Données cliniques (utilisées par les médecins)
CREATE OR REPLACE VIEW MedicalRecords_Clinical AS
    SELECT idRecord, idPatient, country, date, examType, result
    FROM MedicalRecords;

-- Fragment B : Données IA (utilisées par les data scientists)
CREATE OR REPLACE VIEW MedicalRecords_AI AS
    SELECT idRecord, idPatient, country, aiModelUsed, aiScore, aiVersion
    FROM MedicalRecords;

-- ────────────────────────────────────────────────────────────
-- VUES pour la fragmentation hybride de Transactions
-- ────────────────────────────────────────────────────────────

-- Fragment Hybride H1-V1 : Consultations France
CREATE OR REPLACE VIEW Trans_France_Consult AS
    SELECT idTrans, idPatient, date, amount, status
    FROM Transactions
    WHERE country = 'France' AND type = 'consultation';

-- Fragment Hybride H2-V1 : Consultations Tunisie
CREATE OR REPLACE VIEW Trans_Tunisia_Consult AS
    SELECT idTrans, idPatient, date, amount, status
    FROM Transactions
    WHERE country = 'Tunisia' AND type = 'consultation';

COMMENT ON TABLE Patients        IS 'Table principale des patients – distribuée par country';
COMMENT ON TABLE MedicalRecords  IS 'Dossiers médicaux – fragmentation verticale Clinical/AI';
COMMENT ON TABLE TrainingData    IS 'Données IA – fragmentation horizontale par siteOrigin';
COMMENT ON TABLE Transactions    IS 'Transactions financières – fragmentation hybride';
