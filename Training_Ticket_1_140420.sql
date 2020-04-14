-- 1 - How many clients do we have?
SELECT COUNT(*) AS total_clients
FROM ol.salesforce_accounts
WHERE type IN ('Customer','Reactivation','Cancelled Client','Closed Down','Do Not Contact')
