require 'sqlite3'
require 'singleton'
require_relative './QuestionsDatabase.rb'
require_relative './Reply.rb'
require_relative './User.rb'
require_relative './QuestionLike.rb'
require_relative './QuestionFollow.rb'

class QuestionLike
  attr_accessor :author_id, :questions_id

  def initialize(options)
    @author_id = options["author_id"]
    @question_id = options["questions_id"]
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_likes
            WHERE
                id = ?
        SQL
    QuestionLike.new(user_data.first)
  end

  def self.likers_for_question_id(question_id)
    search_result = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                users.id, users.fname, users.lname
            FROM
                question_likes
            JOIN
                users
                ON users.id = question_likes.author_id
            WHERE
                questions_id = ?
        SQL
    search_result.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    search_result = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                COUNT(*)
            FROM
                question_likes
            JOIN
                questions
                ON questions.id = question_likes.author_id
            WHERE
                questions_id = ?
        SQL
    search_result.first["COUNT(*)"]
  end

  def self.liked_questions_for_user_id(user_id)
    search_result = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                questions.id, questions.title, questions.body, questions.associated_author_id
            FROM
                question_likes
            JOIN
                questions
                ON questions.associated_author_id = question_likes.author_id
            WHERE
                questions.associated_author_id = ?
        SQL
    search_result.map { |q| Question.new(q) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                questions.id, questions.title, questions.body, questions.associated_author_id
            FROM
                question_likes
            JOIN
                questions
                ON question_likes.questions_id = questions.id
            GROUP BY
                question_likes.questions_id
            ORDER BY
                COUNT(*)
            LIMIT ?
        SQL
    questions.map { |question| Question.new(question) }
  end
end