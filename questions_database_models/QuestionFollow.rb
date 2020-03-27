require 'sqlite3'
require 'singleton'
require_relative './QuestionsDatabase.rb'
require_relative './Question.rb'
require_relative './Reply.rb'
require_relative './User.rb'
require_relative './QuestionLike.rb'

class QuestionFollow
  attr_accessor :users_id, :questions_id

  def initialize(options)
    @users_id = options["users_id"]
    @questions_id = options["questions_id"]
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_follows
            WHERE
                id = ?
        SQL
    QuestionFollow.new(user_data.first)
  end

  def self.followers_for_question_id(question_id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                users.id, users.fname, users.lname
            FROM
                question_follows
            JOIN
                users
                ON question_follows.users_id = users.id
            WHERE
                questions_id = ?
        SQL
    user_data.map { |user| User.new(user) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                questions.id, questions.title, questions.body, questions.associated_author_id
            FROM
                question_follows
            JOIN
                questions
                ON question_follows.users_id = questions.associated_author_id
            WHERE
                users_id = ?
        SQL
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                questions.id, questions.title, questions.body, questions.associated_author_id
            FROM
                question_follows
            JOIN
                questions
                ON question_follows.questions_id = questions.id
            GROUP BY
                question_follows.questions_id
            ORDER BY
                COUNT(*)
            LIMIT ?
        SQL
    questions.map { |question| Question.new(question) }
  end
end