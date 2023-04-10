import logging
import unittest
from unittest.mock import MagicMock, patch

from zoltpy.connection import Model

from code.zoltar_scripts.upload_covid19_forecasts_to_zoltar import upload_covid_all_forecasts, has_changed, \
    upload_covid_forecast_by_model


logging.getLogger().setLevel(logging.DEBUG)


class UploadCovidAllForecastsTestCase(unittest.TestCase):
    """
    NB: Running these unit tests requires setting the working dir to the repo root.
    """


    #
    # metadata tests
    #

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


    #
    # upload_covid_forecast_by_model() tests
    #

    def test_upload_covid_forecast_by_model_returns_job(self):
        """
        tests that `upload_covid_forecast_by_model()` returns a Job
        """
        # case: upload_forecast() does not raise RuntimeError -> returns a Job
        conn = MagicMock(name='connection')
        conn.re_authenticate_if_necessary = MagicMock()

        job_mock = MagicMock(name='job')
        job_mock.status_as_str = 'SUCCESS'
        model_mock = MagicMock(name='model')
        model_mock.upload_forecast = MagicMock(return_value=job_mock)
        job = upload_covid_forecast_by_model(conn, {}, '', '', model_mock, '', '')
        self.assertEqual(job_mock, job)

        # case: upload_forecast() does raise RuntimeError -> returns None
        model_mock.upload_forecast.reset_mock()
        model_mock.upload_forecast = MagicMock(side_effect=RuntimeError('upload_forecast RuntimeError'))
        job = upload_covid_forecast_by_model(conn, {}, '', '', model_mock, '', '')
        self.assertIsNone(job)
        self.assertEqual(2, model_mock.upload_forecast.call_count)


    #
    # upload_covid_all_forecasts() tests
    #

    def test_upload_covid_all_forecasts_return_values(self):
        """
        tests `upload_covid_all_forecasts()` return value cases
        """
        project_mock = MagicMock(name='project')
        conn = MagicMock(name='connection')
        conn.re_authenticate_if_necessary = MagicMock()

        # case: `create_model()` raises Exception -> return ex
        models = []  # does not contain COVIDhub-ensemble -> will call create_model()
        project_mock.create_model = MagicMock(side_effect=Exception('create_model Exception'))
        result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock, [],
                                            None, models, {})
        self.assertEqual(project_mock.create_model.side_effect, result)

        # case: `create_timezero()` raises Exception -> return ex
        model_mock = MagicMock(name='model')
        model_mock.abbreviation = 'COVIDhub-ensemble'
        model_mock.forecasts = []
        models = [model_mock]  # contains COVIDhub-ensemble -> will call not call create_model()

        project_mock.reset_mock()
        project_mock.create_timezero = MagicMock(side_effect=Exception('create_timezero Exception'))
        model_mock.reset_mock()

        # patch has_changed() so that `model.edit()` is not called:
        with patch('code.zoltar_scripts.upload_covid19_forecasts_to_zoltar.has_changed', return_value=False):
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock, [],
                                                None, models, {})
            self.assertEqual(project_mock.create_timezero.side_effect, result)

            # case: `validate_quantile_csv_file()` returns not "no errors" -> return error_messages
            project_timezeros = ['2020-07-13']  # from test/data/COVIDhub-ensemble/2020-07-13-COVIDhub-ensemble.csv
            errors = ['an error']
            with patch('zoltpy.covid19.validate_quantile_csv_file', return_value=errors):
                result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                    project_timezeros, conn, models, {})
                self.assertEqual(errors, result)

            # case: `json_io_dict_from_quantile_csv_file()` returns non-empty error_messages -> return error_messages
            with patch('zoltpy.quantile_io.json_io_dict_from_quantile_csv_file', return_value=({}, errors)):
                result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                    project_timezeros, conn, models, {})
                self.assertEqual(errors, result)

            # case: `upload_covid_forecast_by_model()` returns `job = None` -> return "upload job failed.*"
            model_mock.upload_forecast = MagicMock(side_effect=RuntimeError('upload_forecast RuntimeError'))
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                project_timezeros, conn, models, {})
            self.assertRegex(result, "upload job failed.*")

            # case: blue sky -> return []
            job_mock = MagicMock(name='job')
            job_mock.status_as_str = 'SUCCESS'
            model_mock.upload_forecast = MagicMock(return_value=job_mock)
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                project_timezeros, conn, models, {})
            self.assertEqual([], result)


    def test_upload_covid_all_forecasts_calls_create_model_if_missing(self):
        """
        tests that `upload_covid_all_forecasts()` calls `zoltpy.connection.Project.create_model()` if model missing
        """
        project_mock = MagicMock(name='project')
        conn = MagicMock(name='connection')
        conn.re_authenticate_if_necessary = MagicMock()

        job_mock = MagicMock(name='job')
        job_mock.status_as_str = 'SUCCESS'
        model_mock = MagicMock(name='model')
        model_mock.abbreviation = 'COVIDhub-ensemble'
        model_mock.forecasts = []
        model_mock.upload_forecast = MagicMock(return_value=job_mock)
        project_mock.create_model = MagicMock(return_value=model_mock)

        project_timezeros = ['2020-07-13']  # from test/data/COVIDhub-ensemble/2020-07-13-COVIDhub-ensemble.csv
        models = []  # does not contain COVIDhub-ensemble -> will call create_model()

        # patch has_changed() so that `model.edit()` is not called:
        with patch('code.zoltar_scripts.upload_covid19_forecasts_to_zoltar.has_changed', return_value=False):
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                project_timezeros, conn, models, {})
            project_mock.create_model.assert_called_once()
            self.assertEqual([], result)


    def test_upload_covid_all_forecasts_does_not_update_db_if_failed_job(self):
        """
        tests that `upload_covid_all_forecasts()` does not do `db[forecast] = checksum` if the job returned by
        `upload_covid_forecast_by_model()` was not successful
        """
        project_mock = MagicMock(name='project')
        conn = MagicMock(name='connection')
        conn.re_authenticate_if_necessary = MagicMock()

        job_mock = MagicMock(name='job')
        job_mock.status_as_str = 'FAILED'  # anything other than 'SUCCESS' will work
        model_mock = MagicMock(name='model')
        model_mock.abbreviation = 'COVIDhub-ensemble'
        model_mock.forecasts = []
        model_mock.upload_forecast = MagicMock(return_value=job_mock)

        project_timezeros = ['2020-07-13']  # from test/data/COVIDhub-ensemble/2020-07-13-COVIDhub-ensemble.csv
        models = [model_mock]  # contains COVIDhub-ensemble -> will call not call create_model()
        db = {}

        # case: job failed
        # patch has_changed() so that `model.edit()` is not called:
        with patch('code.zoltar_scripts.upload_covid19_forecasts_to_zoltar.has_changed', return_value=False):
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                project_timezeros, conn, models, db)
            self.assertEqual(2, model_mock.upload_forecast.call_count)  # two tries
            self.assertEqual({}, db)  # failed job -> no db entry added for forecast
            self.assertRegex(result, "upload job failed.*")

            # blue sky case: job successful
            model_mock.upload_forecast.reset_mock()
            job_mock.reset_mock()
            job_mock.status_as_str = 'SUCCESS'
            result = upload_covid_all_forecasts('code/test/data/COVIDhub-ensemble/', 'COVIDhub-ensemble', project_mock,
                                                project_timezeros, conn, models, db)
            model_mock.upload_forecast.assert_called_once()

            # example db: {'2020-07-13-COVIDhub-ensemble.csv': '689b7a827b6904a9d7fea72c13daf6b5'}
            self.assertEqual(1, len(db.keys()))
            self.assertEqual('2020-07-13-COVIDhub-ensemble.csv', list(db.keys())[0])
            self.assertEqual([], result)
