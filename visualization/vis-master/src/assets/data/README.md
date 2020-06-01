## Visualization JSON data

The visualization uses these `.JSON` files for its data.

* `season-latest.json` - Cumulative Deaths Data
* `season-Incident Deaths.json` - Incident Deaths Data

### JSON Strucure
```
{
    seasonID: < Incident Deaths / Cumulative Deaths > ,
    regions: 
    [{
        id: < State Abbreviation "MA","CT" > ,  # "nat" i.e. National or US
        actual: [{
                week: < year + epiweek 1 > , #i.e. 202001 means year 2020 epiweek 1
                actual: < actual value of Cumulative / Incident Deaths for that epiweek >
            },
            {
                week: < year + epiweek 2 > ,
                actual: < actual value of Cumulative / Incident Deaths for that epiweek >
            },
            ...
            {
                week: < year + last epiweek > ,
                actual: < actual value of Cumulative / Incident Deaths for that epiweek >
            }],
        models: 
            [{
                id: < Model Team Name + Model Abbreviation from Metadata File > ,
                meta: {
                    name: < Full Team Name + Model Name > ,
                    description: < Full Model Description > ,
                    url: < Model Metadata URL >
                },
                predictions: 
                [{
                    # for each of the 52 i.e. [0, 51] Epiweeks & same order as Actual Epiweeks
                    # if "null" that means that model had no prediction for that epiweek / location

                    null,null,null,...
                    {
                        series: [{
                                point: < point estimate for 1 wk ahead in that epiweek / model / location > ,
                                high: [ < top value for 90 % CI > , < top valuefor 50 % CI >],
                                low: [ < bottom value for 90 % CI > , < bottom value for 50 % CI >]
                            },
                            {
                                point: < point estimate for 2 wk ahead in that epiweek / model / location > ,
                                high: [ < top value for 90 % CI > , < top valuefor 50 % CI >],
                                low: [ < bottom value for 90 % CI > , < bottom value for 50 % CI >]
                            },
                            {
                                point: < point estimate for 3 wk ahead in that epiweek / model / location > ,
                                high: [ < top value for 90 % CI > , < top valuefor 50 % CI >],
                                low: [ < bottom value for 90 % CI > , < bottom value for 50 % CI >]
                            },
                            {
                                point: < point estimate for 4 wk ahead in that epiweek / model / location > ,
                                high: [ < top value for 90 % CI > , < top valuefor 50 % CI >],
                                low: [ < bottom value for 90 % CI > , < bottom value for 50 % CI >]
                            }
                        ]
                    }, null,null, null, ...
                }]
            },
            {
                id: < Model Team Name + Model Abbreviation from Metadata File > ,
                meta: {
                    name: < Full Team Name + Model Name > ,
                    description: < Full Model Description > ,
                    url: < Model Metadata URL >
                    ...
                }, ...
            }]
        # Repeats for every region
    }]
}

```
