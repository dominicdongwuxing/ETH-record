-- TABLE Completed contains all completed courses 
CREATE TABLE Completed ( 
    course_id VARCHAR(20) PRIMARY KEY, 
    course_name VARCHAR(50), 
    course_category VARCHAR(50), 
    credit INT, 
    grade DECIMAL(3,2), 
    completion_semester VARCHAR(3));

-- TABLE Interested contains all courses I'm planning to take
CREATE TABLE Interested ( 
    course_id VARCHAR(20) PRIMARY KEY, 
    course_name VARCHAR(50), 
    course_category VARCHAR(50), 
    credit INT, 
    grade DECIMAL(3,2), 
    completion_semester VARCHAR(3));

-- TABLE Credit_status contains how I am finishing in course categories of the program 
CREATE TABLE Credit_status (
    course_category VARCHAR(50),
    requirement INT DEFAULT 0,
    completed INT DEFAULT 0,
    PRIMARY KEY (course_category));

-- FOREIGN KEY Completed.course_category is PRIMARAY KEY Credit_status.course_category
ALTER TABLE Completed 
ADD FOREIGN KEY (course_category) 
REFERENCES Credit_status (course_category);

-- same with Interested
ALTER TABLE Interested
ADD FOREIGN KEY (course_category) 
REFERENCES Credit_status (course_category);

-- initiate Credit_status data according to CBB study plan, program regulation 2017
INSERT INTO Credit_status (course_category, requirement) VALUES ('additional_requirements',0);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_overall',40);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_bioinformatics',1);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_biophysics',1);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_biosystems',1);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_big_data',1);
INSERT INTO Credit_status (course_category, requirement) VALUES ('core_courses_seminar',2);
INSERT INTO Credit_status (course_category, requirement) VALUES ('advanced_courses_overall',32);
INSERT INTO Credit_status (course_category, requirement) VALUES ('advanced_courses_theory',18);
INSERT INTO Credit_status (course_category, requirement) VALUES ('advanced_courses_biology',12);
INSERT INTO Credit_status (course_category, requirement) VALUES ('advanced_courses_science_in_perspective',2); 
INSERT INTO Credit_status (course_category, requirement) VALUES ('lab_rotations',18); 
INSERT INTO Credit_status (course_category, requirement) VALUES ('master_thesis',30); 

-- I decided to add a column called city in Completed and Interested
ALTER TABLE Completed
ADD city VARCHAR(10);
ALTER TABLE Interested
ADD city VARCHAR(10);

-- when a course is completed, add the credit into Credit_status.completed
-- however, all four core course categories can be counted as theory, therefore 
-- if the sum of the core course category is already full, and the course is one of the
-- four core course category, then the credit belongs to the theory
DELIMITER $$ 
CREATE 
    TRIGGER add_credit BEFORE INSERT
    ON Completed
    FOR EACH ROW BEGIN 
        UPDATE Credit_status 
        SET completed = completed + NEW.credit
        WHERE NEW.course_category = Credit_status.course_category;
        
        -- if it is a core course, remember to also add it to the overall core course credit
        IF NEW.course_category LIKE 'core_courses_%' THEN 
 
            UPDATE Credit_status 
            SET completed = completed + NEW.credit
            WHERE Credit_status.course_category = 'core_courses_overall';

            -- make the new core course as advanced_courses_theory if even without it core course overall credit is already enough

            SET @core_overall = (
                SELECT Credit_status.completed 
                FROM Credit_status 
                WHERE Credit_status.course_category = 'core_courses_overall');

            IF @core_overall - NEW.credit >= 40 THEN 
                -- remove this course from core course specific category 
                UPDATE Credit_status 
                SET completed = completed - NEW.credit
                WHERE NEW.course_category = Credit_status.course_category;
                
                -- remove this course from core course overall 
                UPDATE Credit_status 
                SET completed = completed - NEW.credit
                WHERE NEW.course_category = 'core_courses_overall';

                -- add this course to advacned overall and then theory
                UPDATE Credit_status 
                SET completed = completed + NEW.credit
                WHERE NEW.course_category = 'advanced_courses_overall';

                UPDATE Credit_status 
                SET completed = completed + NEW.credit
                WHERE NEW.course_category = 'advanced_courses_theory';
            END IF;
        END IF;

        -- if it is an advanced course, remember to also add it to the overall advacned course credit
        IF NEW.course_category LIKE 'advanced_courses_%' THEN 
            UPDATE Credit_status 
            SET completed = completed + NEW.credit
            WHERE Credit_status.course_category = 'advanced_courses_overall';
        END IF;
    END$$
DELIMITER ;

-- 2020-07-21
INSERT INTO Completed VALUES ('636-0017-00 S','Computational Biology','core_courses_bioinformatics',6,5.25,'W20','Zurich');
INSERT INTO Completed VALUES ('262-5100-00 S','Protein Biophysics','core_courses_biophysics',6,4.5,'S19','Zurich');
INSERT INTO Completed VALUES ('636-0007-00 S','Computational Systems Biology','core_courses_biosystems',6,5,'W20','Zurich');
INSERT INTO Completed VALUES ('636-0018-00 S','Data Mining I','core_courses_big_data',6,5.25,'W20','Zurich');
INSERT INTO Completed VALUES ('551-0364-00 S','Functional Genomics','core_courses_big_data',3,5.25,'S19','Zurich');
INSERT INTO Completed VALUES ('636-0704-00 S','Computational Biology and Bioinformatics Seminar','core_courses_seminar',2,5.00,'S19','Zurich');
INSERT INTO Completed VALUES ('636-0101-00 S','Systems Genomics','advanced_courses_theory',4,4.50,'S20','Basel');
INSERT INTO Completed VALUES ('636-0022-00 S','Design of Experiments','advanced_courses_theory',4,5.25,'S20','Basel');
INSERT INTO Completed VALUES ('MOB-001','Programming for Life Sciences Pass/Fail grading','advanced_courses_theory',4,NULL,'W20','Basel');
INSERT INTO Completed VALUES ('636-0110-00 S','	ImmunoEngineering','advanced_courses_biology',4,5.25,'S19','Zurich');
INSERT INTO Completed VALUES ('701-1708-00 S','Infectious Disease Dynamics','advanced_courses_biology',4,5.00,'S19','Zurich');
INSERT INTO Completed VALUES ('636-0105-00 S','Introduction to Biological Computers','advanced_courses_biology',4,5.00,'W20','Zurich');
INSERT INTO Completed VALUES ('851-0732-03 S','Intellectual Property: An Introduction','advanced_courses_science_in_perspective',2,5,'S19','Zurich');
INSERT INTO Completed VALUES ('252-0002-AA S','Data Structures and Algorithms','additional_requirements',7,4,'S19','Zurich');

