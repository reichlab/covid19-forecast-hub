# Before executing the script, we need urllib3. Run `pip install urllib3`
# A simple script for automatically download the ihme-covid19.zip file and extract it
import requests
import os
import sys
import calendar
import datetime
def download_file_by_date(path, date):
    # metadata
    prefix = "https://raw.githubusercontent.com/shaman-lab/COVID-19Projection/master/Projection_"
    suffix = "/cdc_hosp/state_cdchosp_"
    raw_list = ["60contact.csv", "70contact.csv", "80contact.csv", "nointerv.csv", "80contact_1x.csv", "80contactw.csv"]

    # Check all urls if there's new data on specific date
    working_urls = []
    for raw_file in raw_list:
        url = prefix+date+suffix+raw_file
        response = requests.get(url)
        working_urls.append(response.status_code)

    # Download data
    savepath = os.path.join(path, "Projection_"+date+"/cdc_hosp/")
    if 200 in working_urls:
        if not os.path.exists(savepath):
            os.makedirs(savepath)
        for raw_file in raw_list:
            url = prefix+date+suffix+raw_file
            response = requests.get(url)
            if response.status_code == 200:
                with open(os.path.join(savepath,"state_cdchosp_"+raw_file), "wb") as writer:
                    for chunk in response:
                        writer.write(chunk)
                    writer.close()
        return True
    else:
        return False

def download_recent_CU_data(path):

    # Because the script is run at 1pm everyday, it may miss forecasts that 
    # are uploaded after 1pm if the script only look at the current day. We
    # set it up to also look at the day before
    today = datetime.datetime.today() - datetime.timedelta(days=2)
    today_date_v1 = calendar.month_name[today.month] + today.strftime('%d')
    today_date_v2 = calendar.month_name[today.month] + today.strftime('%d').strip('0')
    yesterday = datetime.datetime.today() - datetime.timedelta(days=1)
    yesterday_date_v1 = calendar.month_name[yesterday.month] + yesterday.strftime('%d')
    yesterday_date_v2 = calendar.month_name[yesterday.month] + yesterday.strftime('%d').strip('0')

    # Check for different combination of new data from yesterday (Example: May3 vs May03)
    download_with_yesterday_v1_is_successful = download_file_by_date(path, yesterday_date_v1)
    download_with_yesterday_v2_is_successful = download_file_by_date(path, yesterday_date_v2)
    if (download_with_yesterday_v1_is_successful or download_with_yesterday_v2_is_successful):
        print('There is new data from CU on '+yesterday_date_v1)
    else:
        print('There is no new data from CU on '+yesterday_date_v1)

    # Check for different combination of new data from today (Example: May4 vs May04)
    download_with_today_v1_is_successful = download_file_by_date(path, today_date_v1)
    download_with_today_v2_is_successful = download_file_by_date(path, today_date_v2)
    if (download_with_today_v1_is_successful or download_with_today_v2_is_successful):
        print('There is new data from CU on '+today_date_v1)
    else:
        print('There is no new data from CU on '+today_date_v1)

if __name__ == '__main__':
    path = sys.argv[1]
    download_recent_CU_data(path)
