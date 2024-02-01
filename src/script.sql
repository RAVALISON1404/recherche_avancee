
CREATE OR REPLACE FUNCTION recherche_produit_avancee(mots VARCHAR)
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
    nom_colonne   VARCHAR;
BEGIN
    FOR nom_colonne IN
        SELECT nom FROM getColonnes(mots)
        LOOP
            IF colonne_tri = '' THEN
                colonne_tri := nom_colonne;
            ELSE
                colonne_tri := colonne_tri || ', ' || nom_colonne;
            END IF;
        END LOOP;
    operation_tri := getmotcle(mots);
    mots_array := string_to_array(mots, ' ');
    mots_concat := array_to_string(mots_array, ' & ');
    FOR i IN 1..array_length(mots_array, 1)
        LOOP
            IF mots_array[i] NOT IN ('meilleur', 'pire', 'plus', 'moins', 'prix', 'qualite') THEN
                mots_like :=
                        mots_like || ' OR designation ILIKE ''%' || mots_array[i] || '%'' OR categorie ILIKE ''%' ||
                        mots_array[i] || '%''';
            END IF;
            IF i > 1 THEN
                mots_like := mots_like || ' OR ';
            END IF;
            mots_like := mots_like || 'designation ILIKE ''%' || mots_array[i] || '%'' OR categorie ILIKE ''%' ||
                         mots_array[i] || '%''';
        END LOOP;

    query_text := '
        SELECT *
        FROM detail_produit
        WHERE to_tsvector(''french'', detail_produit.categorie || '' '') @@ plainto_tsquery(''french'', ''' ||
                  mots_concat || ''')
           OR to_tsvector(''french'', detail_produit.designation || '' '' || detail_produit.prix || '' '' || detail_produit.qualite) @@
              plainto_tsquery(''french'', ''' || mots_concat || ''')
           OR similarity_dist(detail_produit.designation, ''' || mots || ''') =
              (SELECT MIN(similarity_dist(detail_produit.designation, ''' || mots || ''')) FROM detail_produit)
            AND similarity_dist(detail_produit.categorie, ''' || mots || ''') =
                (SELECT MIN(similarity_dist(detail_produit.categorie, ''' || mots || ''')) FROM detail_produit)
           OR (' || mots_like || ')
        ORDER BY ' || colonne_tri || ' ' || operation_tri;
    RETURN QUERY EXECUTE query_text;
END;
$$ LANGUAGE plpgsql;

create or replace function test(mots VARCHAR) returns varchar AS
$$
DECLARE
    mots_array    VARCHAR[];
    mots_concat   VARCHAR;
    mots_like     VARCHAR := '';
    query_text    VARCHAR;
    colonne_tri   VARCHAR := '';
    operation_tri VARCHAR;
    nom_colonne   VARCHAR;
BEGIN
    FOR nom_colonne IN
        SELECT nom FROM getColonnes(mots)
        LOOP
            IF colonne_tri = '' THEN
                colonne_tri := nom_colonne;
            ELSE
                colonne_tri := colonne_tri || ', ' || nom_colonne;
            END IF;
        END LOOP;
    operation_tri := getmotcle(mots);
    mots_array := string_to_array(mots, ' ');
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
        SELECT *
        FROM detail_produit
        WHERE to_tsvector(''french'', detail_produit.categorie || '' '') @@ plainto_tsquery(''french'', ''' ||
                  mots_concat || ''')
           OR to_tsvector(''french'', detail_produit.designation || '' '' || detail_produit.prix || '' '' || detail_produit.qualite) @@
              plainto_tsquery(''french'', ''' || mots_concat || ''')
           OR similarity_dist(detail_produit.designation, ''' || mots || ''') =
              (SELECT MIN(similarity_dist(detail_produit.designation, ''' || mots || ''')) FROM detail_produit)
            AND similarity_dist(detail_produit.categorie, ''' || mots || ''') =
                (SELECT MIN(similarity_dist(detail_produit.categorie, ''' || mots || ''')) FROM detail_produit)
           OR (' || mots_like || ')
        ORDER BY ' || colonne_tri || ' ' || operation_tri;
    RETURN query_text;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION test(mots VARCHAR)
    RETURNS VARCHAR
AS
$$
DECLARE
    mots_array    VARCHAR[];
    mots_concat   VARCHAR;
    mots_like     VARCHAR := '';
    query_text    VARCHAR;
    colonne_tri   VARCHAR := '';
    operation_tri VARCHAR;
    nom_colonne   VARCHAR;
    colonne_id    integer;
BEGIN
    FOR nom_colonne IN
        SELECT nom FROM getColonnes(mots)
        LOOP
            IF colonne_tri = '' THEN
                colonne_tri := '"' || nom_colonne || '"';
            ELSE
                colonne_tri := colonne_tri || ', "' || nom_colonne || '"';
            END IF;
        END LOOP;
    SELECT id INTO colonne_id FROM colonne WHERE nom = colonne_tri;
    SELECT operation
    INTO operation_tri
    FROM combinaison
             JOIN getMotCle(mots) ON combinaison.motscle = getMotCle.id
    WHERE combinaison.colonne = colonne_id;

    mots_array := string_to_array(mots, ' ');
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
        SELECT *
        FROM detail_produit
        WHERE to_tsvector(''french'', detail_produit.categorie || '' '') @@ plainto_tsquery(''french'', ''' ||
                  mots_concat || ''')
           OR to_tsvector(''french'', detail_produit.designation || '' '' || detail_produit.prix || '' '' || detail_produit.qualite) @@
              plainto_tsquery(''french'', ''' || mots_concat || ''')
           OR similarity_dist(detail_produit.designation, ''' || mots || ''') =
              (SELECT MIN(similarity_dist(detail_produit.designation, ''' || mots || ''')) FROM detail_produit)
            AND similarity_dist(detail_produit.categorie, ''' || mots || ''') =
                (SELECT MIN(similarity_dist(detail_produit.categorie, ''' || mots || ''')) FROM detail_produit)
           OR (' || mots_like || ')
        ORDER BY ' || colonne_tri || ' ' || operation_tri;
    RETURN colonne_tri;
END;
$$ LANGUAGE plpgsql;
