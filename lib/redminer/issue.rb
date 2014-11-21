module Redminer
  class Issue < Redminer::Base
    attr_reader :id
    attr_accessor :author, :project,
                  :tracker, :status, :priority, :category,
                  :subject, :description,
                  :start_date, :due_date,
                  :created_on, :updated_on

    def initialize(server, id = nil)
      @server = server
      unless id.nil?
        @id = id
        self.retrieve
      end
    end

    def retrieve
      response = server.get("/issues/#{id}.json")
      raise "#{id} issue does not exists" if response.nil?
      origin = response["issue"]
      self.all = origin
      self
    end

    def sync
      (@id.nil? ? create : update)
    end

    def craete
      server.post("/issues.json", to_hash)
    end

    def update(note = nil)
      server.put("/issues/#{id}.json", to_hash(note))
    end

    private
      def to_hash(note = nil)

        params = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
        params[:issue][:subject] = @subject
        params[:issue][:description] = @description
        params[:issue][:project] = @project
        params[:issue][:notes] = note unless note.nil?

        params
      end
  end
end
