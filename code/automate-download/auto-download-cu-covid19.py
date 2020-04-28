# Before executing the script, we need urllib3. Run `pip install urllib3`
# A simple script for automatically download the ihme-covid19.zip file and extract it
import requests
import os
import sys
import calendar
import datetime

def download_covid_zip_files(path):
    # metadata
    prefix = "https://raw.githubusercontent.com/shaman-lab/COVID-19Projection/master/Projection_"
    suffix = "/cdc_hosp/state_cdchosp_"
    raw_list = ["60contact.csv", "70contact.csv", "80contact.csv", "nointerv.csv"]

    # Because the script is run at 1pm everyday, it may miss forecasts that 
    # are uploaded after 1pm if the script only look at the current day. We
    # set it up to also look at the day before
    today = datetime.datetime.today()
    today_dates = calendar.month_name[today.month] + today.strftime('%d')
    yesterday = datetime.datetime.today() - datetime.timedelta(days=1)
    yesterday_dates = calendar.month_name[yesterday.month] + yesterday.strftime('%d')

    # Check if there's new data yesterday
    url = prefix+yesterday_dates+suffix+raw_list[0]
    response = requests.get(url)
    savepath = os.path.join(path, "Projection_"+yesterday_dates+"/cdc_hosp/")
    if response.status_code == 200:
        if not os.path.exists(savepath):
            print("There's new data from CU yesterday")
            os.makedirs(savepath)
        for raw_file in raw_list:
            url = prefix+yesterday_dates+suffix+raw_file
            response = requests.get(url)
            if response.status_code == 200:
                with open(os.path.join(savepath,"state_cdchosp_"+raw_file), "wb") as writer:
                    for chunk in response:
                        writer.write(chunk)
                    writer.close()
    else:
        print("No new raw data from CU yesterday")

    # Check if there's new data today
    url = prefix+today_dates+suffix+raw_list[0]
    response = requests.get(url)
    savepath = os.path.join(path, "Projection_"+today_dates+"/cdc_hosp/")
    if response.status_code == 200:
        if not os.path.exists(savepath):
            print("There's new data from CU today")
            os.makedirs(savepath)
    else:
        print("No new raw data from CU today")
        return
    
    for raw_file in raw_list:
        url = prefix+today_dates+suffix+raw_file
        response = requests.get(url)
        if response.status_code == 200:
            with open(os.path.join(savepath,"state_cdchosp_"+raw_file), "wb") as writer:
                for chunk in response:
                    writer.write(chunk)
                writer.close()

if __name__ == '__main__':
    path = sys.argv[1]
    download_covid_zip_files(path)
