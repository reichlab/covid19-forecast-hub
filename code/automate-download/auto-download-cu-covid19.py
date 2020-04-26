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
    today = datetime.datetime.today()
    # today_dates = calendar.month_name[today.month] + today.strftime('%d')
    today_dates = "April23"
    suffix = "/cdc_hosp/state_cdchosp_"
    raw_list = ["60contact.csv", "70contact.csv", "80contact.csv", "nointerv.csv"]

    # Check if there's new data
    url = prefix+today_dates+suffix+raw_list[0]
    response = requests.get(url)
    savepath = os.path.join(path, "Projection_"+today_dates+"/cdc_hosp/")
    if response.status_code == 200:
        if not os.path.exists(savepath):
            os.makedirs(savepath)
    else:
        print("No new raw data from CU")
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
