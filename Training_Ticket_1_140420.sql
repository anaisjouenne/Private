--This is a SQL training ticket, it contains requirements of increasing difficulty to get more familiar with SQL and our data.
-- For each of the required elements, create a SQL file.

--You find data regarding companies in our object layer:
--SELECT * FROM ol.salesforce_accounts LIMIT 10
--The honeypot_it correlates with the company_id of other tables.
--The owner_id connects with ol.salesforce_users and gives information about who the current CSM is.
--The type column is an indicator if the company is still an active client or maybe just a lead.
--Those are clients we would consider as clients (or former clients): ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
--You can find data about placements in placements
--You can find our time dimension in time_d

-- 1 - How many clients do we have?
SELECT COUNT(*) AS total_clients
FROM ol.salesforce_accounts
WHERE type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')


--3 - How many clients per type?
SELECT type,
COUNT(*) AS total_clients
FROM ol.salesforce_accounts
WHERE type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
GROUP BY type
ORDER by total_clients DESC

--4 - How many clients per type who are in Berlin?
SELECT type,
COUNT(*) AS total_clients
FROM ol.salesforce_accounts
WHERE primary_market='Berlin'
AND type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
GROUP BY type
ORDER by total_clients DESC

--5 - Which CSM has the most (existing) companies to take care off?
SELECT su.name,
COUNT(DISTINCT sa.id) AS total_clients
FROM ol.salesforce_accounts sa
LEFT JOIN ol.salesforce_users su  ON sa.owner_id=su.id
WHERE type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
GROUP BY su.name
ORDER by total_clients DESC
-- LIMIT 1

--6 - Which active client has the most hires? What's the name of this company?
SELECT sa.name,
COUNT(p.id) AS total_hires
FROM placements p
LEFT JOIN ol.salesforce_accounts sa ON p.company_id=sa.honeypot_id
--WHERE sa.account_status='Full Client' -- Not sure about Full client, how do we define "Active" -- Without the where close the amount of rows should be equal to Q7, but that's not the case. Why?!
AND p.refund_case_at IS NULL
GROUP BY sa.name
ORDER by total_hires DESC

--7 - How many clients have ever hired?
SELECT COUNT (DISTINCT p.company_id)
FROM placements p
WHERE p.refund_case_at IS NULL

--8 - A list of all companies with more than 3 hires (>3)
SELECT sa.name,
COUNT(p.id) AS total_hires
FROM ol.salesforce_accounts sa
LEFT JOIN placements p ON sa.honeypot_id =p.company_id
WHERE p.refund_case_at IS NULL
GROUP BY sa.name
HAVING COUNT(p.id) > 3
ORDER BY total_hires DESC

--9 - How many hires have we had in our markets, ordered by hires descending?
SELECT sa.primary_market,
COUNT(p.id) AS total_hires
FROM ol.salesforce_accounts sa
LEFT JOIN placements p ON sa.honeypot_id =p.company_id
GROUP BY sa.primary_market
ORDER BY total_hires DESC, primary_market NULLS LAST

-- 10 - A list of CSM, the number of companies they manage, the number of hires those companies had and the last time any of those companies hired.
SELECT su.name,
COUNT (DISTINCT sa.id) AS total_clients,
COUNT(p.id) AS total_hires,
MAX(p.placed_at) AS last_hired_at
FROM ol.salesforce_users su
LEFT JOIN ol.salesforce_accounts sa ON su.id=sa.owner_id
LEFT JOIN placements p ON sa.honeypot_id =p.company_id
WHERE type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
GROUP BY su.name
ORDER BY total_clients DESC, total_hires DESC

--11 - How many companies do we sign per period for every period in 2019?
SELECT
       t.period,
       COUNT(sa.id)
FROM ol.salesforce_accounts AS sa
LEFT JOIN time_d AS t ON sa.signature_date=t.date
WHERE period BETWEEN 'P2019-01' AND 'P2019-12'
GROUP BY t.period
ORDER BY t.period

--12 - For all companies who got signed in 2019 and hired ever since, who is the CSM managing most of them?
SELECT
       su.name AS CSM,
       COUNT(sa.id) AS total_customers_from_2019_with_hired
FROM ol.salesforce_accounts AS sa
LEFT JOIN ol.salesforce_users AS su ON sa.owner_id=su.id
WHERE sa.signature_date::date BETWEEN '2019-01-01' AND '2019-12-31'
      AND sa.had_hire IS TRUE
      AND type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact') -- Assumption: CSM only takes care of the companies with these status
GROUP BY su.name
ORDER BY total_customers_from_2019_with_hired DESC
--LIMIT 1

--12b - How long did it take the companies from signing up to the first hire on average?
WITH days_to_hire_by_company AS(
SELECT sa.name,
       sa.signature_date::date,
       MIN(p.placed_at) AS first_hired_at,
       MIN(p.placed_at) - sa.signature_date AS days_between_signature_hire
FROM ol.salesforce_accounts sa
LEFT JOIN placements p ON sa.honeypot_id =p.company_id
WHERE sa.signature_date::date BETWEEN '2019-01-01' AND '2019-12-31'
      AND sa.had_hire IS TRUE
GROUP BY sa.name, sa.signature_date)

SELECT
TRUNC(AVG (days_between_signature_hire)) AS average_days_signature_first_hire
FROM days_to_hire_by_company
