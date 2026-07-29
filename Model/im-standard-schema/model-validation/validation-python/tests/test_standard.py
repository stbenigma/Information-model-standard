import json
import os
import sys
import unittest
import logging
from pathlib import Path
import pytest


parent_dir = Path(__file__).resolve().parent.parent
if str(parent_dir) not in sys.path: # 3. Add the parent directory to sys.path if it's not already there
    sys.path.insert(0, str(parent_dir))

try:
    import jsonvalidate
except Exception as e:
    raise e


class MyTestCase(unittest.TestCase):
    @pytest.fixture(autouse=True)
    def inject_fixtures(self, caplog, tmp_path, capsys):
        self.caplog = caplog
        caplog.set_level(logging.WARNING)
        self.capsys = capsys
        logging.basicConfig(level=logging.ERROR, force=True)
        return

    def setUp(self) -> None:

        self.basepath =  jsonvalidate.STD_IM_PATH
        self.schemapath= jsonvalidate.STD_SCHEMA_PATH
        self.examplepath =  self.basepath / "Example models"
        self.imdeffilename="InformationModel-schema.json"
        self.imdeffilepath=self.schemapath/ "InformationModel"/ self.imdeffilename

        self.testmodelpath = self.basepath / "Model" / "im-standard-schema" / "model-validation"/ "testmodels"

        return

    def _schemareferences(self,schemapath):
        retval = {}
        with os.scandir(schemapath) as schemata:
            for schema in schemata:
                if schema.name.endswith("-schema.json"):
                    with open(schema) as infile:
                        injson=json.load(infile)
                    retval[schema.name]=injson
        return retval

    def list_tree(self,path, dotest,level=0):
        for item in sorted(Path(path).iterdir()):
            #print(' ' * level * 4 + item.name)
            if item.is_dir():
                self.list_tree(item, dotest, level + 1)
            elif item.is_file() and level >0 and item.suffix==".json":
               dotest(file=item,reffile=self.schemapath / item.parts[-4] / (item.parts[-3] + "-schema" + item.suffix))
        return

    def test_testmodels(self):
        """ print my testmodels defined in the standard """

        def testonefile(file,reffile):
            with open(file) as infile:
                try:
                    jsonobj=json.load(infile)
                except Exception as ex:
                    logging.error(f"File {str(file)}")
                    logging.error(ex)
                    return
            myfilepath=self.schemapath / file.parts[-4] / (file.parts[-3] +"-schema" + file.suffix)
            if not myfilepath.is_file():
                myfilepath = self.schemapath / (file.parts[-3] + "-schema" + file.suffix)
            with open(myfilepath) as schemafile:
                validateschemajson=json.load(schemafile)

            errors, _ = jsonvalidate.dovalidate(data=jsonobj,
                                                          schema=validateschemajson,
                                                          # draft=,
                                                          quiet=False,
                                                          schema_dir=self.schemapath
                                                          )

            valid = file.parts[-2] == "valid"

            #TODO domain properties of subdomaintypes are not checked properly see invalid jsonx files
            if len(errors)==0 and valid:
                pass
            elif len(errors)==0 and not valid:
                logging.error (f"******* invalid passed {file.parts[-5:]}")
            elif len(errors) > 0 and not valid:
                pass
            else:
                logging.error (f"******* valid throws error {'/'.join(file.parts[-5:])}")
                for i,err in enumerate(errors):
                    logging.error  (jsonvalidate.format_error(err=err,index=i))
            return

        self.list_tree(path=self.testmodelpath,
                       dotest=testonefile)
        print("\n".join(self.caplog.messages))
        self.assertEqual(0,len(self.caplog.messages))

        return

    def test_examples(self):

        def _test1expl(testfilepath):
            if not testfilepath.is_file():
                logging.warning(f"Examplefile not found: {testfilepath}")
                return
            with open(testfilepath) as infile:
                jsonobj = json.load(infile)

            with open(self.imdeffilepath) as schemafile:
                validateschemajson = json.load(schemafile)

            errors, _ = jsonvalidate.dovalidate(data=jsonobj,
                                                          schema=validateschemajson,
                                                          quiet=False,
                                                          schema_dir=self.schemapath
                                                          )
            for i, err in enumerate(errors):
                logging.error(jsonvalidate.format_error(err=err, index=i))
            print(f"tested {str(testfilepath)}")

            return

        logging.getLogger().setLevel(logging.WARNING)
        _test1expl(testfilepath=self.examplepath / "Astronomie" / "astronomie-information-model.json")
        print()
        print ("\n".join(self.caplog.messages))
        self.assertEqual(0,len([cl for cl in self.caplog.records if cl.levelname=="ERROR"]))

        _test1expl(testfilepath=self.examplepath / "MinimalModels" / "absolute_minimal_IM.json")
        print()
        print ("\n".join(self.caplog.messages))
        self.assertEqual(0,len([cl for cl in self.caplog.records if cl.levelname=="ERROR"]))

        _test1expl(testfilepath=self.examplepath / "MinimalModels" / "minimalistic_IM.json")
        print()
        print ("\n".join(self.caplog.messages))
        self.assertEqual(0,len([cl for cl in self.caplog.records if cl.levelname=="ERROR"]))
        return


if __name__ == '__main__':
    unittest.main()
