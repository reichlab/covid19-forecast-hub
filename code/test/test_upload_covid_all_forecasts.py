import unittest
from unittest.mock import patch, MagicMock

from zoltpy.connection import Project, Model

from code.zoltar_scripts.upload_covid19_forecasts_to_zoltar import upload_covid_all_forecasts, has_changed


# metadata_field_to_zoltar = {
#     'team_name': 'team_name',
#     'model_name': 'name',
#     'model_abbr': 'abbreviation',
#     'model_contributors': 'contributors',
#     'website_url': 'home_url',
#     'license': 'license',
#     'team_model_designation': 'notes',
#     'methods': 'description',
#     'repo_url': 'aux_data_url',
#     'citation': 'citation',
#     'methods_long': 'methods'
# }
class UploadCovidAllForecastsTestCase(unittest.TestCase):

    def test_has_changed(self):

        metadata_dict = {
            'team_name': 'test_team',
            'model_name': 'test_name',
            'model_abbr': 'test_abbr',
            'model_contributors': 'test_contrib',
            'website_url': 'test_url',
            'license': 'test_license',
            'team_model_designation': 'test_notes',
            'methods': 'test_methods',
            'repo_url': 'test_repo_url',
            'citation': 'test_citation',
            'methods_long': 'test_methods_long'
        }

        zoltar_json = {
            'team_name': 'test_team',
            'name': 'test_name',
            'abbreviation': 'test_abbr',
            'contributors': 'test_contrib',
            'home_url': 'test_url',
            'license': 'test_license',
            'notes': 'test_notes',
            'description': 'test_methods',
            'aux_data_url': 'test_repo_url',
            'citation': 'test_citation',
            'methods': 'test_methods_long'
        }
        # Case: Not has changed.
        zoltar_model = Model(None, None, initial_json=zoltar_json)
        self.assertFalse(has_changed(metadata_dict, zoltar_model))

        # Case: missing field?
        tmp_metadata_dict = dict(metadata_dict)
        del tmp_metadata_dict['model_contributors']
        self.assertTrue(has_changed(tmp_metadata_dict, zoltar_model))

        # Case: field nto equal
        tmp_metadata_dict = dict(metadata_dict)
        tmp_metadata_dict['model_contributors'] = 'something not equal'
        self.assertTrue(has_changed(tmp_metadata_dict, zoltar_model))

    def test_upload_covid_all_forecasts(self):
        connection_mock = MagicMock()
        project_mock = MagicMock()
        project_mock.name = 'COVID-19 Forecasts'
        tz1 = MagicMock()
        tz1.timezero_date = '2020-06-15'
        tz2 = MagicMock()
        tz2.timezero_date = '2020-06-22'
        project_mock.timezeros = [tz1, tz2]
        model1 = MagicMock()
        model1.abbreviation = 'COVIDhub-ensemble'
        # TODO: Check why this does not work
        # model1.edit = MagicMock(name='method')
        model2 = MagicMock()
        model2.abbreviation = 'mobility'
        project_mock.models = [model1, model2]
        with patch('zoltpy.util.authenticate') as auth_mock:
            auth_mock.return_value = connection_mock
            connection_mock.projects = [project_mock]
            pass
        # Case: has_changed =False

        with patch('code.zoltar_scripts.upload_covid19_forecasts_to_zoltar.has_changed',
                   return_value=False), \
             patch(
                 'code.zoltar_scripts.upload_covid19_forecasts_to_zoltar.upload_covid_all_forecasts',
                 return_value="Pass"):
            val_errors_or_pass = upload_covid_all_forecasts(
                'code/test/data/COVIDhub-ensemble/',
                'COVIDhub-ensemble')
        # Case: has_changed =True

        self.assertEqual("Pass", val_errors_or_pass)

# class MockConnection:
#
#     def projects(self):
#         pass
#
#
# class MockProject(Project):
#
#     def create_model
