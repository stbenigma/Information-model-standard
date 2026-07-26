-- This file contains select statements to check the consistenty of the database 
-- This checks are all on top of the standard SQL-checks and constraints.
-- 

-- translated unique-columns must be unique in their translation as well
-- cannot be checked by constraints, as translated values are generic
-- and if an entry in a language is missing, it is replaced by its 'brother' -value from
-- the main language
-- OK= select does not return a row
-- TODO handle multicolumn multilang uk
--       like enca_name, enca_enca_id
select lang_id,
       lang_iso_code2 lang,
       lgtx_attrname  attrname,
       defaultvalue,
       count(*)
from translatedvalues
where lgtx_attrname in
      ('enti_name', 'enti_prefix', 'enti_short_name',
       'buru_name',
       'lang_iso_code2', 'lang_iso_code3', 'lang_iso_name',
       'doma_name',
       'modl_name'
          )
group by lang_id, lang_iso_code2, lgtx_attrname, defaultvalue
having count(*) > 1
        