-- Create the table
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(1000) NOT NULL,
    goal_amount NUMERIC(12, 2) NOT NULL,
    submitted_on DATE NOT NULL,
    channel VARCHAR(50) NOT NULL
);

-- Inserting data into the table
INSERT INTO campaigns (id, project_id, name, goal_amount, submitted_on, channel)
VALUES
    (1, 2, 'A', 200000, '2023-01-07', 'direct'),
    (2, 3, 'B', 300000, '2024-01-03', 'google'),
    (3, 4, 'C', 400000, '2024-01-05', 'google'),
    (4, 2, 'D', 100000, '2023-01-10', 'facebook'),
    (5, 5, 'E', 2500000, '2024-01-09', 'direct'),
    (6, 6, 'F', 450000, '2023-01-12', 'google');

SELECT* from campaigns
----------------------------------------------------------------------------------------
-- Create the table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    category VARCHAR(1000) NOT NULL,
    total_pending_amount NUMERIC(12, 2) NOT NULL
);

-- Insert data into the table
INSERT INTO projects (id, category, total_pending_amount)
VALUES
    (1, 'Medical', 2000),
    (2, 'Medical', 1500),
    (3, 'Memorials', 400),
    (4, 'Medical', 300),
    (5, 'Memorials', 2000),
    (6, 'Education', 4000),
    (7, 'Medical', 1200);

SELECT* from projects
----------------------------------------------------------------------------------------
-- Create the table
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    campaign_id INT NOT NULL,
    project_id INT NOT NULL,
    currency VARCHAR(10) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(50) NOT NULL
);

-- Insert data into the table
INSERT INTO payments (id, campaign_id, project_id, currency, amount, status)
VALUES
    (1, 2, 3, 'usd', 20, 'success'),
    (2, 3, 4, 'inr', 500, 'success'),
    (3, 1, 2, 'inr', 200, 'success'),
    (4, 2, 3, 'usd', 50, 'failed'),
    (5, 4, 2, 'inr', 1000, 'success'),
    (6, 5, 5, 'usd', 75, 'failed'),
    (7, 2, 3, 'inr', 10000, 'success'),
    (8, 1, 2, 'inr', 2000, 'success');

