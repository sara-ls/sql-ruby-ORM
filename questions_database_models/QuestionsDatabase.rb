require "sqlite3"
require "singleton"

# SQLite3::Database.new( "questions.db" ) do |db|
#   db.execute( "select * from table" ) do |row|
#     p row
#   end
# end

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")
    self.type_translation = true
    self.results_as_hash = true
  end
end
