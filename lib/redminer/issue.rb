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

    def update(params = nil)
      server.put("/issues/#{id}.json", to_hash(params))
    end

    private
      def to_hash(params = nil)
        params.nil? ? default_params : default_params.deep_merge(params)
      end

      def default_params
        { issue: { subject: @subject, description: @description, project: @project } }
      end
  end
end
