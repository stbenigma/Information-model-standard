-- ============================================================
-- SQLite Konvertierung von MySQL_Datenmodell_(1).sql
-- Konvertierungsregeln:
--   [K1] Schema-Prefix `DDL Import`. entfällt (SQLite kennt keine Schemas)
--   [K2] Backtick-Bezeichner → normale Bezeichner
--   [K3] ALTER TABLE ADD COLUMN → direkt in CREATE TABLE integriert
--   [K4] SMALLINT → INTEGER (SQLite kennt nur INTEGER)
--   [K5] DATETIME → TEXT (SQLite hat keinen nativen DATETIME-Typ;
--        Konvention: ISO-8601-String 'YYYY-MM-DD HH:MM:SS')
--   [K6] TEXT bleibt TEXT
--   [K7] PRIMARY KEY per CONSTRAINT → inline oder am Tabellenende
--   [K8] FOREIGN KEY via ALTER TABLE → als inline REFERENCES im CREATE TABLE
--   [K9] ON DELETE CASCADE bleibt; PRAGMA foreign_keys = ON; wird vorangestellt
-- ============================================================

PRAGMA foreign_keys = OFF;
-- [K9] FKs in SQLite müssen explizit aktiviert werden

-- -----------------------------------------------------------
CREATE TABLE languages
(
    lang_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    lang_is_base_lang TEXT NOT NULL DEFAULT 'FALSE',
    lang_iso_code2    TEXT NOT NULL,
    lang_iso_code3    TEXT,
    lang_iso_name     TEXT,
    lang_lang_id      INTEGER,
    constraint UK_lang_iso2 unique (lang_iso_code2),
    constraint UK_lang_iso3 unique (lang_iso_code3),
    constraint UK_lang_name unique (lang_iso_name),
    CONSTRAINT CHK_bool CHECK (lang_is_base_lang in ('TRUE', 'FALSE')),
    FOREIGN KEY (lang_lang_id) REFERENCES languages (lang_id) ON DELETE SET NULL
);

BEGIN TRANSACTION;
-- recursive FK need transaction
CREATE TABLE modelelements
(
    mode_id      INTEGER primary key autoincrement, -- [K4]
    mode_type    TEXT NOT NULL,
    mode_modl_id INTEGER,
    mode_dc      TEXT NOT NULL,                     -- [K5] DATETIME → TEXT (ISO-8601)
    mode_dm      TEXT,                              -- [K5]
    mode_uc      TEXT NOT NULL,                     -- [K6]
    mode_um      TEXT,
    constraint chk_modl_notnull check (not (mode_modl_id is null and (mode_type in ('ENTI', 'DOMA', 'BURU', 'ECAT')))),
    constraint chk_model_recursive check (mode_modl_id is null or mode_type != 'MODL'),
    CONSTRAINT Check_mode_type CHECK (mode_type IN ('ATTR', 'BURU', 'DOMA', 'ECAT', 'ENTI', 'MODL', 'RELA')),
    CONSTRAINT fk_mode_modl FOREIGN KEY (mode_modl_id)
        REFERENCES models (modl_id) ON DELETE RESTRICT
);

CREATE TABLE models
(
    modl_id                INTEGER PRIMARY KEY,
    modl_descr             TEXT,
    modl_name              TEXT NOT NULL,
    modl_targetenvironment TEXT,
    modl_type              TEXT NOT NULL,
    constraint uk_models unique (modl_name),
    CONSTRAINT Check_modl_type CHECK (modl_type IN ('AM', 'DM', 'IM')),
    CONSTRAINT FK_fk_mode_modls FOREIGN KEY (modl_id)
        REFERENCES modelelements (mode_id) ON DELETE RESTRICT
);
COMMIT;

CREATE TABLE lang_texts
(
    lgtx_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    lgtx_attrname TEXT    NOT NULL,
    lgtx_lang_id  INTEGER NOT NULL,
    lgtx_mode_id  INTEGER NOT NULL,
    lgtx_text     TEXT    NOT NULL,
    constraint UK_lgtx unique (lgtx_text, lgtx_attrname, lgtx_mode_id, lgtx_lang_id),
    FOREIGN KEY (lgtx_lang_id) REFERENCES languages (lang_id) ON DELETE CASCADE,
    FOREIGN KEY (lgtx_mode_id) REFERENCES modelelements (mode_id) ON DELETE CASCADE
);


