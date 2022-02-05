class viz(object):
    
    def __init__(self,dataQuantiles,realized_data,loc):
        self.d = dataQuantiles

        self.loc =loc
        self.rdata = realized_data
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

        dir = self.checkDir()

        rdata =self.rdata
        print(rdata)
        for target in ["cases","deaths","hosps"]:

            target_quantiles = self.d.loc[self.d.target.str.contains(target[:3])]
            target_quantiles["quantile"] = target_quantiles["quantile"].astype(float)

            plt.style.use("fivethirtyeight")
            fig,ax = plt.subplots()
            p = ax.plot(rdata["date"],rdata[target],lw=2)

            colors = [x.get_color() for x in p]
            color = colors[0]

            cis = target_quantiles.loc[ (target_quantiles["quantile"].isin([0.025,0.50,0.975]))  ]

            target_end_dates = cis.target_end_date.unique()

            low = cis.loc[cis["quantile"]==0.025,"value"]
            mid = cis.loc[cis["quantile"]==0.50,"value"]
            hig = cis.loc[cis["quantile"]==0.975,"value"]

            ax.fill_between(target_end_dates , low, hig, color = color, alpha=0.50 )
            ax.plot( target_end_dates, mid, color=color, lw=1,ls="--",label="Loc = {:d}".format(self.loc))

            ax.tick_params(which="both",labelsize=6)

            ax.set_xticks(ax.get_xticks()[::-1][::21][::-1])

            ax.set_xlabel("Target end date",fontsize=8)
            ax.set_ylabel("Num. of confirmed flu hosps",fontsize=8)
            ax.legend(fontsize=10)

            w=self.mm2inch(183)
            fig.set_size_inches(w,w/1.6)

            plt.savefig("{:s}/LOC_{:02d}_{:s}.pdf".format(dir,self.loc,target))
            plt.savefig("{:s}/LOC_{:02d}_{:s}.png".format(dir,self.loc,target),dpi=300)

            plt.close()

