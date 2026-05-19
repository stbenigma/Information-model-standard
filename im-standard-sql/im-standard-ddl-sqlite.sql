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
    lang_iso_code2    TEXT    NOT NULL,
    lang_iso_code3    TEXT,
    lang_iso_name     TEXT,
    lang_lang_id      INTEGER,
    constraint UK_lang_iso2 unique (lang_iso_code2),
    constraint UK_lang_iso3 unique (lang_iso_code3),
    constraint UK_lang_name unique (lang_iso_name),
    CONSTRAINT CHK_bool CHECK (lang_is_base_lang in ('TRUE', 'FALSE')),
    FOREIGN KEY (lang_lang_id) REFERENCES languages (lang_id) ON DELETE SET NULL
);


CREATE TABLE modelelements
(
    mode_id   INTEGER primary key autoincrement, -- [K4]
    mode_type TEXT NOT NULL,
    mode_dc   TEXT NOT NULL,                     -- [K5] DATETIME → TEXT (ISO-8601)
    mode_dm   TEXT,                              -- [K5]
    mode_uc   TEXT NOT NULL,                     -- [K6]
    mode_um   TEXT,
    CONSTRAINT CHK_mode_type CHECK (mode_type in ('ENTI', 'ECAT', 'ATTR', 'RELA','DOMA'))

);

CREATE TABLE lang_texts
(
    lgtx_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    lgtx_attrname TEXT    NOT NULL,
    lgtx_lang_id  INTEGER NOT NULL,
    lgtx_mode_id  INTEGER NOT NULL,
    lgtx_text     TEXT    NOT NULL,
    constraint UK_lgtx unique (lgtx_attrname, lgtx_mode_id, lgtx_lang_id),
    FOREIGN KEY (lgtx_lang_id) REFERENCES languages (lang_id) ON DELETE CASCADE,
    FOREIGN KEY (lgtx_mode_id) REFERENCES modelelements (mode_id) ON DELETE CASCADE
);


CREATE TABLE user_defined_props
(
    udpv_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    udpv_name TEXT    NOT NULL,
    udpv_mode_id  INTEGER NOT NULL,
    udpv_value     TEXT    NOT NULL,
    constraint UK_udpv unique (udpv_mode_id, udpv_name),
    FOREIGN KEY (udpv_mode_id) REFERENCES modelelements (mode_id) ON DELETE CASCADE
);
-- -----------------------------------------------------------
CREATE TABLE entity_categories
(
    enca_id      INTEGER PRIMARY KEY, -- [K4]
    enca_name    TEXT    NOT NULL,
    enca_descr   TEXT    NULL,
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
    enti_id         INTEGER PRIMARY KEY,                             -- [K4]
    enti_name       TEXT    NOT NULL,
    enti_descr      TEXT,
    enti_enca_id    INTEGER,                                      -- [K4]
    enti_prefix     TEXT,
    enti_short_name TEXT,
    enti_tooltip    TEXT,
    enti_superenti_id    INTEGER,

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


CREATE TABLE domains (
    doma_id INTEGER PRIMARY KEY ,
    doma_bin_contenttype TEXT,
    doma_bin_storageformat TEXT,
    doma_dat_granularity TEXT,
    doma_dat_maxvalue TEXT,
    doma_dat_minvalue TEXT,
    doma_datm_id INTEGER,                     -- Konvertiert von SMALLINT zu INTEGER
    doma_daty_id INTEGER,                     -- Konvertiert von SMALLINT zu INTEGER
    doma_descr TEXT,
    doma_name TEXT NOT NULL,
    doma_num_fract_digits NUMERIC,            -- DECIMAL(3,0) zu NUMERIC konvertiert
    doma_num_maxvalue NUMERIC,                -- DECIMAL(30,10) zu NUMERIC konvertiert
    doma_num_minvalue NUMERIC,                -- DECIMAL(30,10) zu NUMERIC konvertiert
    doma_num_physunit TEXT,
    doma_num_round_value NUMERIC,             -- DECIMAL(7,3) zu NUMERIC konvertiert
    doma_num_total_digits NUMERIC,            -- DECIMAL(3,0) zu NUMERIC konvertiert
    doma_txt_maxlng NUMERIC,                  -- DECIMAL(28,0) zu NUMERIC konvertiert
    doma_txt_minlng NUMERIC,                  -- DECIMAL(28,0) zu NUMERIC konvertiert
    doma_txt_syntaxrule TEXT,
    doma_type TEXT NOT NULL,
    CONSTRAINT Check_doma_bin_contenttype
        CHECK (doma_bin_contenttype IN ('DRAWING', 'FILM', 'IMAGE', 'OTHER', 'SOUND', 'TEXT')),

    CONSTRAINT Check_doma_dat_granularity
        CHECK (doma_dat_granularity IN ('DAY', 'HOUR', 'MILlISECOND', 'MINUTE', 'MONTH', 'QUARTER', 'SECOND', 'SEMESTER', 'WEEK', 'YEAR')),

    CONSTRAINT Check_doma_type
        CHECK (doma_type IN ('BIN', 'BOO', 'DAT', 'GRP', 'LOV', 'NUM', 'TXT'))
);

-- Tabelle: attributes
CREATE TABLE attributes (
    attr_id INTEGER PRIMARY KEY,
    attr_descr TEXT,
    attr_displ_name TEXT,
    attr_displ_seq INTEGER,
    attr_doma_group_id INTEGER,
    attr_doma_id INTEGER,
    attr_enti_id INTEGER,
    attr_is_descriptive TEXT NOT NULL CHECK (attr_is_descriptive IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_encrypted TEXT NOT NULL CHECK (attr_is_encrypted IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_historicised TEXT NOT NULL CHECK (attr_is_historicised IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_mandatory TEXT NOT NULL CHECK (attr_is_mandatory IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_repeated TEXT NOT NULL CHECK (attr_is_repeated IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_is_translated TEXT NOT NULL CHECK (attr_is_translated IN ('TRUE', 'FALSE')) DEFAULT 'FALSE',
    attr_tech_name TEXT NOT NULL,
    attr_tooltip TEXT,
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
    expl_id      INTEGER primary key autoincrement,      -- [K4]
    expl_value   TEXT NOT NULL,
    expl_enti_id INTEGER,                                -- [K4]
    expl_rela_id INTEGER,                                -- [K4]
    expl_attr_id INTEGER,                                -- [K4]
    expl_doma_id INTEGER,                                -- [K4]

    CONSTRAINT FK_expl_enti_fk FOREIGN KEY (expl_enti_id)
        REFERENCES entities (enti_id) ON DELETE CASCADE, -- [K8]
    constraint UK_expl unique (expl_value, expl_enti_id, expl_rela_id, expl_attr_id),
    CONSTRAINT CHK_expl_fkarc CHECK ((expl_enti_id is not null
        and expl_attr_id is null
        and expl_rela_id is null
        and expl_doma_id is null)
        OR
                                     (expl_enti_id is null
                                         and expl_attr_id is not null
                                         and expl_rela_id is null
        and expl_doma_id is null)
        OR
                                     (expl_enti_id is null
                                         and expl_attr_id is null
                                         and expl_rela_id is not null
        and expl_doma_id is null)
        OR
                                     (expl_enti_id is null
                                         and expl_attr_id is null
                                         and expl_rela_id is null
        and expl_doma_id is not null)
        )
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



PRAGMA foreign_keys = ON;


