# tests/test_rp_handler.py

import unittest
from unittest.mock import patch, MagicMock, mock_open, Mock
import sys
import os
import json
import base64

# Add src to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

import rp_handler  # from src/rp_handler.py


class TestRunpodWorkerComfy(unittest.TestCase):
    # Example tests you may keep or adapt
    def test_validate_input(self):
        input_data = {
            "workflow": {"test": "data"},
            "callbackUrl": "http://localhost:3000/callback"
        }
        validated, error = rp_handler.validate_input(input_data)
        self.assertIsNone(error)
        self.assertEqual(validated["workflow"], {"test": "data"})
        self.assertEqual(validated["callbackUrl"], "http://localhost:3000/callback")

    def test_validate_input_missing_workflow(self):
        input_data = {"callbackUrl": "http://localhost"}
        validated, error = rp_handler.validate_input(input_data)
        self.assertIsNotNone(error)
        self.assertIn("Missing 'workflow'", error)

    # ... More tests as needed ...


if __name__ == "__main__":
    unittest.main()
