-- ============================================================
-- MediAI – Initialisation du cluster Citus
-- À exécuter sur le COORDINATOR après docker-compose up -d
-- ============================================================

-- ── Étape 1 : Enregistrer les workers dans le coordinator ──
SELECT citus_add_node('citus_worker1', 5432);
SELECT citus_add_node('citus_worker2', 5432);
SELECT citus_add_node('citus_worker3', 5432);

-- Vérification : lister les nœuds du cluster
SELECT nodeid, nodename, nodeport, isactive
FROM pg_dist_node
ORDER BY nodeid;

-- ── Étape 2 : Distribuer les tables ────────────────────────

-- Patients : distribué par country (fragmentation horizontale géographique)
SELECT create_distributed_table('Patients', 'country');

-- TrainingData : distribué par siteOrigin
SELECT create_distributed_table('TrainingData', 'siteOrigin');

-- MedicalRecords : co-localisé avec Patients (même clé de distribution)
SELECT create_distributed_table('MedicalRecords', 'country');

-- Transactions : distribué par country (pour fragmentation hybride)
SELECT create_distributed_table('Transactions', 'country');

-- ── Étape 3 : Vérification de la distribution ──────────────

-- Voir les shards créés par Citus
SELECT logicalrelid, shardid, shardminvalue, shardmaxvalue
FROM pg_dist_shard
ORDER BY logicalrelid, shardid;

-- Voir la répartition des shards sur les workers
SELECT s.logicalrelid, s.shardid, p.nodename, p.nodeport
FROM pg_dist_shard s
JOIN pg_dist_shard_placement p ON s.shardid = p.shardid
ORDER BY s.logicalrelid, s.shardid;

-- ── Message de confirmation ─────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '✅ Cluster MediAI initialisé avec succès !';
    RAISE NOTICE '   - 1 Coordinator (Paris HQ)';
    RAISE NOTICE '   - 3 Workers (Tunis, Montréal, Tokyo)';
    RAISE NOTICE '   - 4 tables distribuées';
END $$;
