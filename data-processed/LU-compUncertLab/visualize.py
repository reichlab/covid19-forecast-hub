class viz(object):
    
    def __init__(self,dataQuantiles,realized_data, weeklydata, loc):
        self.d = dataQuantiles

        self.loc =loc
        self.rdata = realized_data
        self.rweeklydata = weeklydata
        
        self.forecast_date = str(dataQuantiles.forecast_date.values[0])
        
    def mm2inch(self,x):
        return x/25.4

    def checkDir(self):
        import os
        dir = "./viz/{:s}".format(self.forecast_date)
        if os.path.isdir(dir):
            pass
        else:
            os.mkdir(dir)
        return dir
    
    def forecastVizLOCS(self):
        import matplotlib.pyplot as plt
        import seaborn as sns
        import pandas as pd
        import numpy as np
        
        dir = self.checkDir()
        
        for target in ["cases","deaths","hosps"]:

            if target !="hosps":
                rdata = self.rweeklydata
                rdata = rdata.sort_values("end_date")

                N = len(rdata)
                rdata["mw"] = np.arange(0,N)
                extra_mws = np.arange(N,N+4)
                
            else:
                rdata =self.rdata        

            target_quantiles = self.d.loc[self.d.target.str.contains("inc covid "+target[:3])]
            target_quantiles["quantile"] = target_quantiles["quantile"].astype(float)

            plt.style.use("fivethirtyeight")
            fig,ax = plt.subplots()

            if target !="hosps":
                p = ax.plot(rdata["mw"],rdata[target],lw=2)
            else:
                p = ax.plot(rdata["date"],rdata[target],lw=2)

            colors = [x.get_color() for x in p]
            color = colors[0]

            cis = target_quantiles.loc[ (target_quantiles["quantile"].isin([0.025,0.50,0.975]))  ]

            target_end_dates = cis.target_end_date.unique()

            low = cis.loc[cis["quantile"]==0.025,"value"]
            mid = cis.loc[cis["quantile"]==0.50,"value"]
            hig = cis.loc[cis["quantile"]==0.975,"value"]

            if target !="hosps":
                ax.fill_between(extra_mws , low, hig, color = color, alpha=0.50 )
                ax.plot( extra_mws        , mid, color=color, lw=1,ls="-",label="Loc = {:s}".format( str(self.loc) ))
            else:
                ax.fill_between(target_end_dates , low, hig, color = color, alpha=0.50 )
                ax.plot( target_end_dates, mid, color=color, lw=1,ls="-",label="Loc = {:s}".format( str(self.loc) ))

            ax.tick_params(which="both",labelsize=6)

            if target =="hosps":
                ax.set_xticks(ax.get_xticks()[::-1][::21][::-1])
                
            ax.set_xlabel("Target end date",fontsize=8)
            ax.set_ylabel("Num. of confirmed covid {:s}".format(target),fontsize=8)
            ax.legend(fontsize=10)

            if target=="hosps":
                lower_xlim, upper_xlim = ax.get_xlim()
                ax.set_xlim( 0.60*upper_xlim, upper_xlim )
            else:
                pass
                
            w=self.mm2inch(183)
            fig.set_size_inches(w,w/1.6)

            plt.savefig("{:s}/LOC_{:s}_{:s}.pdf".format(dir, str(self.loc) ,target))
            plt.savefig("{:s}/LOC_{:s}_{:s}.png".format(dir, str(self.loc) ,target),dpi=300)

            plt.close()

