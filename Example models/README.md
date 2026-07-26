# im-standard-python    

Python code to verify the definition of the standard.

It provides a function to validate a json-schema against the IM-standard json-schema.
It provides a test function to validate the testmodels (seel Model/im-standard-json/testmodels) against the im-standard-schema

## tests/...
pytest files test_standard.py and test_jsonvalidate.py
to validate the json-models in this directories.
Especially all valid and invalid testmodels (in Model/im-standard-json/testmodels) are checked wether the throw an error or not

## jsonvalidate.py
pyhton file callable from operating system

Validate a JSON file against a JSON Schema file. 

Usage:<br> 
python validate_json.py <json_file> <schema_file> [options] 

Options: 
- -v, --verbose Show all validation errors (default: stop at first) 
- -q, --quiet Exit code only, no output 
- -d, --draft {4,6,7,2019,2020}<br>
           Force a specific JSON Schema draft validator. <br>
          Auto-detected from $schema if omitted. <br>
         default 2020 
- -h, --help Show this help message

positional arguments:
-  json_file             Path to the JSON data file
-  schema_file           Path to the JSON Schema file.<br> 
                       Abbreviation for json-schema-files: <br>
--                           IM for InformationModel,<br> 
--                           DM for DataModel, <br>
--                           MM for MetaModel<br>