SELECT* from payments
----------------------------------------------------------------------------------------
-- Create the table
CREATE TABLE withdrawals (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    amount_requested NUMERIC(12, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    project_id INT NOT NULL
);

-- Insert data into the table
INSERT INTO withdrawals (id, source, currency, amount_requested, status, project_id)
VALUES
    (1, 'web', 'inr', 200, 'transferred', 2),
    (2, 'web', 'usd', 400, 'transferred', 3),
    (3, 'app', 'inr', 200, 'transferred', 5),
    (4, 'web', 'inr', 50, 'rejected', 1),
    (5, 'app', 'usd', 100, 'transferred', 5),
    (6, 'web', 'inr', 300, 'rejected', 2),
    (7, 'app', 'inr', 400, 'transferred', 1);
SELECT* from withdrawals
----------------------------------------------------------------------------------------
--1. Query to find campaigns with pending amount > 1k submitted this year, sorted by highest pending amount
SELECT 
    c.id AS campaign_id,
    c.name AS campaign_name,
    c.goal_amount,
    pr.total_pending_amount
FROM 
    campaigns c
JOIN 
    projects pr ON c.project_id = pr.id
WHERE 
    pr.total_pending_amount > 1000
    AND EXTRACT(YEAR FROM c.submitted_on) = 2024 -- Explicitly filtering for 2024
ORDER BY 
    pr.total_pending_amount DESC;
----------------------------------------------------------------------------------------
--2. Query to find project-wise withdrawals with currency-wise raised and transferred amounts
SELECT 
    withdrawals.project_id,
    withdrawals.currency,
    SUM(withdrawals.amount_requested) AS total_raised,
    SUM(CASE WHEN withdrawals.status = 'transferred' THEN withdrawals.amount_requested ELSE 0 END) AS total_transferred
FROM 
    withdrawals
GROUP BY 
    withdrawals.project_id, withdrawals.currency
ORDER BY 
    withdrawals.project_id, withdrawals.currency;
----------------------------------------------------------------------------------------
--3. Query to calculate the percentage of withdrawals from the APP source
SELECT 
    ROUND(
        (SUM(CASE WHEN source = 'app' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
    ) AS percentage_from_app
FROM 
    withdrawals;
----------------------------------------------------------------------------------------
--4. Query to calculate total amount requested and transferred in INR for 2024
SELECT 
    SUM(amount_requested * CASE 
        WHEN currency = 'usd' THEN 80  
        ELSE 1  
    END) AS total_requested_in_inr,
    SUM(CASE 
        WHEN status = 'transferred' THEN amount_requested * 
            CASE 
                WHEN currency = 'usd' THEN 80  
                ELSE 1  
            END
        ELSE 0
    END) AS total_transferred_in_inr
FROM 
    withdrawals
WHERE 
    EXTRACT(YEAR FROM CURRENT_DATE) = 2024;
----------------------------------------------------------------------------------------
--5.Project wise amount raised and failed amount [inr equivalent]. 
SELECT 
    project_id,
    SUM(CASE 
        WHEN status = 'success' THEN amount * 
            CASE 
                WHEN currency = 'usd' THEN 80  
                ELSE 1  
            END
        ELSE 0
    END) AS total_raised_in_inr,
    SUM(CASE 
        WHEN status = 'failed' THEN amount * 
            CASE 
                WHEN currency = 'usd' THEN 80 
                ELSE 1  
            END
        ELSE 0
    END) AS total_failed_in_inr
FROM 
    payments
GROUP BY 
    project_id;
----------------------------------------------------------------------------------------
--6.List the campaigns which have amount raised more than 80%. [Raised take in inr equivalent]. 
-- Assume 1 USD = 80 INR for conversion
SELECT 
    c.id AS campaign_id,
    c.name AS campaign_name,
    c.goal_amount,
    ROUND(SUM(
        CASE 
            WHEN p.currency = 'usd' THEN p.amount * 80 -- Convert USD to INR
            WHEN p.currency = 'inr' THEN p.amount
            ELSE 0
        END
    ), 2) AS total_raised_inr
FROM 
    campaigns c
JOIN 
    payments p ON c.id = p.campaign_id AND p.status = 'success'
GROUP BY 
    c.id, c.name, c.goal_amount
HAVING 
    SUM(
        CASE 
            WHEN p.currency = 'usd' THEN p.amount * 80
            WHEN p.currency = 'inr' THEN p.amount
            ELSE 0
        END
    ) > 0.8 * c.goal_amount
ORDER BY 
    total_raised_inr DESC;
----------------------------------------------------------------------------------------
-- Assume 1 USD = 80 INR for conversion
SELECT 
    c.id AS campaign_id,
    c.name AS campaign_name,
    c.goal_amount,
    ROUND(0.8 * c.goal_amount, 2) AS eighty_percent_goal,
    ROUND(SUM(
        CASE 
            WHEN p.currency = 'usd' THEN p.amount * 80 -- Convert USD to INR
            WHEN p.currency = 'inr' THEN p.amount
            ELSE 0
        END
    ), 2) AS total_raised_in_inr,
    CASE 
        WHEN SUM(
            CASE 
                WHEN p.currency = 'usd' THEN p.amount * 80
                WHEN p.currency = 'inr' THEN p.amount
                ELSE 0
            END
        ) > 0.8 * c.goal_amount THEN 'Yes'
        ELSE 'No'
    END AS meets_criteria
FROM 
    campaigns c
LEFT JOIN 
    payments p ON c.id = p.campaign_id AND p.status = 'success'
GROUP BY 
    c.id, c.name, c.goal_amount
ORDER BY 
    total_raised_in_inr DESC;
----------------------------------------------------------------------------------------
--7.Channel wise amount raised this month sorted with highest raise. [raised take in inr equivalant]
-- Assume 1 USD = 80 INR for conversion
SELECT 
    c.channel,
    ROUND(SUM(
        CASE 
            WHEN p.currency = 'usd' THEN p.amount * 80 -- Convert USD to INR
            WHEN p.currency = 'inr' THEN p.amount
            ELSE 0
        END
    ), 2) AS total_raised_in_inr
FROM 
    campaigns c
JOIN 
    payments p ON c.id = p.campaign_id AND p.status = 'success'
WHERE 
    EXTRACT(MONTH FROM c.submitted_on) = 1 -- January
    AND EXTRACT(YEAR FROM c.submitted_on) = 2024 -- Year 2024
GROUP BY 
    c.channel
ORDER BY 
    total_raised_in_inr DESC;
----------------------------------------------------------------------------------------
--8.Month wise payment success rate.
SELECT 
    EXTRACT(YEAR FROM c.submitted_on) AS year,
    EXTRACT(MONTH FROM c.submitted_on) AS month,
    COUNT(CASE WHEN p.status = 'success' THEN 1 END) * 100.0 / COUNT(*) AS success_rate
FROM 
    payments p
JOIN 
    campaigns c ON p.campaign_id = c.id
GROUP BY 
    year, month
ORDER BY 
    year, month;



























