#mcandrew

class dataprep(object):
    def __init__(self):
        self.load_cases()
        self.load_deaths()
        self.load_hosps()
        self.merge()
        self.mergeCounties()
        self.combineStateAndCounty()
        
    def load_cases(self):
        import pandas as pd
        cases = pd.read_csv("../../data-truth/truth-Incident Cases.csv")
        cases.location = cases.location.astype(str)
        
        # we need to separate cases at the state level from cases at county level
        cases_counties = cases.loc[ [True if len(_)>=4 else False for _ in cases.location] ,:]

        cases_counties = cases_counties.rename(columns = {"value":"cases"})
        cases = cases.rename(columns = {"value":"cases"})
        self.cases = cases

        # strips the last three digits from the FIPS to get either 1 or 2 digits, then left fills with 0 if 1 digit
        state_codes = cases_counties.apply(lambda x: x['location'][:-3].zfill(2), axis=1)

        # appends to the dataframe
        cases_counties.insert(len(cases_counties.columns), 'state', state_codes)

        self.ccases_counties = cases_counties
        
    def load_deaths(self):
        import pandas as pd
        deaths = pd.read_csv("../../data-truth/truth-Incident Deaths.csv")
        deaths.location = deaths.location.astype(str)

        deaths = deaths.rename(columns = {"value":"deaths"})

        # NOTE: THIS IS A VERY EXPENSIVE OPERATION
        normalize_loc = deaths.apply(lambda x: x['location'].zfill(2), axis=1)
        deaths.insert(len(deaths.columns), 'nloc', normalize_loc)

        self.deaths = deaths

    def load_hosps(self):
        import pandas as pd
        hosps = pd.read_csv("../../data-truth/truth-Incident Hospitalizations.csv")
        hosps.location = hosps.location.astype(str)
        
        hosps = hosps.rename(columns = {"value":"hosps"})

        # NOTE: THIS IS A VERY EXPENSIVE OPERATION
        normalize_loc = hosps.apply(lambda x: x['location'].zfill(2), axis=1)
        hosps.insert(len(hosps.columns), 'nloc', normalize_loc)

        self.hosps = hosps

    def merge(self):
        key = ["date","location","location_name"]
        d = self.cases.merge(self.deaths, on = key)
        d = d.merge(self.hosps, on = key )

        self.threestreams_state = d
        return d

    def mergeCounties(self):
        # merge the county cases with state deaths
        d = self.ccases_counties.merge(self.deaths, left_on=['date', 'state'], right_on=['date', 'nloc'], suffixes=(None, "_d"))
        # merge the county cases with state hosps
        d = d.merge(self.hosps, left_on=['date', 'state'], right_on=['date', 'nloc'], suffixes=(None, "_h"))
        d = d.drop(columns=['state', 'location_d', 'location_name_d', 'nloc', 'location_h', 'location_name_h', 'nloc_h'])

        self.threestreams_county = d
        return d

    def combineStateAndCounty(self):
        import pandas as pd
        # append county threestreams to state threestreams
        d = pd.concat([self.threestreams_state, self.threestreams_county])

        # store it in instance variable threestreams
        self.threestreams = d
        
        # rename columns in threestreams_county for clarity
        self.threestreams_county = self.threestreams_county.rename(columns={"cases":"county_cases", "deaths":"state_deaths", "hosps":"state_hosps"})

    def write(self):
        def tocsv(x,f):
            x.to_csv(f,index=False,compression = "gzip")
        tocsv(self.threestreams_state,"threestreams__state.csv.gz")
        tocsv(self.threestreams_county,"threestreams__county.csv.gz")
        tocsv(self.threestreams,"threestreams.csv.gz")
        tocsv(self.cases,"cases.csv.gz")
        tocsv(self.deaths,"deaths.csv.gz")
        tocsv(self.hosps,"hosps.csv.gz")
        
if __name__ == "__main__":

    dtap = dataprep()
    dtap.write()
