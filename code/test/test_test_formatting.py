import os
import sys
import unittest


# this line enables the following import to work if tests are run from repo root. per
# https://stackoverflow.com/questions/2262546/how-to-make-my-python-unit-tests-to-import-the-tested-modules-if-they-are-in-sis
sys.path.append(os.path.join('code', 'validation'))

from code.validation.test_formatting import check_formatting


class TestFormattingTestCase(unittest.TestCase):
    """
    NB: Running these unit tests requires setting the working dir to the repo root.
    """

    def test_check_formatting_change_pandas_append_to_concat(self):
        """
        This test drives our changing `check_formatting()`'s use of the depreciated function append() to its
        replacement, concat():
            https://pandas.pydata.org/pandas-docs/version/1.5/whatsnew/v1.4.0.html#whatsnew-140-deprecations-frame-series-append
            DataFrame.append() and Series.append() have been deprecated and will be removed in a future version. Use pandas.concat() instead (GH35407).

        The recommended change is from "Examples > Append a single row to the end of a DataFrame object" here:
        https://pandas.pydata.org/docs/dev/reference/api/pandas.concat.html
        """
        my_path = "./code/test/"  # code eventually finds 'test/data/COVIDhub-ensemble' & 'test/data/NotreDame-mobility'
        try:
            check_formatting(my_path)  # assumes runs from repo root, e.g., './code/validation/validated_files.csv'
        except Exception as ex:
            self.fail(f"unexpected exception: {ex}")
