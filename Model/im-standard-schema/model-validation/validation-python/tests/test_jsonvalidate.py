import json
import logging
import sys
import unittest
from pathlib import Path
import pytest

import jsonvalidate

parent_dir = Path(__file__).resolve().parent.parent
if str(parent_dir) not in sys.path:  # 3. Add the parent directory to sys.path if it's not already there
    sys.path.insert(0, str(parent_dir))


class MyTestCase(unittest.TestCase):

    @pytest.fixture(autouse=True)
    def inject_fixtures(self, caplog, tmp_path, capsys):
        self.caplog = caplog
        caplog.set_level(logging.WARNING)
        self.capsys = capsys
        logging.basicConfig(level=logging.ERROR, force=True)
        return

    def setUp(self) -> None:
        self.basepath = jsonvalidate.STD_IM_PATH.resolve()
        self.schemapath = jsonvalidate.STD_SCHEMA_PATH.resolve()
        self.IM_schema = jsonvalidate.TOP_SCHEMAS["IM"].resolve()
        self.testfilepath=self.schemapath / "model-validation" / "testmodels"
        return

    def test_jsonvalidate(self):
        """
        test the jsonvalidate.dovalidate function with a direct call
        :return:
        """
        datajsonfile = (self.testfilepath / "simpleIM_test.json").resolve()
        with open(datajsonfile) as infile:
            data=json.load(infile)
        with open(self.IM_schema) as infile:
            schema=json.load(infile)

        errors, draft_label = jsonvalidate.dovalidate(data=data,
                                                      schema=schema,
                                                      # draft=,
                                                      # quiet=True
                                                      # schema_dir=jsonvalidate
                                                      )
        self.assertTrue(draft_label in schema.get("$schema"))
        self.assertTrue(len(errors) == 0)

        # validate entity with im-schema
        datajsonfile = (self.testfilepath / "simpleentity_test.json").resolve()
        if not datajsonfile.is_file():
            self.skipTest(f"testfile not found '{self.testfilepath / 'simpleIM_test.json'}'")
        with open(datajsonfile) as infile:
            data=json.load(infile)
        errors, draft_label = jsonvalidate.dovalidate \
                (data=data,
                schema=schema,
                draft="7",
                quiet=True,
                schema_dir=self.IM_schema
            )
        self.assertEqual("7",draft_label)
        self.assertTrue(len(errors) == 2)

        # validate entity with entity
        datajsonfile = (self.testfilepath / "simpleentity_test.json").resolve()
        if not datajsonfile.is_file():
            self.skipTest(f"testfile not found '{self.testfilepath / 'simpleIM_test.json'}'")
        with open(datajsonfile) as infile:
            data=json.load(infile)
        with open(self.schemapath / "InformationModel" / "Entity-schema.json") as infile:
            schema=json.load(infile)

        errors, draft_label = jsonvalidate.dovalidate(data=data,
            schema=schema,
            # draft=,
            quiet=False,
            schema_dir=self.schemapath
        )
        self.assertTrue(len(errors) == 0)
        return

    def test_directmain(self):
        with pytest.raises(SystemExit) as exc_info:
            jsonvalidate.main([str((self.testfilepath / 'simpleentity_test.json').resolve()),  # json file
                               str(self.schemapath / "InformationModel" / "Entity-schema.json")  # schema file
                               ])

        # Assert that the exit code was specifically 0 (success)
        assert exc_info.value.code == 0

        return

    def test_viasubprocessok(self):
        """
        test the call of the pythom module (main) as a subprocess
        :return:
        """
        import subprocess
        command = [
            sys.executable,
            str(self.testfilepath.parent / "validation-python"/"jsonvalidate.py"),
            str((self.testfilepath / 'simpleentity_test.json').resolve()), #json file
            str((self.schemapath / "InformationModel" / "Entity-schema.json")), #schema file
            "--verbose",
        ]

        result = subprocess.run(
            command,
            cwd=str(self.testfilepath.parent.parent),
            capture_output=True,
            text=True
        )
        print (result.stdout)
        print (result.stderr)

        self.assertTrue( result.returncode == 0)
        return

    def test_viasubprocessnok(self):
        """
        test the call of the pythom module with illegal schema
        :return:
        """
        import subprocess

        command = [
            sys.executable,
            str(self.testfilepath.parent / "validation-python"/"jsonvalidate.py"),
            str((self.testfilepath /"simpleentity_test.json").resolve()), #json file
            str((self.schemapath / "InformationModel" / "InformationModel-schema.json")), #schema file
            "--verbose",
        ]
        result = subprocess.run(
            command,
            cwd=str(self.schemapath),
            capture_output=True,
            text=True
        )
        print (result.stdout)
        print (result.stderr)
        self.assertTrue( result.returncode ==1)
        self.assertTrue("INVALID — 3 error(s) found" in result.stdout)

        return

if __name__ == '__main__':
    unittest.main()