CREATE TABLE model_languages
(
    mola_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    mola_lang_id      INTEGER NOT NULL,
    mola_modl_id      INTEGER NOT NULL,
    mola_mainlanguage TEXT    NOT NULL default 'FALSE',
    CONSTRAINT UQ_model_languages UNIQUE (mola_lang_id, mola_modl_id),
    CONSTRAINT Check_mola_boolean CHECK (mola_mainlanguage IN ('TRUE', 'FALSE')),
    CONSTRAINT FK_fk_mola_lang FOREIGN KEY (mola_lang_id)
        REFERENCES languages (lang_id) ON DELETE CASCADE,
    CONSTRAINT FK_fk_mola_modl FOREIGN KEY (mola_modl_id)
        REFERENCES models (modl_id) ON DELETE CASCADE
);

CREATE TABLE user_defined_props
(
    udpv_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    udpv_name    TEXT    NOT NULL,
    udpv_mode_id INTEGER NOT NULL,
    udpv_value   TEXT    NOT NULL,
    constraint UK_udpv unique (udpv_mode_id, udpv_name),
    FOREIGN KEY (udpv_mode_id) REFERENCES modelelements (mode_id) ON DELETE CASCADE
);
-- -----------------------------------------------------------
CREATE TABLE entity_categories
(
    enca_id      INTEGER PRIMARY KEY, -- [K4]
    enca_name    TEXT NOT NULL,
    enca_descr   TEXT NULL,
    enca_enca_id INTEGER,
    constraint UK_enca_name unique (enca_name, enca_enca_id),
    CONSTRAINT FK_enca_enca FOREIGN KEY (enca_enca_id)
        REFERENCES entity_categories (enca_id) ON DELETE RESTRICT,
    CONSTRAINT FK_enca_mode_fk FOREIGN KEY (enca_id)
        REFERENCES modelelements (mode_id) ON DELETE CASCADE

);

-- -----------------------------------------------------------
CREATE TABLE entities
(
    enti_id           INTEGER PRIMARY KEY,                        -- [K4]
    enti_name         TEXT NOT NULL,
    enti_descr        TEXT,
    enti_enca_id      INTEGER,                                    -- [K4]
    enti_prefix       TEXT,
    enti_short_name   TEXT,
    enti_tooltip      TEXT,
    enti_superenti_id INTEGER,

    constraint UK_enti_name unique (enti_name),
    constraint UK_enti_shortname unique (enti_short_name),
    constraint UK_enti_prefix unique (enti_prefix),
    CONSTRAINT FK_enti_enti FOREIGN KEY (enti_superenti_id)
        REFERENCES entities (enti_id) ON DELETE RESTRICT,
    CONSTRAINT FK_enti_mode_fk FOREIGN KEY (enti_id)
        REFERENCES modelelements (mode_id) ON DELETE CASCADE,     -- [K8]
    CONSTRAINT FK_enti_enca_fk FOREIGN KEY (enti_enca_id)
        REFERENCES entity_categories (enca_id) ON DELETE RESTRICT -- [K8]
);


CREATE TABLE domains
(
    doma_id                INTEGER PRIMARY KEY,
    doma_bin_contenttype   TEXT,
    doma_bin_storageformat TEXT,
    doma_dat_granularity   TEXT,
    doma_dat_maxvalue      TEXT,
    doma_dat_minvalue      TEXT,
    doma_datm_id           INTEGER, -- Konvertiert von SMALLINT zu INTEGER
    doma_daty_id           INTEGER, -- Konvertiert von SMALLINT zu INTEGER
    doma_descr             TEXT,
    doma_name              TEXT NOT NULL,
    doma_num_fract_digits  NUMERIC, -- DECIMAL(3,0) zu NUMERIC konvertiert
    doma_num_maxvalue      NUMERIC, -- DECIMAL(30,10) zu NUMERIC konvertiert
    doma_num_minvalue      NUMERIC, -- DECIMAL(30,10) zu NUMERIC konvertiert
    doma_num_physunit      TEXT,
    doma_num_round_value   NUMERIC, -- DECIMAL(7,3) zu NUMERIC konvertiert
    doma_num_total_digits  NUMERIC, -- DECIMAL(3,0) zu NUMERIC konvertiert
    doma_txt_maxlng        NUMERIC, -- DECIMAL(28,0) zu NUMERIC konvertiert
    doma_txt_minlng        NUMERIC, -- DECIMAL(28,0) zu NUMERIC konvertiert
    doma_txt_syntaxrule    TEXT,
    doma_type              TEXT NOT NULL,
    CONSTRAINT Check_doma_bin_contenttype
        CHECK (doma_bin_contenttype IN ('DRAWING', 'FILM', 'IMAGE', 'OTHER', 'SOUND', 'TEXT')),

    CONSTRAINT Check_doma_dat_granularity
        CHECK (doma_dat_granularity IN
               ('DAY', 'HOUR', 'MILlISECOND', 'MINUTE', 'MONTH', 'QUARTER', 'SECOND', 'SEMESTER', 'WEEK', 'YEAR')),

    CONSTRAINT Check_doma_type
        CHECK (doma_type IN ('BIN', 'BOO', 'DAT', 'GRP', 'LOV', 'NUM', 'TXT'))
);

