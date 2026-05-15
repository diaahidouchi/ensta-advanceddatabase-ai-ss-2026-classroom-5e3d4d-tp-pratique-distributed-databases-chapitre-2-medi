-- Solutions élèves pour MediAI TP (Parts 1-5)

-- PARTIE 2 – FRAGMENTATION

-- 2.1 Vues : fragmentation horizontale de TrainingData
create or replace view trainingdata_paris as
    select * from trainingdata where siteorigin = 'Paris';

create or replace view trainingdata_tunis as
    select * from trainingdata where siteorigin = 'Tunis';

create or replace view trainingdata_montreal as
    select * from trainingdata where siteorigin = 'Montreal';

create or replace view trainingdata_tokyo as
    select * from trainingdata where siteorigin = 'Tokyo';

-- 2.2 Fragmentation verticale : création des tables physiques
create table if not exists medrec_clinical (
    idrecord integer not null,
    idpatient integer not null,
    country varchar(100) not null,
    date date,
    examtype varchar(100),
    result text,
    primary key (idrecord)
);

create table if not exists medrec_ai (
    idrecord integer not null,
    idpatient integer not null,
    country varchar(100) not null,
    aimodelused varchar(50),
    aiscore decimal(5,4),
    aiversion varchar(20),
    primary key (idrecord)
);

-- peupler les fragments depuis la table principale
insert into medrec_clinical (idrecord, idpatient, country, date, examtype, result)
    select idrecord, idpatient, country, date, examtype, result
    from medicalrecords;

insert into medrec_ai (idrecord, idpatient, country, aimodelused, aiscore, aiversion)
    select idrecord, idpatient, country, aimodelused, aiscore, aiversion
    from medicalrecords;

-- test de reconstruction
select fc.idrecord, fc.idpatient, fc.date, fc.examtype, fc.result,
       fi.aimodelused, fi.aiscore, fi.aiversion
from medrec_clinical fc
join medrec_ai fi on fc.idrecord = fi.idrecord
order by fc.idrecord;

-- 2.3 Fragmentation hybride : vues financières / gestion par pays
create or replace view trans_fr_financial as
    select idtrans, idpatient, date, amount, currency
    from transactions where country = 'France';

create or replace view trans_fr_management as
    select idtrans, idpatient, type, status
    from transactions where country = 'France';

create or replace view trans_tn_financial as
    select idtrans, idpatient, date, amount, currency
    from transactions where country = 'Tunisia';

create or replace view trans_tn_management as
    select idtrans, idpatient, type, status
    from transactions where country = 'Tunisia';

create or replace view trans_ca_financial as
    select idtrans, idpatient, date, amount, currency
    from transactions where country = 'Canada';

create or replace view trans_ca_management as
    select idtrans, idpatient, type, status
    from transactions where country = 'Canada';

create or replace view trans_jp_financial as
    select idtrans, idpatient, date, amount, currency
    from transactions where country = 'Japan';

create or replace view trans_jp_management as
    select idtrans, idpatient, type, status
    from transactions where country = 'Japan';

-- reconstruction pour la France
select fin.idtrans, fin.idpatient, fin.date, fin.amount, fin.currency,
       mgt.type, mgt.status
from trans_fr_financial fin
join trans_fr_management mgt on fin.idtrans = mgt.idtrans;


-- PARTIE 3 – REQUÊTES DISTRIBUÉES

-- Q1 : Profil complet du patient (exemple)
-- recherche par nom : utiliser un nom en arabe
select p.name, p.age, p.city, p.country,
       mr.date, mr.examtype, mr.result, mr.aimodelused, mr.aiscore
from patients p
join medicalrecords mr on p.idpatient = mr.idpatient and p.country = mr.country
where p.name = 'محمد بن علي'
order by mr.date desc;

-- Q2 : Performance moyenne des modèles IA par site
select p.siteorigin as site, mr.aimodelused as modele_ia,
       count(mr.idrecord) as nb_examens,
       round(avg(mr.aiscore)::numeric, 4) as score_moyen,
       round(min(mr.aiscore)::numeric, 4) as score_min,
       round(max(mr.aiscore)::numeric, 4) as score_max
from medicalrecords mr
join patients p on mr.idpatient = p.idpatient and mr.country = p.country
where mr.aiscore is not null
group by p.siteorigin, mr.aimodelused
order by p.siteorigin, score_moyen desc;

-- Q3 : Patients avec score IA élevé (>0.95)
select p.name, p.country, mr.examtype, mr.aimodelused, mr.aiscore,
       case
           when mr.aiscore >= 0.99 then 'Critique'
           when mr.aiscore >= 0.97 then 'Élevé'
           when mr.aiscore >= 0.95 then 'Modéré'
           else 'Normal' end as niveau_alerte
from medicalrecords mr
join patients p on mr.idpatient = p.idpatient and mr.country = p.country
where mr.aiscore > 0.95
order by mr.aiscore desc;

-- Q4 : Chiffre d'affaires par pays (status = 'committed')
select country, currency, type,
       count(*) as nb_transactions,
       sum(amount) as total_amount,
       avg(amount) as avg_amount
from transactions
where status = 'committed' and amount > 0
group by country, currency, type
order by country, total_amount desc;
-- PARTIE 4 – TRANSACTIONS DISTRIBUÉES 2PC (exemple de préparation)
begin;
insert into medicalrecords (idpatient, country, date, examtype, result, aimodelused, aiscore, aiversion)
values (16, 'Japan', now()::date, 'Consultation urgence', 'Bilan général - patient en déplacement', 'DiagNet-3', 0.8934, 'v3.2');

insert into transactions (idpatient, country, date, type, amount, currency, status)
values (16, 'Japan', now(), 'consultation', 15000, 'JPY', 'pending');

prepare transaction 'mediai_urgence_yuki_2024';

-- valider: COMMIT PREPARED 'mediai_urgence_yuki_2024';
-- annuler: ROLLBACK PREPARED 'mediai_urgence_yuki_2024';


-- PARTIE 5 – BONUS : plans d'exécution et monitoring

-- Exemples : comparer scans avec/sans clé de distribution
explain analyze select * from patients where name = 'Alice Dupont';
explain analyze select * from patients where country = 'France' and name = 'Alice Dupont';

-- État du cluster
select nodeid, nodename, nodeport, isactive, noderole from pg_dist_node;
select p.nodename, count(*) as nb_shards from pg_dist_shard_placement p group by p.nodename order by nb_shards desc;
