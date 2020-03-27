# frozen_string_literal: true

require 'sqlite3'
require 'singleton'
require_relative './QuestionsDatabase.rb'
require_relative './Reply.rb'
require_relative './User.rb'
require_relative './QuestionLike.rb'
require_relative './QuestionFollow.rb'

class Question
  attr_accessor :id, :title, :body, :associated_author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @associated_author_id = options['associated_author_id']
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
    SQL
    Question.new(user_data.first)
  end

  def self.find_by_author_id(author_id)
    search_result = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                associated_author_id = ?
    SQL
    search_result.map { |question| Question.new(question) }
  end

  def author
    search_result = QuestionsDatabase.instance.execute(<<-SQL, @associated_author_id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
    SQL
    User.new(search_result.first)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def self.most_liked(n)
    QuestionLike.most_followed_questions(n)
  end
end