CREATE TABLE lov_values
(
    lovv_id         INTEGER primary key autoincrement,
    lovv_value      TEXT NOT NULL,
    lovv_displ      TEXT,
    lovv_descr      TEXT,
    lovv_sort_order INTEGER,
    lovv_doma_id    INTEGER,

    CONSTRAINT FK_lovv_doma_fk FOREIGN KEY (lovv_doma_id)
        REFERENCES domains (doma_id) ON DELETE CASCADE,
    constraint UK_lovv_value unique (lovv_doma_id, lovv_value),
    constraint UK_lovv_displ unique (lovv_doma_id, lovv_displ),
    constraint UK_lovv_sort unique (lovv_doma_id, lovv_sort_order)
);

-- Tabelle: attributes
CREATE TABLE attributes
(
    attr_id              INTEGER PRIMARY KEY,
    attr_descr           TEXT,
    attr_displ_name      TEXT,
    attr_displ_seq       INTEGER,
    attr_doma_id         INTEGER,
    attr_enti_id         INTEGER,
    attr_doma_group_id   INTEGER,
    attr_is_descriptive  TEXT CHECK (attr_is_descriptive IN ('TRUE', 'FALSE')),
    attr_is_encrypted    TEXT CHECK (attr_is_encrypted IN ('TRUE', 'FALSE')),
    attr_is_historicised TEXT CHECK (attr_is_historicised IN ('TRUE', 'FALSE')),
    attr_is_mandatory    TEXT NOT NULL CHECK (attr_is_mandatory IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_repeated     TEXT CHECK (attr_is_repeated IN ('TRUE', 'FALSE')),
    attr_is_translated   TEXT CHECK (attr_is_translated IN ('TRUE', 'FALSE')),
    attr_tech_name       TEXT NOT NULL,
    attr_tooltip         TEXT,
    CONSTRAINT CHK_fkexcl CHECK ((attr_enti_id is not null and attr_doma_group_id is null)
        or
                                 (attr_enti_id is null and attr_doma_group_id is not null)
        ),
    FOREIGN KEY (attr_enti_id) REFERENCES entities (enti_id),
    FOREIGN KEY (attr_id) REFERENCES modelelements (mode_id) ON DELETE CASCADE,
    FOREIGN KEY (attr_doma_id) REFERENCES domains (doma_id) ON DELETE RESTRICT,
    FOREIGN KEY (attr_doma_group_id) REFERENCES domains (doma_id) ON DELETE RESTRICT
);

-- -----------------------------------------------------------
CREATE TABLE examples
(
    expl_id      INTEGER primary key autoincrement, -- [K4]
    expl_value   TEXT    NOT NULL,
    expl_mode_id INTEGER NOT NULL,

    CONSTRAINT FK_expl_enti_fk FOREIGN KEY (expl_mode_id)
        REFERENCES modelelements (mode_id) ON DELETE CASCADE,
    constraint UK_expl unique (expl_value, expl_mode_id)
);

CREATE TABLE synonyms
(
    syno_id      INTEGER primary key autoincrement,      -- [K4]
    syno_name    TEXT NOT NULL,
    syno_enti_id INTEGER,                                -- [K4]

    CONSTRAINT FK_syno_enti_fk FOREIGN KEY (syno_enti_id)
        REFERENCES entities (enti_id) ON DELETE CASCADE, -- [K8]
    constraint UK_syno unique (syno_name, syno_enti_id)
);

CREATE TABLE keys
(
    keys_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    keys_name    TEXT    NOT NULL,
    keys_enti_id INTEGER NOT NULL,
    keys_attr_id INTEGER,
    keys_rela_id INTEGER,
    constraint UK_keys unique (keys_enti_id, keys_name, keys_attr_id, keys_rela_id),
    constraint chk_arc check ((keys_attr_id is null and keys_rela_id is not null)
        or (keys_attr_id is not null and keys_rela_id is null)
        ),
    --FOREIGN KEY (keys_rela_id) REFERENCES relations (rela_id) ON DELETE CASCADE,
    FOREIGN KEY (keys_attr_id) REFERENCES attributes (attr_id) ON DELETE CASCADE
);

-- Tabelle: business_rules
CREATE TABLE business_rules
(
    buru_id       INTEGER PRIMARY KEY,
    buru_descr    TEXT,
    buru_errormsg TEXT,
    buru_level    TEXT NOT NULL CHECK (buru_level IN ('ATTR', 'DB', 'ENTI', 'TUPL')),
    buru_name     TEXT NOT NULL,
    buru_rule     TEXT NOT NULL,
    buru_type     TEXT NOT NULL CHECK (buru_type IN ('CALC', 'CHECK', 'TRIGGER')),
    constraint UK_buru unique (buru_name),
    FOREIGN KEY (buru_id) REFERENCES modelelements (mode_id)

);

CREATE TABLE relations
(
    rela_id                INTEGER PRIMARY KEY AUTOINCREMENT,
    rela_name              TEXT    NOT NULL,
    rela_type              TEXT    NOT NULL CHECK (rela_type IN ('1:1', 'M:1', 'M:N', 'ROLE', 'SUBTYPE')),
    rela_arc_no_from       INTEGER,
    rela_arc_no_to         INTEGER,
    rela_assoc_from_to     TEXT,
    rela_assoc_to_from     TEXT,
    rela_enti_id_from      INTEGER NOT NULL,
    rela_enti_id_to        INTEGER NOT NULL,
    rela_hist_from_to      TEXT CHECK (rela_hist_from_to IN ('TRUE', 'FALSE')),
    rela_hist_to_from      TEXT CHECK (rela_hist_to_from IN ('TRUE', 'FALSE')),
    rela_mandatory_from_to TEXT    NOT NULL CHECK (rela_mandatory_from_to IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    rela_mandatory_to_from TEXT    NOT NULL CHECK (rela_mandatory_to_from IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    rela_maptype_from_to   TEXT    NOT NULL CHECK (rela_maptype_from_to IN ('1', 'M')),
    rela_maptype_to_from   TEXT    NOT NULL CHECK (rela_maptype_to_from IN ('1', 'M')),
    constraint UK_relaname unique (rela_name),
    constraint UK_rela unique (rela_enti_id_from, rela_enti_id_to, rela_assoc_from_to, rela_assoc_to_from),
    constraint chk_type11 check (rela_type != '1:1' or (rela_maptype_to_from = '1' and rela_maptype_from_to = '1')),
    constraint chk_typem1 check (rela_type != 'M:1' or rela_maptype_to_from != rela_maptype_from_to),
    constraint chk_typemn check (rela_type != 'M:N' or (rela_maptype_to_from = 'M' and rela_maptype_from_to = 'M')),
    constraint chk_typerole check (rela_type != 'ROLE' or
                                   (rela_maptype_to_from = '1' and rela_maptype_from_to = '1' and
                                    (rela_mandatory_from_to = 'FALSE' or rela_mandatory_to_from = 'FALSE'))
        ),
    constraint chk_typesubtype check (rela_type != 'SUBTYPE' or
                                      (rela_maptype_to_from = '1' and rela_maptype_from_to = '1' and
                                       rela_mandatory_from_to = 'TRUE' and rela_mandatory_to_from = 'TRUE' and
                                       (rela_arc_no_from is not null or rela_arc_no_to is not null)
                                          )
        ),
    FOREIGN KEY (rela_enti_id_from) REFERENCES entities (enti_id),
    FOREIGN KEY (rela_enti_id_to) REFERENCES entities (enti_id),
    FOREIGN KEY (rela_id) REFERENCES modelelements (mode_id)
);

-- Tabelle: businessrule_elements
CREATE TABLE businessrule_elements
(
    bure_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    bure_buru_id   INTEGER NOT NULL,
    bure_mode_id   INTEGER NOT NULL,
    bure_writeable TEXT    NOT NULL CHECK (bure_writeable IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    constraint UK_bure unique (bure_mode_id, bure_buru_id),
    FOREIGN KEY (bure_buru_id) REFERENCES business_rules (buru_id) ON DELETE CASCADE
);

PRAGMA foreign_keys = ON;

-------- VIEWS are maintained manually ----------------
--- in dataspot as VIEW ... tables
------------------------------------------------------
-- create values for every language (use default-language if missing)
create view translatedvalues as
select lang_id
     , lang_iso_code2
     , entries.lgtx_attrname
     , entries.lgtx_mode_id
     , lg2.lgtx_text as realvalue    -- real value found in model
     , case
           when lg2.lgtx_text is null
               then lg3.lgtx_text
           else lg2.lgtx_text
        end    as defaultvalue -- real or defaultvalue
from languages
         cross join (select distinct lgtx_attrname, lgtx_mode_id
                     from lang_texts
) entries
         left outer join lang_texts lg2 on lg2.lgtx_lang_id = lang_id
            and lg2.lgtx_attrname = entries.lgtx_attrname
            and lg2.lgtx_mode_id = entries.lgtx_mode_id
         left outer join lang_texts lg3 on lg3.lgtx_lang_id = lang_lang_id
            and lg3.lgtx_attrname = entries.lgtx_attrname
            and lg3.lgtx_mode_id = entries.lgtx_mode_id
;