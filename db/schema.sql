--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.6
-- Dumped by pg_dump version 9.5.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bohrung; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bohrung;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = bohrung, pg_catalog;

--
-- Name: _archive_date_insert(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _archive_date_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF NEW.archive=1 THEN
NEW.archive_date := now();
END IF;


RETURN NEW;

END;
$$;


--
-- Name: _archive_date_update(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _archive_date_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF NEW.archive=1 and OLD.archive=0 THEN
NEW.archive_date := now();
END IF;


RETURN NEW;

END;
$$;


--
-- Name: _archive_dummy(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _archive_dummy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN



RETURN OLD;

END;
$$;


--
-- Name: _checkarchive(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _checkarchive() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE 
v_bohrung_id integer;

BEGIN



IF TG_OP = 'DELETE' THEN 
v_bohrung_id = OLD.bohrung_id;
ELSE
v_bohrung_id = NEW.bohrung_id;
END IF;


IF (select count(*) from bohrung.bohrprofil where v_bohrung_id=bohrung_id and archive =0) != 1 THEN
RAISE EXCEPTION 'Constraint Trigger: Genau ein Bohrprofil muss aktiv sein (archive=0)' ;
END IF;


RETURN NEW;

END;
$$;


--
-- Name: _insert_bohrprofil(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _insert_bohrprofil() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF (select count(bohrprofil_id) from bohrung.bohrprofil where bohrprofil_id = NEW.bohrprofil_id) > 0
THEN
NEW.bohrprofil_id := nextval('bohrung.bohrprofil_bohrprofil_id_seq');

END IF;

RETURN NEW;

END;
$$;


--
-- Name: FUNCTION _insert_bohrprofil(); Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON FUNCTION _insert_bohrprofil() IS 'Korrigiert die bohrprofil_id bei Verwendung der Klonfunktion';


--
-- Name: _insert_schicht(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _insert_schicht() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF (select count(schicht_id) from bohrung.schicht where schicht_id = NEW.schicht_id) > 0
THEN
NEW.schicht_id := nextval('bohrung.schicht_schicht_id_seq');

END IF;

RETURN NEW;

END;
$$;


--
-- Name: FUNCTION _insert_schicht(); Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON FUNCTION _insert_schicht() IS 'Korrigiert die schicht_id bei Verwendung der Klonfunktion';


--
-- Name: _insert_vorkommnis(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _insert_vorkommnis() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF (select count(vorkommnis_id) from bohrung.vorkommnis where vorkommnis_id = NEW.vorkommnis_id) > 0
THEN
NEW.vorkommnis_id := nextval('bohrung.vorkommnis_vorkommnis_id_seq');

END IF;

RETURN NEW;

END;
$$;


--
-- Name: FUNCTION _insert_vorkommnis(); Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON FUNCTION _insert_vorkommnis() IS 'Korrigiert die vorkommnis_id bei Verwendung der Klonfunktion';


--
-- Name: _mutation(); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION _mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

NEW.mut_date := now();
NEW.mut_usr := CURRENT_USER;

RETURN NEW;

END;
$$;


--
-- Name: FUNCTION _mutation(); Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON FUNCTION _mutation() IS 'Generische Mutatiosntriggerfunktion zum Setzen von mut_date und mut_usr';


--
-- Name: bohrprofil_clone(integer); Type: FUNCTION; Schema: bohrung; Owner: -
--

CREATE FUNCTION bohrprofil_clone(p_bohrprofil_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

declare v_bohrprofil_id integer;
declare v_bohrprofil bohrung.bohrprofil%ROWTYPE;
declare v_vorkommnis bohrung.vorkommnis%ROWTYPE;
declare v_schicht bohrung.schicht%ROWTYPE;

BEGIN

select * into v_bohrprofil from bohrung.bohrprofil where bohrprofil_id = p_bohrprofil_id;

v_bohrprofil.archive := 1;

insert into bohrung.bohrprofil values (v_bohrprofil.*)
returning bohrprofil_id into v_bohrprofil_id;

for v_schicht in select * from bohrung.schicht where bohrprofil_id = p_bohrprofil_id LOOP

v_schicht.bohrprofil_id := v_bohrprofil_id;

insert into bohrung.schicht values (v_schicht.*);
end loop;

for v_vorkommnis IN select * from bohrung.vorkommnis where bohrprofil_id=p_bohrprofil_id LOOP

v_vorkommnis.bohrprofil_id := v_bohrprofil_id;

insert into bohrung.vorkommnis values (v_vorkommnis.*);

end loop;




END;
$$;


--
-- Name: FUNCTION bohrprofil_clone(p_bohrprofil_id integer); Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON FUNCTION bohrprofil_clone(p_bohrprofil_id integer) IS 'Erstellt eine Kopie (Klon) eines Bohrprofils sowie der davon abhÃ¤ngenden EintrÃ¤ge in den Tabellen "schicht" und "vorkommnis"';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bohrprofil; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE bohrprofil (
    bohrprofil_id integer NOT NULL,
    bohrung_id integer,
    datum date,
    bemerkung text,
    abnahmedatum date,
    abnahmebem text,
    kote smallint,
    endteufe smallint,
    tektonik integer,
    fmfelso integer,
    fmeto integer,
    quali integer,
    qualibem text,
    wkb_geometry public.geometry,
    wkb_geometry95 public.geometry,
    archive_date timestamp without time zone DEFAULT '9999-01-01'::date,
    archive integer DEFAULT 0 NOT NULL,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_dims_wkb_geometry95 CHECK ((public.st_ndims(wkb_geometry95) = 2))
);


--
-- Name: TABLE bohrprofil; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE bohrprofil IS 'Informationen zum Bohrprofil. Ein Bohrprofil entspricht einer Bohrung bzw. eine Interpretation davon.';


--
-- Name: COLUMN bohrprofil.bohrprofil_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.bohrprofil_id IS 'Feature ID';


--
-- Name: COLUMN bohrprofil.datum; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.datum IS 'Datum des Bohrprofils';


--
-- Name: COLUMN bohrprofil.bemerkung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.bemerkung IS 'Bemerkung zum Bohrprofil';


--
-- Name: COLUMN bohrprofil.abnahmedatum; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.abnahmedatum IS 'Datum des Abnahmeprotokolls';


--
-- Name: COLUMN bohrprofil.abnahmebem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.abnahmebem IS 'Bemerkungen zum Abnahmeergebnis';


--
-- Name: COLUMN bohrprofil.kote; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.kote IS 'Terrainkote der Bohrung [m]';


--
-- Name: COLUMN bohrprofil.endteufe; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.endteufe IS 'Endtiefe der Bohrung [m]';


--
-- Name: COLUMN bohrprofil.tektonik; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.tektonik IS 'Klassierung Tektonik';


--
-- Name: COLUMN bohrprofil.fmfelso; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.fmfelso IS 'Formation Fels';


--
-- Name: COLUMN bohrprofil.fmeto; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.fmeto IS 'Formation Endtiefe';


--
-- Name: COLUMN bohrprofil.quali; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.quali IS 'Qualität der Angaben zum Bohrprofil';


--
-- Name: COLUMN bohrprofil.qualibem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.qualibem IS 'Bemerkung zur Qualitätsangabe';


--
-- Name: COLUMN bohrprofil.wkb_geometry; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.wkb_geometry IS 'OGC WKB Geometrie SRID 21781 LV03';


--
-- Name: COLUMN bohrprofil.wkb_geometry95; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.wkb_geometry95 IS 'OGC WKB Geometrie SRID 2056 LV95';


--
-- Name: COLUMN bohrprofil.archive_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.archive_date IS 'Datum der Archvierung des Objektes';


--
-- Name: COLUMN bohrprofil.archive; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.archive IS '0: aktiv, 1: archiviert';


--
-- Name: COLUMN bohrprofil.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.new_date IS 'Datum des Imports des Objektes';


--
-- Name: COLUMN bohrprofil.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN bohrprofil.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN bohrprofil.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrprofil.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: bohrprofil_bohrprofil_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE bohrprofil_bohrprofil_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bohrprofil_bohrprofil_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE bohrprofil_bohrprofil_id_seq OWNED BY bohrprofil.bohrprofil_id;


--
-- Name: bohrung; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE bohrung (
    bohrung_id integer NOT NULL,
    standort_id integer NOT NULL,
    bezeichnung text NOT NULL,
    bemerkung text,
    datum date,
    besitzer text,
    durchmesserbohrloch smallint,
    bohrart integer,
    bohrzweck integer,
    ablenkung integer,
    ablenkungbem text,
    quali integer,
    qualibem text,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    quelleref text,
    hotlinka text,
    hotlinkf text,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying
);


--
-- Name: TABLE bohrung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE bohrung IS 'Informationen zur Bohrung';


--
-- Name: COLUMN bohrung.bohrung_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.bohrung_id IS 'Feature ID';


--
-- Name: COLUMN bohrung.standort_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.standort_id IS 'Foreign Key: ID der Tabelle Anlage';


--
-- Name: COLUMN bohrung.bezeichnung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.bezeichnung IS 'Bezeichnung der Bohrung';


--
-- Name: COLUMN bohrung.bemerkung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.bemerkung IS 'Bemerkungen zur Bohrung';


--
-- Name: COLUMN bohrung.datum; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.datum IS 'Datum des Bohrbeginns';


--
-- Name: COLUMN bohrung.besitzer; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.besitzer IS 'Besitzer der Bohrung';


--
-- Name: COLUMN bohrung.durchmesserbohrloch; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.durchmesserbohrloch IS 'Durchmesser der Bohrlöcher [mm]';


--
-- Name: COLUMN bohrung.bohrart; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.bohrart IS 'Art der Bohrung';


--
-- Name: COLUMN bohrung.bohrzweck; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.bohrzweck IS 'Zweck der Bohrung';


--
-- Name: COLUMN bohrung.ablenkung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.ablenkung IS 'Klassierung der Ablenkung';


--
-- Name: COLUMN bohrung.ablenkungbem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.ablenkungbem IS 'Bemerkung zu Ablenkung';


--
-- Name: COLUMN bohrung.quali; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.quali IS 'Qualität der Angaben zur Bohrung';


--
-- Name: COLUMN bohrung.qualibem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.qualibem IS 'Bemerkung zur Qualitätsangabe';


--
-- Name: COLUMN bohrung.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.new_date IS 'Datum des Imports des Objektes';


--
-- Name: COLUMN bohrung.quelleref; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.quelleref IS 'Autor geol. Aufnahme (Firma, Bearbeiter, Jahr)';


--
-- Name: COLUMN bohrung.hotlinka; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.hotlinka IS 'Pfad zur Ablage der gescannten Bohrungsprofile etc';


--
-- Name: COLUMN bohrung.hotlinkf; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.hotlinkf IS 'Dateiname des gescannten Bohrungsprofile u. Dokumente';


--
-- Name: COLUMN bohrung.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN bohrung.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN bohrung.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN bohrung.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: bohrung_bohrung_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE bohrung_bohrung_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bohrung_bohrung_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE bohrung_bohrung_id_seq OWNED BY bohrung.bohrung_id;


--
-- Name: code; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE code (
    code_id integer NOT NULL,
    codetyp_id integer NOT NULL,
    kurztext character varying NOT NULL,
    text character varying,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying,
    sort smallint
);


--
-- Name: TABLE code; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE code IS 'Verwaltung der Codes';


--
-- Name: COLUMN code.code_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.code_id IS 'Feature ID';


--
-- Name: COLUMN code.codetyp_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.codetyp_id IS 'Referenz auf die Spalte codetypid in der Tabelle codetyp';


--
-- Name: COLUMN code.kurztext; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.kurztext IS 'Kurzbezeichnung des Codes';


--
-- Name: COLUMN code.text; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.text IS 'Ausfuehrliche Bezeichnung des Codes';


--
-- Name: COLUMN code.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.new_date IS 'Timestamp Anlage';


--
-- Name: COLUMN code.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN code.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN code.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN code.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: code_code_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE code_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_code_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE code_code_id_seq OWNED BY code.code_id;


--
-- Name: codeschicht; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE codeschicht (
    codeschicht_id integer NOT NULL,
    kurztext text NOT NULL,
    text text NOT NULL,
    sort smallint,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying
);


--
-- Name: COLUMN codeschicht.codeschicht_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.codeschicht_id IS 'Primärschlüssel';


--
-- Name: COLUMN codeschicht.kurztext; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.kurztext IS 'Kürzel zur Identifizierung der Schicht';


--
-- Name: COLUMN codeschicht.text; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.text IS 'Bezeichnung der Schicht';


--
-- Name: COLUMN codeschicht.sort; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.sort IS 'Vorgabe für Reihenfolge der Schichten bei Erfassung in Tabelle schicht';


--
-- Name: COLUMN codeschicht.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.new_date IS 'Timestamp Anlage';


--
-- Name: COLUMN codeschicht.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN codeschicht.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN codeschicht.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codeschicht.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: codeschicht_codeschicht_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE codeschicht_codeschicht_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: codeschicht_codeschicht_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE codeschicht_codeschicht_id_seq OWNED BY codeschicht.codeschicht_id;


--
-- Name: codetyp; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE codetyp (
    codetyp_id integer NOT NULL,
    kurztext character varying NOT NULL,
    text character varying NOT NULL,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying
);


--
-- Name: TABLE codetyp; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE codetyp IS 'Zentrale Tabelle der Codetypen';


--
-- Name: COLUMN codetyp.codetyp_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.codetyp_id IS 'Feature ID';


--
-- Name: COLUMN codetyp.kurztext; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.kurztext IS 'Kurzbezeichnung des Codetypen';


--
-- Name: COLUMN codetyp.text; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.text IS 'Ausfuehrliche Bezeichnung des Codetypen';


--
-- Name: COLUMN codetyp.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.new_date IS 'Timestamp Anlage';


--
-- Name: COLUMN codetyp.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN codetyp.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN codetyp.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN codetyp.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: codetyp_codetyp_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE codetyp_codetyp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: codetyp_codetyp_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE codetyp_codetyp_id_seq OWNED BY codetyp.codetyp_id;


--
-- Name: schicht; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE schicht (
    schicht_id integer NOT NULL,
    bohrprofil_id integer NOT NULL,
    schichten_id integer NOT NULL,
    tiefe real NOT NULL,
    quali integer NOT NULL,
    qualibem text,
    bemerkung text,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying
);


--
-- Name: TABLE schicht; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE schicht IS 'Erfassung der einzelnen Bohrprofilschichten';


--
-- Name: COLUMN schicht.schicht_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.schicht_id IS 'Feature ID';


--
-- Name: COLUMN schicht.bohrprofil_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.bohrprofil_id IS 'Foreign Key: ID der Tabelle bohrprofil';


--
-- Name: COLUMN schicht.tiefe; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.tiefe IS 'Tiefe der Schichtgrenze [m]';


--
-- Name: COLUMN schicht.quali; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.quali IS 'Qualitätsangabe zur Borhprofilschicht';


--
-- Name: COLUMN schicht.qualibem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.qualibem IS 'Bemerkung zur Qualitätsangabe';


--
-- Name: COLUMN schicht.bemerkung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.bemerkung IS 'Bemerkung zur Schicht';


--
-- Name: COLUMN schicht.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.new_date IS 'Datum des Imports des Objektes';


--
-- Name: COLUMN schicht.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.mut_date IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN schicht.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN schicht.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN schicht.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: schicht_schicht_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE schicht_schicht_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schicht_schicht_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE schicht_schicht_id_seq OWNED BY schicht.schicht_id;


--
-- Name: standort; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE standort (
    standort_id integer NOT NULL,
    bezeichnung text NOT NULL,
    bemerkung text,
    anzbohrloch smallint,
    gembfs integer,
    gbnummer character(40),
    gaso_nr integer,
    quali integer,
    qualibem text,
    wkb_geometry public.geometry NOT NULL,
    wkb_geometry95 public.geometry,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_dims_wkb_geometry95 CHECK ((public.st_ndims(wkb_geometry95) = 2))
);


--
-- Name: TABLE standort; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE standort IS 'Allgemeine Informationen zu einer zusammengehörigen Gruppe von Bohrungen';


--
-- Name: COLUMN standort.standort_id; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.standort_id IS 'Feature ID';


--
-- Name: COLUMN standort.bezeichnung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.bezeichnung IS 'Bezeichnung des Standorts';


--
-- Name: COLUMN standort.bemerkung; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.bemerkung IS 'Bemerkungen zum Standort';


--
-- Name: COLUMN standort.anzbohrloch; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.anzbohrloch IS 'Anzahl Bohrlöcher. TODO: Verzichtbar? Ergibt sich aus Anzahl Bohrprofile?';


--
-- Name: COLUMN standort.gembfs; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.gembfs IS 'Gemeinde-Nr. TODO: FKey auf SO!GIS-Gemeinden';


--
-- Name: COLUMN standort.gbnummer; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.gbnummer IS 'Grundbuch-Nr , ';


--
-- Name: COLUMN standort.gaso_nr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.gaso_nr IS 'Gaso-Nr (mobj_id) falls vorhanden TODO:fkey auf VEGAS';


--
-- Name: COLUMN standort.quali; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.quali IS 'Qualität der Stammdaten';


--
-- Name: COLUMN standort.qualibem; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.qualibem IS 'Bemerkung zur Qualitätsangabe';


--
-- Name: COLUMN standort.wkb_geometry; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.wkb_geometry IS 'OGC WKB Geometrie SRID 21781 LV03';


--
-- Name: COLUMN standort.wkb_geometry95; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.wkb_geometry95 IS 'OGC WKB Geometrie SRID 2056 LV95';


--
-- Name: COLUMN standort.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.new_date IS 'Datum des Imports des Objektes';


--
-- Name: COLUMN standort.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN standort.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN standort.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN standort.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: standort_standort_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE standort_standort_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: standort_standort_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE standort_standort_id_seq OWNED BY standort.standort_id;


--
-- Name: vorkommnis; Type: TABLE; Schema: bohrung; Owner: -
--

CREATE TABLE vorkommnis (
    vorkommnis_id integer NOT NULL,
    bohrprofil_id integer NOT NULL,
    typ integer NOT NULL,
    subtyp integer,
    tiefe real,
    bemerkung text,
    new_date timestamp without time zone DEFAULT now() NOT NULL,
    mut_date timestamp without time zone,
    new_usr character varying DEFAULT "current_user"() NOT NULL,
    mut_usr character varying,
    quali integer,
    qualibem text
);


--
-- Name: TABLE vorkommnis; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TABLE vorkommnis IS 'Vorkommnisse bei der Bohrung: Karteser, Karst, Gas/Öl, Sulfat, technische Komplikationen';


--
-- Name: COLUMN vorkommnis.typ; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.typ IS 'Art des Vorkommnisses, z.B. Arteser';


--
-- Name: COLUMN vorkommnis.subtyp; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.subtyp IS 'Weitere Spezifizierung, z.B. Klassierung betr. artesischem Überlauf';


--
-- Name: COLUMN vorkommnis.tiefe; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.tiefe IS 'Tiefe des Vorkommnisses';


--
-- Name: COLUMN vorkommnis.new_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.new_date IS 'Timestamp Anlage';


--
-- Name: COLUMN vorkommnis.mut_date; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.mut_date IS 'Timestamp letzte Änderung';


--
-- Name: COLUMN vorkommnis.new_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.new_usr IS 'Kürzel des Benutzers bei Anlage';


--
-- Name: COLUMN vorkommnis.mut_usr; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON COLUMN vorkommnis.mut_usr IS 'Kürzel des Benutzers bei letzter Änderung';


--
-- Name: vorkommnis_vorkommnis_id_seq; Type: SEQUENCE; Schema: bohrung; Owner: -
--

CREATE SEQUENCE vorkommnis_vorkommnis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vorkommnis_vorkommnis_id_seq; Type: SEQUENCE OWNED BY; Schema: bohrung; Owner: -
--

ALTER SEQUENCE vorkommnis_vorkommnis_id_seq OWNED BY vorkommnis.vorkommnis_id;


--
-- Name: bohrprofil_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil ALTER COLUMN bohrprofil_id SET DEFAULT nextval('bohrprofil_bohrprofil_id_seq'::regclass);


--
-- Name: bohrung_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung ALTER COLUMN bohrung_id SET DEFAULT nextval('bohrung_bohrung_id_seq'::regclass);


--
-- Name: code_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY code ALTER COLUMN code_id SET DEFAULT nextval('code_code_id_seq'::regclass);


--
-- Name: codeschicht_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY codeschicht ALTER COLUMN codeschicht_id SET DEFAULT nextval('codeschicht_codeschicht_id_seq'::regclass);


--
-- Name: codetyp_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY codetyp ALTER COLUMN codetyp_id SET DEFAULT nextval('codetyp_codetyp_id_seq'::regclass);


--
-- Name: schicht_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY schicht ALTER COLUMN schicht_id SET DEFAULT nextval('schicht_schicht_id_seq'::regclass);


--
-- Name: standort_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY standort ALTER COLUMN standort_id SET DEFAULT nextval('standort_standort_id_seq'::regclass);


--
-- Name: vorkommnis_id; Type: DEFAULT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY vorkommnis ALTER COLUMN vorkommnis_id SET DEFAULT nextval('vorkommnis_vorkommnis_id_seq'::regclass);


--
-- Name: pk_codeschicht_codeschicht_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY codeschicht
    ADD CONSTRAINT pk_codeschicht_codeschicht_id PRIMARY KEY (codeschicht_id);


--
-- Name: pk_vorkommnis_vorkommnis_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY vorkommnis
    ADD CONSTRAINT pk_vorkommnis_vorkommnis_id PRIMARY KEY (vorkommnis_id);


--
-- Name: pkey_bohrprofil_bohrprofil_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT pkey_bohrprofil_bohrprofil_id PRIMARY KEY (bohrprofil_id);


--
-- Name: pkey_bohrung_bohrung_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT pkey_bohrung_bohrung_id PRIMARY KEY (bohrung_id);


--
-- Name: pkey_code_code_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY code
    ADD CONSTRAINT pkey_code_code_id PRIMARY KEY (code_id);


--
-- Name: pkey_codetyp_codetyp_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY codetyp
    ADD CONSTRAINT pkey_codetyp_codetyp_id PRIMARY KEY (codetyp_id);


--
-- Name: pkey_schicht_schicht_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY schicht
    ADD CONSTRAINT pkey_schicht_schicht_id PRIMARY KEY (schicht_id);


--
-- Name: pkey_standort_standort_id; Type: CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY standort
    ADD CONSTRAINT pkey_standort_standort_id PRIMARY KEY (standort_id);


--
-- Name: archive_check_delete; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER archive_check_delete BEFORE DELETE ON bohrprofil FOR EACH ROW EXECUTE PROCEDURE _archive_dummy();


--
-- Name: TRIGGER archive_check_delete ON bohrprofil; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TRIGGER archive_check_delete ON bohrprofil IS 'Notiz: Es zusÃ¤tzlich ein Check Constraint definiert. In Pgadmin nicht sichtbar.';


--
-- Name: archive_check_insert; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER archive_check_insert BEFORE INSERT ON bohrprofil FOR EACH ROW EXECUTE PROCEDURE _archive_date_insert();


--
-- Name: TRIGGER archive_check_insert ON bohrprofil; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TRIGGER archive_check_insert ON bohrprofil IS 'Notiz: Es zusÃ¤tzlich ein Check Constraint definiert. In Pgadmin nicht sichtbar.';


--
-- Name: archive_check_update; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER archive_check_update BEFORE UPDATE ON bohrprofil FOR EACH ROW EXECUTE PROCEDURE _archive_date_update();


--
-- Name: TRIGGER archive_check_update ON bohrprofil; Type: COMMENT; Schema: bohrung; Owner: -
--

COMMENT ON TRIGGER archive_check_update ON bohrprofil IS 'Notiz: Es zusÃ¤tzlich ein Check Constraint definiert. In Pgadmin nicht sichtbar.';


--
-- Name: checkarchive; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE CONSTRAINT TRIGGER checkarchive AFTER INSERT OR DELETE OR UPDATE ON bohrprofil DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE _checkarchive();


--
-- Name: insertcheck; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER insertcheck BEFORE INSERT ON bohrprofil FOR EACH ROW EXECUTE PROCEDURE _insert_bohrprofil();


--
-- Name: insertcheck; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER insertcheck BEFORE INSERT ON vorkommnis FOR EACH ROW EXECUTE PROCEDURE _insert_vorkommnis();


--
-- Name: insertcheck; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER insertcheck BEFORE INSERT ON schicht FOR EACH ROW EXECUTE PROCEDURE _insert_schicht();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON schicht FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON codetyp FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON standort FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON code FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON bohrung FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON bohrprofil FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON vorkommnis FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: mutation; Type: TRIGGER; Schema: bohrung; Owner: -
--

CREATE TRIGGER mutation BEFORE UPDATE ON codeschicht FOR EACH ROW EXECUTE PROCEDURE _mutation();


--
-- Name: Relationship15; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY schicht
    ADD CONSTRAINT "Relationship15" FOREIGN KEY (quali) REFERENCES code(code_id);


--
-- Name: Relationship17; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT "Relationship17" FOREIGN KEY (quali) REFERENCES code(code_id);


--
-- Name: fkey_bohrprofil_bohrung_bohrung_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT fkey_bohrprofil_bohrung_bohrung_id FOREIGN KEY (bohrung_id) REFERENCES bohrung(bohrung_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_bohrprofil_fmeto_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT fkey_bohrprofil_fmeto_code_code_id FOREIGN KEY (fmeto) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrprofil_fmfelso_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT fkey_bohrprofil_fmfelso_code_code_id FOREIGN KEY (fmfelso) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrprofil_tektonik_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrprofil
    ADD CONSTRAINT fkey_bohrprofil_tektonik_code_code_id FOREIGN KEY (tektonik) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrprofilschichten_bohrprofil_bohrprofilid; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY schicht
    ADD CONSTRAINT fkey_bohrprofilschichten_bohrprofil_bohrprofilid FOREIGN KEY (bohrprofil_id) REFERENCES bohrprofil(bohrprofil_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_bohrung_ablenkung_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT fkey_bohrung_ablenkung_code_code_id FOREIGN KEY (ablenkung) REFERENCES code(code_id);


--
-- Name: fkey_bohrung_bohrart_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT fkey_bohrung_bohrart_code_code_id FOREIGN KEY (bohrart) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrung_bohrzweck_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT fkey_bohrung_bohrzweck_code_code_id FOREIGN KEY (bohrzweck) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrung_quali_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT fkey_bohrung_quali_code_code_id FOREIGN KEY (quali) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_bohrung_standort_standort_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY bohrung
    ADD CONSTRAINT fkey_bohrung_standort_standort_id FOREIGN KEY (standort_id) REFERENCES standort(standort_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_code_codetyp_codetypid; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY code
    ADD CONSTRAINT fkey_code_codetyp_codetypid FOREIGN KEY (codetyp_id) REFERENCES codetyp(codetyp_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_schicht_codeschicht_codeschicht_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY schicht
    ADD CONSTRAINT fkey_schicht_codeschicht_codeschicht_id FOREIGN KEY (schichten_id) REFERENCES codeschicht(codeschicht_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_standort_quali_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY standort
    ADD CONSTRAINT fkey_standort_quali_code_code_id FOREIGN KEY (quali) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_vorkommnins_bohrprofil_bohrprofil_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY vorkommnis
    ADD CONSTRAINT fkey_vorkommnins_bohrprofil_bohrprofil_id FOREIGN KEY (bohrprofil_id) REFERENCES bohrprofil(bohrprofil_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fkey_vorkommnis_subtyp_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY vorkommnis
    ADD CONSTRAINT fkey_vorkommnis_subtyp_code_code_id FOREIGN KEY (subtyp) REFERENCES code(code_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fkey_vorkommnis_typ_code_code_id; Type: FK CONSTRAINT; Schema: bohrung; Owner: -
--

ALTER TABLE ONLY vorkommnis
    ADD CONSTRAINT fkey_vorkommnis_typ_code_code_id FOREIGN KEY (typ) REFERENCES code(code_id);


--
-- PostgreSQL database dump complete
--

