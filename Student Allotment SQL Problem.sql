-- celebal intership

CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #TempSubjectSeats (
        SubjectId NVARCHAR(50),
        RemainingSeats INT
    );

    INSERT INTO #TempSubjectSeats (SubjectId, RemainingSeats)
    SELECT SubjectId, RemainingSeats
    FROM SubjectDetails;

    CREATE TABLE #TempStudentPreferences (
        StudentId NVARCHAR(50),
        SubjectId NVARCHAR(50),
        Preference INT,
        GPA FLOAT,
        Processed BIT DEFAULT 0
    );

    INSERT INTO #TempStudentPreferences (StudentId, SubjectId, Preference, GPA)
    SELECT sp.StudentId, sp.SubjectId, sp.Preference, sd.GPA
    FROM StudentPreference sp
    JOIN StudentDetails sd ON sp.StudentId = sd.StudentId;

    CREATE TABLE #Allotments (
        SubjectId NVARCHAR(50),
        StudentId NVARCHAR(50)
    );

    CREATE TABLE #UnallottedStudents (
        StudentId NVARCHAR(50)
    );

    DECLARE @StudentId NVARCHAR(50);
    DECLARE @SubjectId NVARCHAR(50);
    DECLARE @Preference INT;
    DECLARE @RemainingSeats INT;
    DECLARE @GPA FLOAT;

    DECLARE student_cursor CURSOR FOR
    SELECT DISTINCT StudentId, GPA
    FROM #TempStudentPreferences
    ORDER BY GPA DESC;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE preference_cursor CURSOR FOR
        SELECT SubjectId, Preference
        FROM #TempStudentPreferences
        WHERE StudentId = @StudentId AND Processed = 0
        ORDER BY Preference ASC;

        OPEN preference_cursor;
        FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;

        DECLARE @Allotted BIT = 0;

        WHILE @@FETCH_STATUS = 0 AND @Allotted = 0
        BEGIN
            SELECT @RemainingSeats = RemainingSeats
            FROM #TempSubjectSeats
            WHERE SubjectId = @SubjectId;

            IF @RemainingSeats > 0
            BEGIN
                INSERT INTO #Allotments (SubjectId, StudentId)
                VALUES (@SubjectId, @StudentId);

                UPDATE #TempSubjectSeats
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = @SubjectId;

                UPDATE #TempStudentPreferences
                SET Processed = 1
                WHERE StudentId = @StudentId AND SubjectId = @SubjectId;

                SET @Allotted = 1;
            END

            FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;
        END

        IF @Allotted = 0
        BEGIN
            INSERT INTO #UnallottedStudents (StudentId)
            VALUES (@StudentId);
        END

        CLOSE preference_cursor;
        DEALLOCATE preference_cursor;

        FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    INSERT INTO Allotments (SubjectId, StudentId)
    SELECT SubjectId, StudentId
    FROM #Allotments;

    INSERT INTO UnallottedStudents (StudentId)
    SELECT StudentId
    FROM #UnallottedStudents;

    DROP TABLE #TempSubjectSeats;
    DROP TABLE #TempStudentPreferences;
    DROP TABLE #Allotments;
    DROP TABLE #UnallottedStudents;

    SET NOCOUNT OFF;
END;
GO


-- --------------------------------


CREATE TABLE StudentDetails (
    StudentId NVARCHAR(50) PRIMARY KEY,
    StudentName NVARCHAR(100),
    GPA FLOAT,
    Branch NVARCHAR(50),
    Section NVARCHAR(50)
);

INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
('159103036', 'Mohit Agarwal', 8.9, 'CCE', 'A'),
('159103037', 'Rohit Agarwal', 5.2, 'CCE', 'A'),
('159103038', 'Shohit Garg', 7.1, 'CCE', 'B'),
('159103039', 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
('159103040', 'Mehreet Singh', 5.6, 'CCE', 'A'),
('159103041', 'Arjun Tehlan', 9.2, 'CCE', 'B');

CREATE TABLE StudentPreference (
    StudentId NVARCHAR(50),
    SubjectId NVARCHAR(50),
    Preference INT,
    PRIMARY KEY (StudentId, SubjectId, Preference)
);

INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
('159103036', 'PO1491', 1),
('159103036', 'PO1492', 2),
('159103036', 'PO1493', 3),
('159103036', 'PO1494', 4),
('159103036', 'PO1495', 5),
('159103037', 'PO1491', 1),
('159103037', 'PO1492', 2),
('159103037', 'PO1493', 3)

CREATE TABLE SubjectDetails (
    SubjectId NVARCHAR(50) PRIMARY KEY,
    SubjectName NVARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

CREATE TABLE Allotments (
    SubjectId NVARCHAR(50),
    StudentId NVARCHAR(50),
    PRIMARY KEY (SubjectId, StudentId)
);

CREATE TABLE UnallottedStudents (
    StudentId NVARCHAR(50) PRIMARY KEY
);


-- --------------------------------

EXEC AllocateSubjects;

-- --------------------------------

SELECT * FROM Allotments;
SELECT * FROM UnallottedStudents;


