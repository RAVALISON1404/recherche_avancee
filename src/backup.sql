create or replace view detail_produit as
select produit.id,
       produit.nom                    as designation,
       produit.prix,
       produit.qualite,
       produit.qualite / produit.prix as rapport,
       categorie.nom                  as categorie
from produit
         join categorie on produit.id_categorie = categorie.id;

create table motscle
(
    id  serial
        constraint motscle_pk
            primary key,
    nom varchar not null
);

create table combinaison
(
    id        serial
        constraint combinaison_pk
            primary key,
    motscle   integer
        constraint combinaison_motscle_id_fk
            references motscle,
    colonne   integer
        constraint combinaison_colonne_id_fk
            references colonne,
    operation varchar default 'asc'
);

CREATE INDEX IF NOT EXISTS idx_recherche_produit ON produit USING gin (to_tsvector('french',
                                                                                   produit.nom ||
                                                                                   produit.id_categorie::varchar ||
                                                                                   produit.qualite::varchar ||
                                                                                   produit.prix::varchar));

CREATE INDEX IF NOT EXISTS idx_recherche_categorie ON categorie USING gin (to_tsvector('french', categorie.nom));

CREATE INDEX IF NOT EXISTS idx_recherche_colonne ON colonne USING gin (to_tsvector('french', colonne.nom));

CREATE INDEX IF NOT EXISTS idx_recherche_motscle ON motscle USING gin (to_tsvector('french', motscle.nom));

-- Insertion des données dans la table "categorie"
INSERT INTO categorie (nom)
VALUES ('Mode et Vêtements'),
       ('Maison et Décoration'),
       ('Alimentation et Boissons'),
       ('Santé et Beauté'),
       ('Sports et Loisirs'),
       ('Livres et Médias'),
       ('Outils et Bricolage'),
       ('Animaux de compagnie');

-- Insertion des données dans la table "produit"
INSERT INTO produit (nom, prix, qualite, id_categorie)
VALUES ('Chemise en coton', 25.99, 8, 1),
       ('Lampe de table moderne', 49.99, 9, 2),
       ('Pommes Granny Smith (1 kg)', 2.49, 7, 3),
       ('Crème hydratante pour le visage', 12.99, 9, 4),
       ('Ballon de football', 19.99, 8, 5),
       ('Roman "Le Petit Prince" par Antoine de Saint-Exupéry', 9.99, 10, 6),
       ('Ensemble de tournevis Phillips et à fente', 29.99, 7, 7),
       ('Croquettes pour chat (sac de 5 kg)', 14.99, 8, 8),
       ('Chemise en lin', 35.50, 7, 1),
       ('Table basse en bois massif', 129.99, 9, 2),
       ('Jus d''orange frais (1 litre)', 3.99, 8, 3),
       ('Masque facial hydratant à l''aloé vera', 15.50, 9, 4),
       ('Ballon de basketball', 24.99, 8, 5),
       ('Guide de voyage "Lonely Planet: Japon"', 19.95, 9, 6),
       ('Perceuse électrique sans fil', 79.99, 8, 7),
       ('Croquettes pour chien (sac de 10 kg)', 29.99, 9, 8),
       ('T-shirt en coton biologique', 19.99, 9, 1),
       ('Cadre photo en métal noir', 12.50, 8, 2),
       ('Pain de campagne artisanal (500 g)', 4.50, 7, 3),
       ('Shampooing nourrissant à l''huile d''argan', 8.99, 9, 4),
       ('Raquette de tennis', 89.99, 8, 5),
       ('Guide de cuisine "Jamie Oliver: 5 Ingredients"', 29.95, 10, 6),
       ('Scie à onglet à double biseau', 199.99, 9, 7),
       ('Litière pour chat (sac de 15 kg)', 34.99, 8, 8);

CREATE EXTENSION IF NOT EXISTS pg_trgm;

create table colonne
(
    id  serial
        constraint colonne_pk
            primary key,
    nom varchar not null
);

CREATE INDEX IF NOT EXISTS idx_recherche_produit ON produit USING gin (to_tsvector('french',
                                                                                   produit.nom ||
                                                                                   produit.id_categorie::varchar ||
                                                                                   produit.qualite::varchar ||
                                                                                   produit.prix::varchar));

