-- 1. Drop old tables if they exist (optional)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE SubjectAllotments';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE SubjectRequest';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- 2. Create SubjectAllotments table
CREATE TABLE SubjectAllotments (
  StudentId VARCHAR2(20),
  SubjectId VARCHAR2(20),
  Is_valid NUMBER(1) -- 1 for valid, 0 for invalid
);

-- 3. Create SubjectRequest table
CREATE TABLE SubjectRequest (
  StudentId VARCHAR2(20),
  SubjectId VARCHAR2(20)
);

-- 4. Insert sample data into SubjectAllotments
INSERT INTO SubjectAllotments VALUES ('159103036', 'PO1491', 1);
INSERT INTO SubjectAllotments VALUES ('159103036', 'PO1492', 0);
INSERT INTO SubjectAllotments VALUES ('159103036', 'PO1493', 0);
INSERT INTO SubjectAllotments VALUES ('159103036', 'PO1494', 0);
INSERT INTO SubjectAllotments VALUES ('159103036', 'PO1495', 0);

-- 5. Insert sample request into SubjectRequest
INSERT INTO SubjectRequest VALUES ('159103036', 'PO1496');

-- 6. Create Stored Procedure
CREATE OR REPLACE PROCEDURE ProcessSubjectRequests IS
BEGIN
  FOR req IN (SELECT StudentId, SubjectId FROM SubjectRequest) LOOP
    DECLARE
      v_count NUMBER;
      v_current_subject VARCHAR2(50);
    BEGIN
      SELECT COUNT(*) INTO v_count
      FROM SubjectAllotments
      WHERE StudentId = req.StudentId;

      IF v_count = 0 THEN
        -- No entry yet: insert new record as valid
        INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
        VALUES (req.StudentId, req.SubjectId, 1);
      ELSE
        BEGIN
          SELECT SubjectId INTO v_current_subject
          FROM SubjectAllotments
          WHERE StudentId = req.StudentId AND Is_valid = 1;

          IF v_current_subject != req.SubjectId THEN
            -- Invalidate old subject
            UPDATE SubjectAllotments
            SET Is_valid = 0
            WHERE StudentId = req.StudentId AND Is_valid = 1;

            -- Insert new subject as valid
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
            VALUES (req.StudentId, req.SubjectId, 1);
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- No valid subject found, just insert new one
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
            VALUES (req.StudentId, req.SubjectId, 1);
        END;
      END IF;
    END;
  END LOOP;

  -- Optional: clear processed requests
  DELETE FROM SubjectRequest;
END;
/

-- 7. Run the procedure
EXEC ProcessSubjectRequests;

-- 8. View updated data
SELECT * FROM SubjectAllotments;
