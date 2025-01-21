# Validation Testing: "Multiple Zero Consumption"

## Introduction
The system under test collects and validates electricity meter readings. Each reading contains several associated attributes:

| Attribute Name       | Type        | Description                                        |
|----------------------|-------------|----------------------------------------------------|
| Reading Date         | Date        | The date of the reading                          |
| Reading Reason       | Integer     | Code value {01; 02; 03...10}                     |
| Reading Type         | Integer     | Code value {01; 02; 03...10}                     |
| Reading Value        | Integer     | Meter status read during the inspection          |
| Consumption          | Integer     | Current meter status - Previous meter status     |

## Description of Validation: Multiple Zero Consumption
This validation identifies readings with zero consumption that meet the conditions below. Such readings are flagged as **Nevierohodné** by the system. 

**Criteria for Non-Credibility:**
- Zero consumption occurs **`x` times consecutively**, where `x` is a configurable parameter.
- The consecutive readings are spaced at least **`y` days apart**, where `y` is a configurable parameter.
- Readings with a **reason code of 06** are exempt from this validation.
- Specific **reading types** can also be excluded from validation through parameter configuration.

**Initial Production Settings:**
- `x = 2`
- `y = 100`
- Excluded Reading Types: `02`, `03`

The validation can be toggled on or off in the system.

## Testing Resources
As a tester, you have the ability to:
- Configure any combination of validation parameters.
- Upload test readings incrementally or in bulk for specific dates.
- View the system’s automatic validation results, where readings are flagged as "**Vierohodné**" or "**Nevierohodné**."

## Response Requirements
To validate the system:
1. Provide a **commented description** of your testing process.
2. Propose test data that demonstrates your understanding of the task and the validation logic.

## Completed Work
- The task was implemented using **Excel** and **SQL**.
- Test data was generated using **Python** to verify the solution.

### Excel Formula
The following formula was created in Excel to validate the readings:
```excel
=IF(AND(
    Usage=0;
    NOT(OR(DeductionReason=6; DeductionType=2; DeductionType=3));
    IF(ISNUMBER(DeductionDatePrevious); AND(DeductionDateCurrent-DeductionDatePrevious>=Y; COUNTIF(OFFSET(DeductionDateCurrent; -X+1; 0; X; 1); 0)=X); FALSE)
); "Nevierohodný"; "Vierohodný")
```

**Explanation:**
1. **`Usage=0`**: Checks if the consumption is zero.
2. **`NOT(OR(DeductionReason=6; DeductionType=2; DeductionType=3))`**: Ensures that the reading reason is not `06` and the reading type is not `02` or `03`.
3. **`IF(ISNUMBER(DeductionDatePrevious); AND(DeductionDateCurrent-DeductionDatePrevious>=Y; COUNTIF(OFFSET(DeductionDateCurrent; -X+1; 0; X; 1); 0)=X); FALSE)`**:
   - Verifies that the current and previous readings are spaced by at least `Y` days.
   - Checks if there are exactly `X` consecutive zero consumption readings.
4. If all conditions are met, the formula marks the reading as **"Nevierohodný"** (`Nevierohodný`), otherwise as **"Vierohodný"** (`Vierohodný`).

### SQL Implementation
The following SQL code replicates the validation logic:

```sql
-- Adding a new column to store state
ALTER TABLE Deductions ADD COLUMN State VARCHAR(20);

-- Update the State column with correct logic
DO $$
DECLARE
    x INT := 2; -- Number of consecutive zero Usage occurrences
    y INT := 100; -- Minimum number of days between consecutive occurrences
BEGIN
    -- Step 1: Assign row numbers to data for easier referencing
    WITH RECURSIVE DeductionsWithRow AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY DeductionDate) AS row_num,
            DeductionDate,
            Usage,
            DeductionReason,
            DeductionType
        FROM Deductions
    ),
    -- Step 2: Identify sequences of consecutive zero Usage readings
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
    -- Step 3: Mark rows that meet the criteria as Nevierohodný
    MarkedNevierohodný AS (
        SELECT DISTINCT
            row_num
        FROM ConsecutiveZeroUsage
        WHERE zero_count >= x -- Only mark sequences with at least x zeros
          AND NOT (DeductionReason = 6 OR DeductionType IN (2, 3)) -- Exclude exceptions
    )
    -- Step 4: Update the State column based on the identified sequences
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
```

**Explanation in Parts:**
1. **Adding a Column:** Adds a `State` column to store the classification of each reading.
2. **Row Number Assignment:** Creates a row-numbered dataset to facilitate row-wise comparisons.
3. **Identify Zero Consumption Sequences:** Uses a recursive CTE to track sequences of zero `Usage` with conditions:
   - A minimum gap of `y` days between readings.
   - Incrementing a counter for consecutive zero readings.
4. **Mark Nevierohodný Readings:** Flags rows as "Nevierohodný" if:
   - The sequence has at least `x` consecutive zeros.
   - The reading does not have an exempt `DeductionReason` or `DeductionType`.
5. **Update State Column:** Updates the `State` column based on whether the row is flagged as "Nevierohodný" or remains "Vierohodný."

## Conclusion
Both the Excel formula and the SQL query solve the problem well, but the SQL solution is better for handling large datasets because of its scalability and flexibility. However, the SQL implementation required more time to develop due to its complexity. 

The task lacked some details, such as whether all readings in a sequence or only the last one should be marked as "Nevierohodný." Providing clearer requirements would make the implementation more accurate. Additionally, visualizing the flagged sequences or providing detailed logs could help improve usability and verification of results.

## Results Screenshots
![image](https://github.com/user-attachments/assets/8716d00a-c7bf-4bb3-a81e-a8adf69c7cd6)

![image](https://github.com/user-attachments/assets/cea1bf1b-b92b-4850-8110-ba18010cce3e)

![image](https://github.com/user-attachments/assets/0085999c-0446-400f-a45d-31106a98ae41)

![image](https://github.com/user-attachments/assets/d224a77d-d9a0-4d81-baaa-2171b5b7a149)





