#mcandrew,parth,matt

from interface import interface
from model import VAR

if __name__ == "__main__":
    
    io = interface(0)
    for n,location in enumerate(io.locations):
        io = interface(0)
        
        io.subset2locations([location])

        forecast_model = VAR(io.modeldata)
        forecast_model.fit()

        io.formatSamples( forecast_model)
        io.un_center() # multipy by std and add back running mean

        io.dataPredictions.to_csv("dataPredictions__example.csv.gz",compression="gzip",index=False)
        break
    