CREATE INDEX IF NOT EXISTS idx_recherche_categorie ON categorie USING gin (to_tsvector('french', categorie.nom));

CREATE INDEX IF NOT EXISTS idx_recherche_colonne ON colonne USING gin (to_tsvector('french', colonne.nom));

CREATE OR REPLACE FUNCTION recherche_produit(phrase VARCHAR)
    RETURNS TABLE
            (
                id          INT,
                designation VARCHAR,
                prix        DOUBLE PRECISION,
                qualite     INT,
                categorie   VARCHAR
            )
AS
$$
DECLARE
    mots_array    VARCHAR[];
    mots_concat   VARCHAR;
    mots_like     VARCHAR := '';
    query_text    VARCHAR;
    colonne_tri   VARCHAR := '';
    operation_tri VARCHAR;
    nbr_colonne   integer := 1;
BEGIN
    SELECT nom INTO colonne_tri FROM getColonnes(phrase);
    SELECT operation
    INTO operation_tri
    FROM combinaison
             JOIN getMotCle(phrase) ON combinaison.motscle = getMotCle.id
             join getcolonnes(phrase) on combinaison.colonne = getcolonnes.id
    WHERE combinaison.colonne = getcolonnes.id
      and combinaison.motscle = getMotCle.id;
    SELECT count(nom) INTO nbr_colonne FROM getColonnes(phrase);
    if nbr_colonne > 1 then
        colonne_tri := 'rapport';
        select operation
        into operation_tri
        from combinaison
                 join getmotcle(phrase) on combinaison.motscle = getMotCle.id
        where colonne = 3
          and combinaison.motscle = getmotcle.id;
    end if;
    mots_array := string_to_array(phrase, ' ');
    mots_concat := array_to_string(mots_array, ' & ');
    FOR i IN 1..array_length(mots_array, 1)
        LOOP
            IF i > 1 THEN
                mots_like := mots_like || ' OR ';
            END IF;
            mots_like := mots_like || 'designation ILIKE ''%' || mots_array[i] || '%'' OR categorie ILIKE ''%' ||
                         mots_array[i] || '%''';
        END LOOP;

    query_text := '
        SELECT id::INT, designation::VARCHAR, prix::DOUBLE PRECISION, qualite::INT, categorie::VARCHAR
        FROM detail_produit
        WHERE to_tsvector(''french'', detail_produit.categorie || '' '') @@ plainto_tsquery(''french'', ''' ||
                  mots_concat || ''')
           OR to_tsvector(''french'', detail_produit.designation || '' '' || detail_produit.prix || '' '' || detail_produit.qualite) @@
              plainto_tsquery(''french'', ''' || mots_concat || ''')
           OR similarity_dist(detail_produit.designation, ''' || phrase || ''') =
              (SELECT MIN(similarity_dist(detail_produit.designation, ''' || phrase || ''')) FROM detail_produit)
            AND similarity_dist(detail_produit.categorie, ''' || phrase || ''') =
                (SELECT MIN(similarity_dist(detail_produit.categorie, ''' || phrase || ''')) FROM detail_produit)
           OR (' || mots_like || ')
        ORDER BY ' || colonne_tri || ' ' || operation_tri;
    RETURN QUERY EXECUTE query_text;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getColonnes(mots VARCHAR)
    RETURNS TABLE
            (
                id  INTEGER,
                nom varchar
            )
AS
$$
DECLARE
    mots_array VARCHAR[];
    mot_like   VARCHAR := '';
    query_text VARCHAR;
    i          INT;
BEGIN
    mots_array := string_to_array(mots, ' ');
    FOR i IN 1..array_length(mots_array, 1)
        LOOP
            IF i > 1 THEN
                mot_like := mot_like || ' OR ';
            END IF;
            mot_like := mot_like || 'colonne.nom ILIKE ''%' || mots_array[i] || '%''';
        END LOOP;

    query_text := '
        SELECT *
        FROM colonne
        WHERE to_tsvector(''french'', nom || '' '') @@ plainto_tsquery(''french'', ''' || mots || ''')
           OR similarity_dist(colonne.nom, ''' || mots || ''') =
              (SELECT MIN(similarity_dist(nom, ''' || mots || ''')) FROM colonne)
           OR (' || mot_like || ')';
    RETURN QUERY EXECUTE query_text;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getMotCle(mots VARCHAR)
    RETURNS TABLE
            (
                id  INTEGER,
                nom VARCHAR
            )
