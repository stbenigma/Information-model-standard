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
        return

    def test_jsonvalidate(self):
        """
        test the jsonvalidate.dovalidate function with a direct call
        :return:
        """
        data = jsonvalidate.load_json(path=Path(__file__).parent / "simpleIM_test.json")
        schema = jsonvalidate.load_json(path=self.IM_schema)
        errors, draft_label = jsonvalidate.dovalidate(data=data,
                                                      schema=schema,
                                                      # draft=,
                                                      # quiet=True
                                                      # schema_dir=jsonvalidate
                                                      )
        self.assertTrue(draft_label in schema.get("$schema"))
        self.assertTrue(len(errors) == 0)

        # validate entity with im-schema
        errors, draft_label = jsonvalidate.dovalidate \
                (data=jsonvalidate.load_json(
                path=Path(__file__).parent / "simpleentity_test.json"),
                schema=jsonvalidate.load_json
                (path=self.IM_schema),
                draft="7",
                quiet=True,
                schema_dir=self.IM_schema
            )
        self.assertEqual("7",draft_label)
        self.assertTrue(len(errors) == 2)

        # validate entity with entity
        errors, draft_label = jsonvalidate.dovalidate(data=jsonvalidate.load_json(
            path=Path(__file__).parent / "simpleentity_test.json"),
            schema=jsonvalidate.load_json(self.schemapath / "InformationModel" / "Entity-schema.json"),
            # draft=,
            quiet=False,
            schema_dir=self.schemapath
        )
        self.assertTrue(len(errors) == 0)
        return

    def test_callvalidatemain(self):
        """
        test the call of the pythom module (main) as a subprocess
        :return:
        """
        import subprocess
        command = [
            sys.executable,
            "../../im-standard-python/jsonvalidate.py",
            str((Path(__file__).parent /"simpleentity_test.json").resolve()), #json file
            str((self.schemapath / "InformationModel" / "Entity-schema.json")), #schema file
            "--verbose",
        ]

        result = subprocess.run(
            command,
            cwd=Path(__file__).parent.parent.parent / "Model" / "im-standard-schema",
            capture_output=True,
            text=True
        )
        print (result.stdout)
        print (result.stderr)

        self.assertTrue( result.returncode == 0)

        command = [
            sys.executable,
            "../../im-standard-python/jsonvalidate.py",
            str((Path(__file__).parent /"simpleentity_test.json").resolve()), #json file
            str((self.schemapath / "InformationModel" / "InformationModel-schema.json")), #schema file
            "--verbose",
        ]
        result = subprocess.run(
            command,
            cwd=Path(__file__).parent.parent.parent / "Model" / "im-standard-schema",
            capture_output=True,
            text=True
        )
        print (result.stdout)
        print (result.stderr)
        self.assertTrue( result.returncode == 1)
        self.assertTrue("INVALID — 3 error(s) found" in result.stdout)

        return

if __name__ == '__main__':
    unittest.main()
