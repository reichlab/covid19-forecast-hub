#mcandrew

class dataprep(object):
    def __init__(self):
        self.load_cases()
        self.load_deaths()
        self.load_hosps()
        self.merge()
        
    def load_cases(self):
        import pandas as pd
        cases = pd.read_csv("../../data-truth/truth-Incident Cases.csv")
        cases.location = cases.location.astype(str)
        
        # we need to separate cases at the state level from cases at county level
        cases_counties = cases.loc[ [True if len(_)==4 else False for _ in cases.location] ,:]
        
        cases = cases.rename(columns = {"value":"cases"})
        self.cases = cases

        self.ccases_counties = cases_counties
        
    def load_deaths(self):
        import pandas as pd
        deaths = pd.read_csv("../../data-truth/truth-Incident Deaths.csv")
        deaths.location = deaths.location.astype(str)

        deaths = deaths.rename(columns = {"value":"deaths"})
        self.deaths = deaths

    def load_hosps(self):
        import pandas as pd
        hosps = pd.read_csv("../../data-truth/truth-Incident Hospitalizations.csv")
        hosps.location = hosps.location.astype(str)
        
        hosps = hosps.rename(columns = {"value":"hosps"})
        self.hosps = hosps

    def merge(self):
        key = ["date","location","location_name"]
        d = self.cases.merge(self.deaths, on = key)
        d = d.merge(self.hosps, on = key )

        self.threestreams = d
        return d

    def write(self):
        self.threestreams.to_csv("threestreams.csv")
        self.cases.to_csv("cases.csv")
        self.deaths.to_csv("deaths.csv")
        self.hosps.to_csv("hosps.csv")
    
if __name__ == "__main__":

    dtap = dataprep()
    dtap.write()
    
    

    

