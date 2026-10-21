# Architecture

~~~text
R/01_generate_logs.R
  deterministic synthetic telemetry + labeled injected scenarios
                    |
                    v
R/02_analyze_logs.R
  clean, aggregate, score, correlate incidents, calculate lifecycle metrics
                    |
                    v
data/processed/*.csv <---- R/03_validate.R validates contracts and relations
       |                                  |
       |                                  +--> R/04_prepare_dashboard_data.R
       v                                                   |
Power BI Desktop                                           v
six-page report                                    web/public/data/*.csv
                                                            |
                                                            v
                                                    React + Vite dashboard
~~~

The project contains no real cloud APIs, credentials, accounts, or telemetry. R is the single producer. Power BI and the local web dashboard are independent presentation layers that read the same validated analytical outputs.

