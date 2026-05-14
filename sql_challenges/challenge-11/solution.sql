-- Exercise 1

CREATE TABLE comments (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id    NUMBER        NOT NULL,
    user_id    NUMBER        NOT NULL,
    content    VARCHAR2(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_task
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Questions
-- 1. Comment should have belongs_to Task and belongs_to user
-- 2. Yes, task should have comments = relationship("Comment", back_populates="task")
-- 3. Comments should be cascade deleted when a task is deleted

-- Exercise 2
CREATE TABLE comments (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id    NUMBER         NOT NULL,
    user_id    NUMBER         NOT NULL,
    content    VARCHAR2(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT ck_comment_content_not_empty CHECK (content != '')
);

DROP TABLE comments;

-- Questions 
-- 1. Upgrade creates the comments table, adds to the db
-- 2. Reverses the migration
-- 3. The comments table gets dropped and all comment data is lost

-- Exercise 3
INSERT INTO teams (name, description) VALUES ('DevOps', 'Infrastructure and deployment team');

-- 2. Create diana_ops user
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('diana_ops', 'diana@example.com', 'Diana Ops',
            (SELECT id FROM teams WHERE name = 'DevOps'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Setup CI/CD pipeline', 'Configure GitHub Actions', 'open',
            (SELECT id FROM users WHERE username = 'diana_ops'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Monitor prod servers', 'Set up Grafana dashboards', 'in_progress',
            (SELECT id FROM users WHERE username = 'diana_ops'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Cleanup old Docker images', 'Low priority maintenance', 'open',
            (SELECT id FROM users WHERE username = 'diana_ops'));

SELECT COUNT(*) AS task_count FROM tasks
WHERE assigned_to = (SELECT id FROM users WHERE username = 'diana_ops');

UPDATE tasks SET status = 'closed', updated_at = CURRENT_TIMESTAMP
WHERE title = 'Setup CI/CD pipeline';
DELETE FROM tasks WHERE title = 'Cleanup old Docker images';
COMMIT;

-- Exercise 4
ALTER TABLE tasks ADD estimated_hours NUMBER;
ALTER TABLE tasks DROP COLUMN estimated_hours;

COMMIT;

-- 1. The estimated_hours column is dropped from the tasks table
-- 2. All data stored in that column is permanently lost

--Exercise 5
-- 1. ORM lets you work with Python objects instead of writing raw SQL more readable, less error prone, and DB agnostic
-- 2. Migrations version control schema changes so the DB evolves with the code without manual ALTER TABLE scripts
-- 3. Rollback when a migration introduced a bug or broke something in production
-- 4. Add stages the object in memory commit() persists it to the DB
-- 5. Relationships let you navigate between objects directly without writing JOINs
