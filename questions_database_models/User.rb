require 'sqlite3'
require 'singleton'
require_relative './QuestionsDatabase.rb'
require_relative './Reply.rb'
require_relative './Question.rb'
require_relative './QuestionLike.rb'
require_relative './QuestionFollow.rb'

class User
  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id = options["id"] # {id => 1, fname => Sara, lname => Sampson}
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def self.find_by_name(fname, lname)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ?
                AND
                lname = ?
        SQL
    User.new(user_data.first)
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    User.new(user_data.first)
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    questions = QuestionsDatabase.instance.execute(<<-SQL, self.id)
            SELECT
                COUNT(question_likes.questions_id) /  CAST(COUNT(DISTINCT question_likes.questions_id) AS FLOAT) 
                AS average
            FROM
                questions
            LEFT OUTER JOIN
                question_likes
                ON question_likes.questions_id = questions.id
            WHERE
                questions.associated_author_id = ?
            GROUP BY
                question_likes.questions_id
        SQL
    questions.first["average"]
  end

  def save
    # if id is nil -> save
    raise "#{self} already in database" if self.id
    # QuestionsDatabase.last_insert_row_id
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
            INSERT INTO
                users (fname, lname)
            VALUES
                (?, ?)
            SQL
    self.id = QuestionsDatabase.instance.last_insert_row_id
  end
end