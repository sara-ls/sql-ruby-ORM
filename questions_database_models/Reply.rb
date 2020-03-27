require 'sqlite3'
require 'singleton'
require_relative './QuestionsDatabase.rb'
require_relative './Question.rb'
require_relative './QuestionFollow.rb'
require_relative './User.rb'
require_relative './QuestionLike.rb'

class Reply
  attr_accessor :id, :parent_reply_id, :author_id, :reply_body, :questions_id

  def initialize(options)
    @id = options["id"]
    @parent_reply_id = options["parent_reply_id"]
    @author_id = options["author_id"]
    @reply_body = options["reply_body"]
    @question_id = options["questions_id"]
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL
    Reply.new(user_data.first)
  end

  def self.find_by_user_id(user_id)
    user_replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies
            WHERE
                user_id = ?
        SQL
    user_replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    user_replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies
            WHERE
                questions_id = ?
        SQL
    user_replies.map { |reply| Reply.new(reply) }
  end

  def author
    search_result = QuestionsDatabase.instance.execute(<<-SQL, @author_id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL
    User.new(search_result.first)
  end

  def question
    search_result = QuestionsDatabase.instance.execute(<<-SQL, @question_id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL
    Question.new(search_result.first)
  end

  def parent_reply
    search_result = QuestionsDatabase.instance.execute(<<-SQL, @parent_reply_id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL
    Reply.new(search_result.first)
  end

  def child_replies
    search_result = QuestionsDatabase.instance.execute(<<-SQL, @id)
            SELECT
                *
            FROM
                questions
            WHERE
                parent_reply_id = ?
        SQL
    search_result.map { |reply| Reply.new(reply) }
  end
end