AS
$$
DECLARE
    mots_array VARCHAR[];
    mot_like   VARCHAR := '';
    query_text VARCHAR;
    i          INT;
BEGIN
    mots_array := string_to_array(mots, ' ');
    FOR i IN 1..array_length(mots_array, 1)
        LOOP
            IF i > 1 THEN
                mot_like := mot_like || ' OR ';
            END IF;
            mot_like := mot_like || 'motscle.nom ILIKE ''%' || mots_array[i] || '%''';
        END LOOP;

    query_text := '
        SELECT id, nom
        FROM motscle
        WHERE to_tsvector(''french'', nom || '' '') @@ plainto_tsquery(''french'', ''' || mots || ''')
           OR similarity_dist(motscle.nom, ''' || mots || ''') =
              (SELECT MIN(similarity_dist(nom, ''' || mots || ''')) FROM motscle)
           OR (' || mot_like || ')';

    RETURN QUERY EXECUTE query_text;
END;
$$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION recherche_avancee(phrase VARCHAR)
        RETURNS TABLE
                (
                    id          INT,
                    designation VARCHAR,
                    prix        DOUBLE PRECISION,
                    qualite     INT,
                    categorie   VARCHAR
                )
    AS
    $$
    DECLARE
        mots_array    VARCHAR[];
        mots_concat   VARCHAR;
        mots_like     VARCHAR := '';
        query_text    VARCHAR;
        colonne_tri   VARCHAR := '';
        operation_tri VARCHAR;
        nbr_colonne   integer := 1;
    BEGIN
        SELECT nom INTO colonne_tri FROM getColonnes(phrase);
        SELECT operation
        INTO operation_tri
        FROM combinaison
                JOIN getMotCle(phrase) ON combinaison.motscle = getMotCle.id
                join getcolonnes(phrase) on combinaison.colonne = getcolonnes.id
        WHERE combinaison.colonne = getcolonnes.id
        and combinaison.motscle = getMotCle.id;
        SELECT count(nom) INTO nbr_colonne FROM getColonnes(phrase);
        if nbr_colonne > 1 then
            colonne_tri := 'rapport';
            select operation
            into operation_tri
            from combinaison
                    join getmotcle(phrase) on combinaison.motscle = getMotCle.id
            where colonne = 3
            and combinaison.motscle = getmotcle.id;
        end if;
        mots_array := string_to_array(phrase, ' ');
        mots_concat := array_to_string(mots_array, ' & ');
        FOR i IN 1..array_length(mots_array, 1)
            LOOP
                IF i > 1 THEN
                    mots_like := mots_like || ' OR ';
                END IF;
                mots_like := mots_like || ' categorie ILIKE ''%' ||mots_array[i] || '%''';
            END LOOP;

        query_text := '
            SELECT id::INT, designation::VARCHAR, prix::DOUBLE PRECISION, qualite::INT, categorie::VARCHAR
            FROM detail_produit
            WHERE to_tsvector(''french'', detail_produit.categorie || '' '') @@ plainto_tsquery(''french'', ''' ||
                    mots_concat || ''')
            OR to_tsvector(''french'', detail_produit.prix || '' '' || detail_produit.qualite) @@
                plainto_tsquery(''french'', ''' || mots_concat || ''')
                OR similarity_dist(detail_produit.categorie, ''' || phrase || ''') =
                    (SELECT MIN(similarity_dist(detail_produit.categorie, ''' || phrase || ''')) FROM detail_produit)
            OR (' || mots_like || ')
            ORDER BY ' || colonne_tri || ' ' || operation_tri;
        RETURN QUERY EXECUTE query_text;
    END
    $$ LANGUAGE plpgsql;