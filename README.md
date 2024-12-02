# Data_Analyst_milaap_assignment
Data Analysis assignment for Milaap using PostgreSQL

Here’s a brief explanation these tables -
Campaigns - Contains list of fundraisers with their names , goal amount , start date ,
source from which they were created, id and project id.
Projects - Project is a set of campaigns for a specific cause , project can have
multiple campaigns, and the category to which it belongs.
Payments - This has all the donations along with the date, currency , amount and
status of payment [if ot was completed or failed]
Withdrawals - This has a list of entries where money is withdrwan from the
project/campaign.
These are dummy values and might not have a correlation.

Questions -

. List of campaigns where the pending amount is greater than 1k , Submitted in
this year , sorted with highest pending amount.
. Project wise withdrawal ,show currency wise raised and transferred
. % of withdrawals happened from APP
. This year total amount that was requested and total amount that got transferred
[all in inr equivalent]
. Project wise amount raised and failed amount [ inr equivalent]
. List the campaigns which have amount raised more than 80%. [ raised take in inr
equivalent]
. Channel wise amount raised this month sorted with highest raise. [raised take in
inr equivalant]
. Month wise payment success rate.
