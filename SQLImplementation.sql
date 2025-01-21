-- Create table
CREATE TABLE Deductions (
    DeductionDate DATE NOT NULL,
    DeductionReason INT NOT NULL,
    DeductionType INT NOT NULL,
    Deduction BIGINT NOT NULL,
    Usage INT NOT NULL
);

-- Insert data
INSERT INTO Deductions (DeductionDate, DeductionReason, DeductionType, Deduction, Usage) VALUES
('2023-06-24', 7, 9, 4999279, 5570),
('2023-08-05', 10, 8, 4730562, 9282),
('2023-09-01', 5, 4, 1725334, 9372),
('2023-09-18', 8, 3, 1973746, 733),
('2023-10-05', 4, 5, 5863368, 7053),
('2023-11-15', 3, 5, 2285679, 3566),
('2023-12-20', 7, 1, 2443743, 5871),
('2023-12-24', 1, 2, 2789953, 1962),
('2023-12-29', 10, 4, 1351751, 629),
('2024-05-31', 6, 9, 2044439, 4627),
('2024-06-14', 6, 4, 3050237, 3661),
('2024-06-17', 2, 2, 7896976, 0),
('2024-07-17', 5, 8, 7058049, 7255),
('2024-07-29', 4, 10, 7506695, 0),
('2024-12-02', 7, 4, 1339593, 0),
('2025-04-06', 10, 8, 9667638, 3675),
('2025-05-04', 7, 5, 8576962, 9254),
('2025-05-31', 6, 9, 2044439, 4627),
('2025-06-14', 6, 4, 3050237, 3661),
('2025-06-17', 2, 2, 7896976, 0),
('2025-07-07', 10, 5, 8316713, 5338),
('2025-07-17', 5, 8, 7058049, 7255),
('2025-07-29', 4, 10, 7506695, 0),
('2025-12-02', 7, 4, 1339593, 0),
('2026-03-15', 5, 9, 1671271, 0),
('2026-03-20', 10, 8, 4774563, 4673),
('2026-04-10', 1, 9, 4327487, 0),
('2026-08-08', 7, 1, 2748834, 0),
('2026-08-25', 3, 9, 3611168, 0),
('2026-09-16', 2, 2, 6152097, 3445),
('2026-12-21', 4, 3, 7452240, 9214),
('2027-01-20', 9, 9, 1406148, 0),
('2027-05-14', 5, 10, 1144280, 0),
('2027-06-24', 3, 10, 9971814, 6923),
('2027-11-04', 4, 6, 9423300, 2287),
('2028-01-22', 6, 4, 8849266, 0),
('2028-03-24', 5, 3, 6383681, 3488),
('2028-06-01', 5, 6, 2013592, 0),
('2028-10-02', 9, 6, 9376683, 2318),
('2028-12-08', 4, 10, 6742404, 2386);

-- Add new column State
ALTER TABLE Deductions ADD COLUMN State VARCHAR(20);

-- Update the State column with correct logic
DO $$
DECLARE
    x INT := 2; -- Number of consecutive zero Usage occurrences
    y INT := 100; -- Minimum number of days between consecutive occurrences
BEGIN
    WITH RECURSIVE DeductionsWithRow AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY DeductionDate) AS row_num,
            DeductionDate,
            Usage,
            DeductionReason,
            DeductionType
        FROM Deductions
    ),
    ConsecutiveZeroUsage AS (
        -- Base case: Include rows where Usage = 0
        SELECT 
            row_num,
            DeductionDate,
            Usage,
            DeductionReason,
            DeductionType,
            DeductionDate AS first_zero_date,
            1 AS zero_count -- Start with 1 zero
        FROM DeductionsWithRow
        WHERE Usage = 0

        UNION ALL

        -- Recursive case: Find the next consecutive zero Usage row
        SELECT 
            d.row_num,
            d.DeductionDate,
            d.Usage,
            d.DeductionReason,
            d.DeductionType,
            c.first_zero_date, -- Keep the first zero date in the sequence
            c.zero_count + 1 -- Increment the zero count
        FROM DeductionsWithRow d
        JOIN ConsecutiveZeroUsage c
          ON d.row_num = c.row_num + 1 -- Ensure consecutive rows
         AND d.Usage = 0 -- Only consider rows with zero Usage
         AND d.DeductionDate - c.DeductionDate >= y -- Ensure the date difference is at least y
    ),
    MarkedNevierohodný AS (
        SELECT DISTINCT
            row_num
        FROM ConsecutiveZeroUsage
        WHERE zero_count >= x -- Only mark sequences with at least x zeros
          AND NOT (DeductionReason = 6 OR DeductionType IN (2, 3)) -- Exclude exceptions
    )
    UPDATE Deductions
    SET State = CASE
        WHEN EXISTS (
            SELECT 1 
            FROM MarkedNevierohodný m
            WHERE m.row_num = (
                SELECT row_num 
                FROM DeductionsWithRow dw 
                WHERE dw.DeductionDate = Deductions.DeductionDate
            )
        ) THEN 'Nevierohodný'
        ELSE 'Vierohodný'
    END;
END $$;

-- Check result
SELECT * FROM Deductions;







