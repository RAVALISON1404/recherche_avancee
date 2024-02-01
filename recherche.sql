--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Ubuntu 15.5-0ubuntu0.23.10.1)
-- Dumped by pg_dump version 16.0 (Ubuntu 16.0-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: recherche; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE recherche WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'fr_FR.UTF-8';


ALTER DATABASE recherche OWNER TO postgres;

\connect recherche

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: getcolonnes(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getcolonnes(mots character varying) RETURNS TABLE(id integer, nom character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.getcolonnes(mots character varying) OWNER TO postgres;

--
-- Name: getmotcle(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getmotcle(mots character varying) RETURNS TABLE(id integer, nom character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.getmotcle(mots character varying) OWNER TO postgres;

--
-- Name: recherche_produit(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.recherche_produit(phrase character varying) RETURNS TABLE(id integer, designation character varying, prix double precision, qualite integer, categorie character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.recherche_produit(phrase character varying) OWNER TO postgres;

--
-- Name: test(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.test(phrase character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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
        SELECT *
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
    RETURN query_text;
END;
$$;


ALTER FUNCTION public.test(phrase character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    id integer NOT NULL,
    nom character varying NOT NULL
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- Name: categorie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categorie_id_seq OWNER TO postgres;

--
-- Name: categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorie_id_seq OWNED BY public.categorie.id;


--
-- Name: colonne; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.colonne (
    id integer NOT NULL,
    nom character varying NOT NULL
);


ALTER TABLE public.colonne OWNER TO postgres;

--
-- Name: colonne_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.colonne_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.colonne_id_seq OWNER TO postgres;

--
-- Name: colonne_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.colonne_id_seq OWNED BY public.colonne.id;


--
-- Name: combinaison; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.combinaison (
    id integer NOT NULL,
    motscle integer,
    colonne integer,
    operation character varying DEFAULT 'asc'::character varying
);


ALTER TABLE public.combinaison OWNER TO postgres;

--
-- Name: combinaison_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.combinaison_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.combinaison_id_seq OWNER TO postgres;

--
-- Name: combinaison_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.combinaison_id_seq OWNED BY public.combinaison.id;


--
-- Name: produit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produit (
    id integer NOT NULL,
    nom character varying NOT NULL,
    prix double precision NOT NULL,
    qualite integer DEFAULT 0 NOT NULL,
    id_categorie integer NOT NULL
);


ALTER TABLE public.produit OWNER TO postgres;

--
-- Name: detail_produit; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.detail_produit AS
 SELECT produit.id,
    produit.nom AS designation,
    produit.prix,
    produit.qualite,
    ((produit.qualite)::double precision / produit.prix) AS rapport,
    categorie.nom AS categorie
   FROM (public.produit
     JOIN public.categorie ON ((produit.id_categorie = categorie.id)));


ALTER VIEW public.detail_produit OWNER TO postgres;

--
-- Name: motscle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motscle (
    id integer NOT NULL,
    nom character varying NOT NULL
);


ALTER TABLE public.motscle OWNER TO postgres;

--
-- Name: motscle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motscle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motscle_id_seq OWNER TO postgres;

--
-- Name: motscle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motscle_id_seq OWNED BY public.motscle.id;


--
-- Name: produit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produit_id_seq OWNER TO postgres;

--
-- Name: produit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produit_id_seq OWNED BY public.produit.id;


--
-- Name: categorie id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN id SET DEFAULT nextval('public.categorie_id_seq'::regclass);


--
-- Name: colonne id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colonne ALTER COLUMN id SET DEFAULT nextval('public.colonne_id_seq'::regclass);


--
-- Name: combinaison id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.combinaison ALTER COLUMN id SET DEFAULT nextval('public.combinaison_id_seq'::regclass);


--
-- Name: motscle id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motscle ALTER COLUMN id SET DEFAULT nextval('public.motscle_id_seq'::regclass);


--
-- Name: produit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produit ALTER COLUMN id SET DEFAULT nextval('public.produit_id_seq'::regclass);


--
-- Data for Name: categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorie (id, nom) FROM stdin;
1	Mode et Vêtements
2	Maison et Décoration
3	Alimentation et Boissons
4	Santé et Beauté
5	Sports et Loisirs
6	Livres et Médias
7	Outils et Bricolage
8	Animaux de compagnie
\.


--
-- Data for Name: colonne; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.colonne (id, nom) FROM stdin;
1	Prix
2	Qualite
3	Rapport
\.


--
-- Data for Name: combinaison; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.combinaison (id, motscle, colonne, operation) FROM stdin;
1	1	1	asc
2	2	1	desc
3	3	1	desc
4	4	1	asc
5	1	2	desc
6	2	2	asc
7	3	2	desc
8	4	2	asc
9	1	3	desc
10	2	3	asc
11	3	3	desc
12	4	3	asc
\.


--
-- Data for Name: motscle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motscle (id, nom) FROM stdin;
1	Meilleur
2	Pire
3	Plus
4	Moins
\.


--
-- Data for Name: produit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produit (id, nom, prix, qualite, id_categorie) FROM stdin;
1	Chemise en coton	25.99	8	1
2	Lampe de table moderne	49.99	9	2
3	Pommes Granny Smith (1 kg)	2.49	7	3
4	Crème hydratante pour le visage	12.99	9	4
5	Ballon de football	19.99	8	5
6	Roman "Le Petit Prince" par Antoine de Saint-Exupéry	9.99	10	6
7	Ensemble de tournevis Phillips et à fente	29.99	7	7
8	Croquettes pour chat (sac de 5 kg)	14.99	8	8
9	Chemise en lin	35.5	7	1
10	Table basse en bois massif	129.99	9	2
11	Jus d'orange frais (1 litre)	3.99	8	3
12	Masque facial hydratant à l'aloé vera	15.5	9	4
13	Ballon de basketball	24.99	8	5
14	Guide de voyage "Lonely Planet: Japon"	19.95	9	6
15	Perceuse électrique sans fil	79.99	8	7
16	Croquettes pour chien (sac de 10 kg)	29.99	9	8
17	T-shirt en coton biologique	19.99	9	1
18	Cadre photo en métal noir	12.5	8	2
19	Pain de campagne artisanal (500 g)	4.5	7	3
20	Shampooing nourrissant à l'huile d'argan	8.99	9	4
21	Raquette de tennis	89.99	8	5
22	Guide de cuisine "Jamie Oliver: 5 Ingredients"	29.95	10	6
23	Scie à onglet à double biseau	199.99	9	7
24	Litière pour chat (sac de 15 kg)	34.99	8	8
\.


--
-- Name: categorie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorie_id_seq', 8, true);


--
-- Name: colonne_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.colonne_id_seq', 3, true);


--
-- Name: combinaison_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.combinaison_id_seq', 12, true);


--
-- Name: motscle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motscle_id_seq', 4, true);


--
-- Name: produit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.produit_id_seq', 24, true);


--
-- Name: categorie categorie_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pk PRIMARY KEY (id);


--
-- Name: colonne colonne_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colonne
    ADD CONSTRAINT colonne_pk PRIMARY KEY (id);


--
-- Name: combinaison combinaison_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.combinaison
    ADD CONSTRAINT combinaison_pk PRIMARY KEY (id);


--
-- Name: motscle motscle_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motscle
    ADD CONSTRAINT motscle_pk PRIMARY KEY (id);


--
-- Name: produit produit_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_pk PRIMARY KEY (id);


--
-- Name: idx_recherche_categorie; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recherche_categorie ON public.categorie USING gin (to_tsvector('french'::regconfig, (nom)::text));


--
-- Name: idx_recherche_colonne; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recherche_colonne ON public.colonne USING gin (to_tsvector('french'::regconfig, (nom)::text));


--
-- Name: idx_recherche_motscle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recherche_motscle ON public.motscle USING gin (to_tsvector('french'::regconfig, (nom)::text));


--
-- Name: combinaison combinaison_colonne_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.combinaison
    ADD CONSTRAINT combinaison_colonne_id_fk FOREIGN KEY (colonne) REFERENCES public.colonne(id);


--
-- Name: combinaison combinaison_motscle_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.combinaison
    ADD CONSTRAINT combinaison_motscle_id_fk FOREIGN KEY (motscle) REFERENCES public.motscle(id);


--
-- Name: produit produit_categorie_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_categorie_id_fk FOREIGN KEY (id_categorie) REFERENCES public.categorie(id);


--
-- PostgreSQL database dump complete
--

