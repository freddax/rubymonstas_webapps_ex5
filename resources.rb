#Webapps exercise 5.4

require "sinatra"

class Member
  attr_accessor :name #attribute accessors are methods!

  def initialize(name = nil) #default avoids error raised when nothing is entered
    #name comes from Member.new(name)
    @name = name.to_s #.to_s not strictly necessary, makes code more flexible for entries
  end

  def id
    #database feel
    name
  end
end

class MemberValidator
  attr_reader :member, :members, :messages

  def initialize(member, members)
    @member = member
    @members = members
    @messages = []
  end

  def valid?
    #calling method validate
    validate
    #checks if @messages returned by method validate are empty or not
    #if empty, method returns true
    @messages.empty?
  end

  def message
    #this makes the messages appear as string, not as array
    #but why first? there is only one message?
    #@messages.join(',') - would be better according to Joe
    @messages.first
  end



  private #why private?

    def names
      members.map { |member| member.name }
    end

    def validate
      if member.name.empty?
        @messages << "Please enter a name!"
      elsif names.include?(member.name)
        @messages << "#{member.name} is already included in our list."
      end
    end
end



#filename into variable
FILENAME = "members.txt"

  def read_names
    #return empty array if file does not exist
    return [] unless File.exist?("members.txt")
    #read file -> string, split turns it into array
    File.read(FILENAME).split("\n")
  end

  def members
    #for each item in the file create new Member class instance
    #with item as the name of the member
    read_names.map { |name| Member.new(name) }
  end

  def find_member(id)
    #find the member for which the member name matches the id argument
    members.detect { |member| member.id == id }
  end

  def add_member(name)
    #file (stored in variable above) is opened in append mode
    #name argument is appended
    File.open(FILENAME, "a+") do |file|
      file.puts(name)
    end
  end

  def update_member(id, name)
    lines = read_names.dup
    lines[lines.index(id)] = name
    store(lines)
  end

  def store(lines)
    File.open(FILENAME, "w+") do |file|
      file.puts(lines.join("\n"))
    end
  end

  def delete_member(name)
    lines = read_names.reject { |other| name == other }
    store(lines)
  end

enable :sessions

get "/members" do
  #instance variable = return of method "members"
  @members = members
  @member = find_member(params[:id])
  @message = session.delete(:message)
  erb :index
end

get "/members/new" do
  #@member = Member.new is not necessary if also taken out from new.erb

  # we delete the key :message from our session (which is something very
  #similar to a Ruby hash). Deleting it will return the value that was
  #stored on this key, and we assign it to the instance variable @message,
  #which makes it available to our template
  @message = session.delete(:message)
  erb :new
end

get "/members/:id" do
  #instance variable = return of method find_member with params as argument

  #params[:id]: params is a hash that Sinatra makes available for you in your
  #route blocks, and it will automatically include relevant data from the request.
  #In our case our route specifies a path that is a pattern:
  #the last part of the path starts with a colon :. This tells Sinatra that
  #we’d like to accept any string here, and that we’d like to call this string "id"

  #in this case the id string comes from URL that is created by link in index.erb member.id
  @member = find_member(params[:id])

  @message = session.delete(:message) #see explanation at get "/members/new"
  erb :show
end

post "/members" do
  #the params hash is stored in variable "name"
  @name = params[:name]
  #a new member instance with name is initialized and stored in instance variable @member
  @member = Member.new(params[:name])
  #a new instance of MemberValidator is initialized and stored in variable "validator"
  #@member is instance variable right above
  #members is return of method members (line 64)
  validator = MemberValidator.new(@member, members)

  if validator.valid?
    #method add_member is called to add member to file
    #why different from method before (used to be just "name")?
    add_member(@member.name)
    session[:message] = "Successfully added new member: #{@name}."
    redirect "/members/#{@member.id}"
  else
    #where does this come from and where does it go to?
    @message = validator.message
    erb :new
  end
end

get "/members/:id/edit" do
  @member = find_member(params[:id])
  erb :edit
end

put "/members/:id" do
  @member = find_member(params[:id])
  @member.name = params[:name] #would also work with name

  @message = session.delete(:message)

  validator = MemberValidator.new(@member, members)

  if validator.valid?
    #method add_member is called to add member to file
    #why different from method before (used to be just "name")?
    update_member(params[:id], @member.name)
    session[:message] = "Successfully edited member: #{@member.name}."
    redirect "/members/#{@member.id}"
  else
    #where does this come from and where does it go to?
    @message = validator.message #method
    erb :edit
  end
end

get "/members/:id/delete" do
  @member = find_member(params[:id])
  erb :delete
end

delete "/members/:id" do
  @member = find_member(params[:id])
  @member.name = params[:id]
  @message = session.delete(:message)

  delete_member(@member.name)

  session[:message] = "Successfully deleted member: #{@member.name}."
  redirect "/members"
end
