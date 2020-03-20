require 'sqlite3'
require 'singleton'
# SQLite3::Database.new( "questions.db" ) do |db|
#   db.execute( "select * from table" ) do |row|
#     p row
#   end
# end

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class User
    attr_accessor :id, :fname, :lname

    def initialize(options)
        @id = options['id'] # {id => 1, fname => Sara, lname => Sampson}
        @fname = options['fname']
        @lname = options['lname']
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
        Reply.find_by_question_id(self.id)
    end

    def followers
        QuestionFollow.followers_for_question_id(self.id)
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def likers 
        QuestionLike.likers_for_question_id(self.id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(self.id)
    end

    def self.most_liked(n)
        QuestionLike.most_followed_questions(n) 
    end

end

class QuestionFollow
    attr_accessor :users_id, :questions_id

    def initialize(options)
        @users_id = options['users_id']
        @questions_id = options['questions_id']
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
        questions.map {|question| Question.new(question) }
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
        questions.map {|question| Question.new(question) }
    end
end

class Reply
    attr_accessor :id, :parent_reply_id, :author_id, :reply_body, :questions_id

    def initialize(options)
        @id = options['id']
        @parent_reply_id = options['parent_reply_id']
        @author_id = options['author_id']
        @reply_body = options['reply_body']
        @question_id = options['questions_id']
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

class QuestionLike
    attr_accessor :author_id, :questions_id

    def initialize(options)
        @author_id = options['author_id']
        @question_id = options['questions_id']
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
        questions.map {|question| Question.new(question) }
    end
end

