PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);
CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  associated_author_id INTEGER NOT NULL,
  FOREIGN KEY (associated_author_id) REFERENCES users(id)
);
CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (users_id) REFERENCES users(id)
);
CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  author_id INTEGER NOT NULL,
  reply_body TEXT NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (author_id) REFERENCES users(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);
CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (questions_id) REFERENCES questions(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);
INSERT INTO users(fname, lname)
VALUES
  ('Sara', 'Sampson'),
  ('Chris', 'Thompson');
INSERT INTO questions(title, body, associated_author_id)
VALUES
  ('Q1', 'Does this work?', 1),
  ('Q2', 'Can you do this twice?', 2);
INSERT INTO question_follows(questions_id, users_id)
SELECT
  id,
  associated_author_id
FROM questions;
INSERT INTO replies(
    questions_id,
    parent_reply_id,
    author_id,
    reply_body
  )
VALUES
  (1, NULL, 2, "I hope so.");
INSERT INTO question_likes(questions_id, author_id)
VALUES
  (1, 2);