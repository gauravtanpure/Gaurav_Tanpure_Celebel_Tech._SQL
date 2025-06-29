CREATE TABLE StudentDetails (
    StudentId NUMBER PRIMARY KEY,
    StudentName VARCHAR2(100),
    GPA NUMBER(3,1),
    Branch VARCHAR2(10),
    Section VARCHAR2(5)
);

CREATE TABLE SubjectDetails (
    SubjectId VARCHAR2(10) PRIMARY KEY,
    SubjectName VARCHAR2(100),
    MaxSeats NUMBER,
    RemainingSeats NUMBER
);

CREATE TABLE StudentPreference (
    StudentId NUMBER,
    SubjectId VARCHAR2(10),
    Preference NUMBER,
    PRIMARY KEY (StudentId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

CREATE TABLE Allotments (
    SubjectId VARCHAR2(10),
    StudentId NUMBER,
    PRIMARY KEY (SubjectId, StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

CREATE TABLE UnallotedStudents (
    StudentId NUMBER PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);


-- Insert student details
INSERT INTO StudentDetails VALUES (159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A');


-- Insert subject details
INSERT INTO SubjectDetails VALUES ('PO1491', 'Basics of Political Science', 60, 2);


-- Insert preferences for Mohit
INSERT INTO StudentPreference VALUES (159103036, 'PO1491', 1);
INSERT INTO StudentPreference VALUES (159103036, 'PO1492', 2);
INSERT INTO StudentPreference VALUES (159103036, 'PO1493', 3);
INSERT INTO StudentPreference VALUES (159103036, 'PO1494', 4);
INSERT INTO StudentPreference VALUES (159103036, 'PO1495', 5);


CREATE OR REPLACE PROCEDURE AllocateSubjects IS
    CURSOR student_cur IS
        SELECT StudentId FROM StudentDetails ORDER BY GPA DESC;

    CURSOR pref_cur(sid NUMBER) IS
        SELECT Preference, SubjectId FROM StudentPreference
        WHERE StudentId = sid ORDER BY Preference;

    v_sid StudentDetails.StudentId%TYPE;
    v_pref StudentPreference.Preference%TYPE;
    v_subid StudentPreference.SubjectId%TYPE;
    v_remaining SubjectDetails.RemainingSeats%TYPE;
    v_allotted BOOLEAN := FALSE;
BEGIN
    FOR student IN student_cur LOOP
        v_allotted := FALSE;

        FOR pref IN pref_cur(student.StudentId) LOOP
            SELECT RemainingSeats INTO v_remaining
            FROM SubjectDetails
            WHERE SubjectId = pref.SubjectId
            FOR UPDATE;

            IF v_remaining > 0 THEN
                INSERT INTO Allotments VALUES (pref.SubjectId, student.StudentId);

                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = pref.SubjectId;

                v_allotted := TRUE;
                EXIT;
            END IF;
        END LOOP;

        IF NOT v_allotted THEN
            INSERT INTO UnallotedStudents VALUES (student.StudentId);
        END IF;
    END LOOP;
END;
/


BEGIN
    AllocateSubjects;
END;
/
